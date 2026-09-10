#!/usr/bin/env python3
"""
TechFin Cloud - FinOps Actual Cost Tracker (Post-Deploy Cost Monitoring)
Consulta a AWS Cost Explorer API para recuperar gastos reais acumulados
dos serviços da solução (Bedrock, Lambda, S3, API Gateway e CloudWatch).
Gera relatórios em texto para terminal e Markdown para GitHub Actions Step Summary.
"""

import sys
import json
import argparse
import subprocess
from datetime import datetime, timezone, timedelta

# Suporte universal a UTF-8 no terminal Windows e Linux
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

PROJECT_SERVICES = {
    "Amazon Bedrock": "Modelos LLM e Guardrails",
    "AWS Lambda": "Funções Serverless (Invocação e Duração)",
    "Amazon Simple Storage Service": "Armazenamento S3 (Frontend e RAG)",
    "Amazon API Gateway": "HTTP API Invocations",
    "AmazonCloudWatch": "Métricas, Dashboards e Logs",
    "AWS X-Ray": "Rastreamento Distribuído"
}

def query_cost_explorer(start_date, end_date):
    """Consulta o Cost Explorer via boto3 ou fallback para AWS CLI"""
    # 1. Tentar boto3
    try:
        import boto3
        from botocore.exceptions import ClientError
        ce_client = boto3.client('ce', region_name='us-east-1')
        return ce_client.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
    except ImportError:
        pass
    except Exception as e:
        raise e

    # 2. Fallback para AWS CLI
    time_period_param = f"Start={start_date},End={end_date}"
    cmd = [
        "aws", "ce", "get-cost-and-usage",
        "--time-period", time_period_param,
        "--granularity", "MONTHLY",
        "--metrics", "UnblendedCost",
        "--group-by", "Type=DIMENSION,Key=SERVICE",
        "--region", "us-east-1",
        "--output", "json"
    ]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"Erro AWS CLI CE: {proc.stderr.strip()}")
    return json.loads(proc.stdout)

def get_cost_and_usage():
    try:
        today = datetime.now(timezone.utc)
        start_date = today.replace(day=1).strftime('%Y-%m-%d')
        # EndDate no Cost Explorer deve ser posterior ao StartDate
        end_date = (today + timedelta(days=1)).strftime('%Y-%m-%d')

        response = query_cost_explorer(start_date, end_date)

        results = []
        total_project_cost = 0.0
        total_account_cost = 0.0

        for period in response.get('ResultsByTime', []):
            for group in period.get('Groups', []):
                service_name = group['Keys'][0]
                amount = float(group['Metrics']['UnblendedCost']['Amount'])
                unit = group['Metrics']['UnblendedCost']['Unit']
                total_account_cost += amount

                if service_name in PROJECT_SERVICES or amount > 0.0001:
                    is_project = service_name in PROJECT_SERVICES
                    if is_project:
                        total_project_cost += amount
                    results.append({
                        "service": service_name,
                        "amount": amount,
                        "unit": unit,
                        "is_project": is_project,
                        "description": PROJECT_SERVICES.get(service_name, "Outro serviço AWS")
                    })

        # Ordenar por maior custo primeiro
        results.sort(key=lambda x: x["amount"], reverse=True)

        return {
            "success": True,
            "period": f"{start_date} a {end_date}",
            "project_total": total_project_cost,
            "account_total": total_account_cost,
            "services": results
        }

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'ClientError')
        error_msg = e.response.get('Error', {}).get('Message', str(e))
        return {
            "success": False,
            "error": f"Erro AWS Cost Explorer [{error_code}]: {error_msg}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Falha ao consultar custos: {str(e)}"
        }

def format_terminal(data):
    print("=" * 80)
    print(" 📈 TECHFIN CLOUD - RELATÓRIO DE CUSTOS REAIS ACUMULADOS (AWS COST EXPLORER)")
    print("=" * 80)

    if not data.get("success"):
        print(f"\n❌ {data.get('error')}\n")
        return

    print(f"Período de Apuração: {data['period']} (Mês Vigente)")
    print("-" * 80)
    print(f"{'Serviço AWS':<32} {'Descrição':<32} {'Gasto Real (USD)':<15}")
    print("-" * 80)

    for item in data["services"]:
        if item["is_project"] or item["amount"] > 0.001:
            tag = "★" if item["is_project"] else " "
            print(f"{tag} {item['service']:<30} {item['description']:<32} ${item['amount']:>10.6f} USD")

    print("-" * 80)
    print(f"Total dos Serviços do Projeto:   ${data['project_total']:>10.6f} USD")
    print(f"Total Acumulado na Conta AWS:    ${data['account_total']:>10.6f} USD")
    print("=" * 80)

def format_markdown(data):
    md = []
    md.append("### 📈 Acompanhamento FinOps: Gastos Reais Acumulados (AWS Cost Explorer)")
    
    if not data.get("success"):
        md.append(f"> [!WARNING]\n> {data.get('error')}")
        return "\n".join(md)

    md.append(f"Valores apurados em tempo real na conta AWS para o período de **{data['period']}**:")
    md.append("")
    md.append("| Serviço AWS | Papel na Arquitetura | Gasto Acumulado (USD) | Status FinOps |")
    md.append("| :--- | :--- | :---: | :---: |")

    for item in data["services"]:
        if item["is_project"] or item["amount"] > 0.001:
            status = "🟢 Controlado" if item["amount"] < 1.0 else "🟡 Atenção"
            md.append(f"| **{item['service']}** | {item['description']} | `${item['amount']:.6f} USD` | {status} |")

    md.append("")
    md.append(f"- **Total Serviços da Aplicação (BedrockChat):** `${data['project_total']:.6f} USD`")
    md.append(f"- **Total Consolidado da Conta AWS:** `${data['account_total']:.6f} USD`")
    md.append("")
    md.append("> [!TIP]")
    md.append("> **Governança:** Os custos de AWS Lambda, S3 e CloudWatch encontram-se quase integralmente dentro do *AWS Free Tier*. O maior direcionador de custo (*cost driver*) é a inferência de tokens no Amazon Bedrock.")
    md.append("")
    return "\n".join(md)

def main():
    parser = argparse.ArgumentParser(description="FinOps Actual Cost Tracker")
    parser.add_argument("--format", choices=["text", "markdown", "json"], default="text", help="Formato de saída")
    args = parser.parse_args()

    data = get_cost_and_usage()

    if args.format == "markdown":
        print(format_markdown(data))
    elif args.format == "json":
        print(json.dumps(data, indent=2))
    else:
        format_terminal(data)

if __name__ == "__main__":
    main()
