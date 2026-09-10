#!/usr/bin/env python3
"""
TechFin Cloud - FinOps Pre-Deploy Cost Estimator (Shift-Left FinOps)
Calcula estimativas de custos de infraestrutura e modelagem de Tokenomics do AWS Bedrock.
Gera relatórios em texto para terminal e Markdown para GitHub Actions Step Summary.
"""

import sys
import json
import argparse

# Suporte universal a UTF-8 no terminal Windows e Linux
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# Tabela oficial de preços AWS Bedrock (por 1.000.000 de tokens / 1M)
BEDROCK_PRICING = {
    "us.amazon.nova-micro-v1:0": {
        "name": "Amazon Nova Micro v1",
        "input_per_1m": 0.035,   # $0.000035 por 1k
        "output_per_1m": 0.140,  # $0.000140 por 1k
        "tier": "Ultra-Low Cost"
    },
    "us.amazon.nova-lite-v1:0": {
        "name": "Amazon Nova Lite v1",
        "input_per_1m": 0.060,   # $0.000060 por 1k
        "output_per_1m": 0.240,  # $0.000240 por 1k
        "tier": "Cost-Optimized"
    },
    "us.meta.llama3-1-8b-instruct-v1:0": {
        "name": "Meta Llama 3.1 8B Instruct",
        "input_per_1m": 0.220,   # $0.000220 por 1k
        "output_per_1m": 0.220,  # $0.000220 por 1k
        "tier": "High Intelligence"
    },
    "meta.llama3-8b-instruct-v1:0": {
        "name": "Meta Llama 3 8B Instruct",
        "input_per_1m": 0.300,   # $0.000300 por 1k
        "output_per_1m": 0.600,  # $0.000600 por 1k
        "tier": "General Purpose"
    }
}

# Custo de avaliação de texto por Guardrail (por 1.000 text units)
GUARDRAIL_COST_PER_1K_UNITS = 0.00075

# Estimativa de infraestrutura base serverless (mensal)
BASE_INFRASTRUCTURE = [
    {"resource": "Amazon S3 (Frontend + RAG)", "metric": "Armazenamento (~15 MB)", "cost_usd": 0.0004, "note": "Primeiros 5GB no Free Tier"},
    {"resource": "Amazon API Gateway (HTTP API)", "metric": "$1.00 / 1.000.000 requests", "cost_usd": 0.0100, "note": "Base para 10k requests"},
    {"resource": "AWS Lambda (256 MB / ~2.5s)", "metric": "Compute Serverless", "cost_usd": 0.0000, "note": "Totalmente coberto pelo Free Tier (1M reqs)"},
    {"resource": "CloudWatch Logs & X-Ray", "metric": "Logs e Rastreamento", "cost_usd": 0.0050, "note": "Primeiros 5GB de logs grátis"},
]

def calculate_inference_cost(model_id, input_tokens, output_tokens, use_guardrail=True):
    model = BEDROCK_PRICING.get(model_id, BEDROCK_PRICING["meta.llama3-8b-instruct-v1:0"])
    input_cost = (input_tokens / 1_000_000.0) * model["input_per_1m"]
    output_cost = (output_tokens / 1_000_000.0) * model["output_per_1m"]
    guardrail_cost = (GUARDRAIL_COST_PER_1K_UNITS if use_guardrail else 0.0)
    total = input_cost + output_cost + guardrail_cost
    return {
        "model_name": model["name"],
        "input_cost": input_cost,
        "output_cost": output_cost,
        "guardrail_cost": guardrail_cost,
        "total_cost": total
    }

def generate_monthly_scenarios(avg_input_tokens=350, avg_output_tokens=150, use_guardrail=True):
    scenarios = [1_000, 10_000, 100_000]
    results = {}

    for model_id, info in BEDROCK_PRICING.items():
        results[model_id] = {
            "name": info["name"],
            "tier": info["tier"],
            "input_rate": info["input_per_1m"],
            "output_rate": info["output_per_1m"],
            "scenarios": {}
        }
        for volume in scenarios:
            cost_per_query = calculate_inference_cost(model_id, avg_input_tokens, avg_output_tokens, use_guardrail)["total_cost"]
            monthly_cost = cost_per_query * volume
            results[model_id]["scenarios"][volume] = monthly_cost

    return results

def format_terminal():
    print("=" * 78)
    print(" 💰 TECHFIN CLOUD - RELATÓRIO DE ESTIMATIVA FINOPS (PRÉ-DEPLOY)")
    print("=" * 78)
    
    print("\n1. Custos Fixos Estimados da Infraestrutura Base:")
    print(f"{'Recurso':<35} {'Métrica':<25} {'Custo Mensal':<15}")
    print("-" * 75)
    base_total = 0.0
    for item in BASE_INFRASTRUCTURE:
        print(f"{item['resource']:<35} {item['metric']:<25} ${item['cost_usd']:.4f} USD ({item['note']})")
        base_total += item["cost_usd"]
    print("-" * 75)
    print(f"Total Base Estimado: ${base_total:.4f} USD/mês\n")

    print("2. Matriz Comparativa de Tokenomics (AWS Bedrock - Custo por Volume Mensal):")
    print("   Premissas: Média de 350 tokens de entrada (Prompt + RAG) e 150 tokens de saída + Guardrail ativo.")
    print("-" * 78)
    print(f"{'Modelo':<30} {'1.000 req/mês':<15} {'10.000 req/mês':<15} {'100.000 req/mês':<15}")
    print("-" * 78)
    
    scenarios = generate_monthly_scenarios()
    for model_id, data in scenarios.items():
        c1k = data["scenarios"][1_000]
        c10k = data["scenarios"][10_000]
        c100k = data["scenarios"][100_000]
        print(f"{data['name']:<30} ${c1k:>6.2f} USD      ${c10k:>7.2f} USD      ${c100k:>8.2f} USD")
    print("=" * 78)

def format_markdown():
    scenarios = generate_monthly_scenarios()
    md = []
    md.append("### 💰 Estimativa de Custos FinOps (Shift-Left Pre-Deploy)")
    md.append("Projeção de custos estimada para a arquitetura serverless e modelos de IA Generativa do AWS Bedrock:")
    md.append("")
    md.append("#### 1. Infraestrutura Serverless Base (Custos Fixos):")
    md.append("| Componente | Métrica Considerada | Estimativa Mensal | Benefício Free Tier |")
    md.append("| :--- | :--- | :---: | :--- |")
    for item in BASE_INFRASTRUCTURE:
        md.append(f"| **{item['resource']}** | {item['metric']} | `${item['cost_usd']:.4f} USD` | {item['note']} |")
    md.append("")
    md.append("#### 2. Matriz de Tokenomics GenAI (Custo Projetado por Modelo):")
    md.append("> **Premissas do Modelo de Consumo:** Média de 350 tokens de entrada (Pergunta + Contexto RAG) e 150 tokens de resposta por requisição, com avaliação do Bedrock Guardrail ativa.")
    md.append("")
    md.append("| Modelo Bedrock | Nível de Otimização | 1.000 Reqs/Mês | 10.000 Reqs/Mês | 100.000 Reqs/Mês | Economia Relativa |")
    md.append("| :--- | :--- | :---: | :---: | :---: | :---: |")

    baseline_100k = scenarios["meta.llama3-8b-instruct-v1:0"]["scenarios"][100_000]
    for model_id, data in scenarios.items():
        c1k = data["scenarios"][1_000]
        c10k = data["scenarios"][10_000]
        c100k = data["scenarios"][100_000]
        savings = ((baseline_100k - c100k) / baseline_100k) * 100.0 if baseline_100k > 0 else 0
        savings_str = f"**-{savings:.0f}%**" if savings > 0 else "Baseline"
        md.append(f"| **{data['name']}** | `{data['tier']}` | `${c1k:.2f} USD` | `${c10k:.2f} USD` | `${c100k:.2f} USD` | {savings_str} |")

    md.append("")
    md.append("> [!TIP]")
    md.append("> **Insight FinOps:** A utilização do **Amazon Nova Micro** ou **Nova Lite** para fluxos corporativos rotineiros proporciona uma **redução de até ~75% nos custos de inferência** com relação ao Llama 3 8B, mantendo a mesma camada de segurança via Bedrock Guardrails.")
    md.append("")
    return "\n".join(md)

def main():
    parser = argparse.ArgumentParser(description="FinOps Pre-Deploy Cost Estimator")
    parser.add_argument("--format", choices=["text", "markdown", "json"], default="text", help="Formato de saída")
    args = parser.parse_args()

    if args.format == "markdown":
        print(format_markdown())
    elif args.format == "json":
        print(json.dumps(generate_monthly_scenarios(), indent=2))
    else:
        format_terminal()

if __name__ == "__main__":
    main()
