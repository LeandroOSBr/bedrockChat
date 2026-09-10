# 🚀 Automação de Guardrails via Código (DevSecOps para IA com Terraform)

Este diretório contém a infraestrutura como código (**IaC**) completa para provisionamento, gerenciamento e automação de políticas de segurança do **Amazon Bedrock Guardrails**, além de todos os serviços de suporte desenvolvidos ao longo dos laboratórios práticos.

---

## 🏗️ Mapeamento de Arquivos por Laboratório

Cada arquivo `.tf` foi projetado para espelhar e automatizar um laboratório específico da disciplina:

| Laboratório | Arquivo Terraform / Script | Recursos Provisionados / Papel DevSecOps |
| :--- | :--- | :--- |
| **LAB 01** | [`lab01_serverless_chat.tf`](lab01_serverless_chat.tf) | Bucket S3 (Website estático), API Gateway (HTTP API v2 com CORS), Lambda Execution Role e Função AWS Lambda (`bedrockChatFunction.py` compactada automaticamente). |
| **LAB 02** | [`tests/test_lab02_owasp_redteam.py`](tests/test_lab02_owasp_redteam.py) | **Security Testing as Code**: Suíte automatizada de Red Teaming que dispara os 5 ataques do OWASP Top 10 contra a API e gera relatórios de vulnerabilidade/bloqueio. |
| **LAB 03** | [`lab03_bedrock_guardrails.tf`](lab03_bedrock_guardrails.tf) | **Policy as Code**: `aws_bedrock_guardrail` corporativo com Content Filters (Prompt Attack HIGH), Denied Topics, Mascaramento de PII (Cartão, E-mail) e Regex para CPF brasileiro (`Brazilian_CPF`), mais publicação de versão imutável. |
| **LAB 04** | [`lab04_rag_hardening.tf`](lab04_rag_hardening.tf) | Bucket S3 de dados RAG, upload dos datasets (`politica_reembolso_legitima.txt` e `politica_reembolso_envenenada.txt`) e ativação de **Contextual Grounding Policy** no Guardrail. |
| **LAB 05** | [`lab05_observability.tf`](lab05_observability.tf) | Rastreamento ativo (**AWS X-Ray** no Lambda), políticas IAM do **Application Signals**, CloudWatch Log Group `/aws/bedrock/modelinvocations` e **Bedrock Model Invocation Logging**. |
| **LAB 07** | [`finops_cost_estimator.py`](finops_cost_estimator.py) | **Shift-Left FinOps**: Estimador pré-deploy que projeta custos de Tokenomics (Nova vs Llama) e infraestrutura serverless antes de aplicar o Terraform. |
| **LAB 07** | [`finops_actual_tracker.py`](finops_actual_tracker.py) | **Post-Deploy FinOps**: Monitor de gastos reais acumulados que consulta a **AWS Cost Explorer API** e gera relatórios para terminal e CI/CD. |

---

## 📋 Pré-Requisitos

1. **AWS CLI v2** configurada com credenciais com permissões administrativas (`aws configure`).
2. **Terraform CLI** instalado (`>= 1.5.0`).
3. **Python 3.10+** para execução dos scripts de teste.

---

## ⚡ Guia Rápido de Execução

### 1. Inicializar o Terraform
No terminal, entre no diretório `deploy/terraform` e execute:

```powershell
cd deploy/terraform
terraform init
```

### 2. Configurar as Variáveis
Copie o arquivo de exemplo:

```powershell
cp terraform.tfvars.example terraform.tfvars
```

---

## 🎓 Ciclo Didático DevSecOps (Passo a Passo na Aula)

### Passo 1: Subir o Ambiente Baseline Inseguro (LAB 01)
No arquivo `terraform.tfvars`, configure as flags:
```hcl
enable_guardrails           = false
enable_contextual_grounding = false
enable_observability        = false
```
Aplique a infraestrutura:
```powershell
terraform apply -auto-approve
```

### Passo 2: Executar Ataques Automatizados (LAB 02 - Red Teaming)
Execute a suíte de testes de invasão contra a API provisionada:
```powershell
python tests/test_lab02_owasp_redteam.py --no-guardrail
```
> **Resultado:** O script acusará que a aplicação é **VULNERÁVEL** à injeção de prompt, vazamento de PII e extração de segredos do sistema!

### Passo 3: Ativar o Guardrail via Código (LAB 03 - Policy as Code)
Agora, altere no `terraform.tfvars`:
```hcl
enable_guardrails           = true
enable_contextual_grounding = false
enable_observability        = false
```
Aplique a mudança com Terraform:
```powershell
terraform apply -auto-approve
```
Reexecute a suíte de testes:
```powershell
python tests/test_lab02_owasp_redteam.py
```
> **Resultado:** Imediatamente, 100% dos ataques são **BLOQUEADOS** ou **ANONIMIZADOS** pelo Bedrock Guardrail, sem necessidade de tocar no console visual da AWS!

### Passo 4: Ativar Contextual Grounding e Observabilidade Completa (LAB 04 & LAB 05)
No `terraform.tfvars`, ative todas as proteções:
```hcl
enable_guardrails           = true
enable_contextual_grounding = true
enable_observability        = true
```
Aplique:
```powershell
terraform apply -auto-approve
```
Abra a URL do S3 retornada no output `s3_website_url` para testar na interface visual e confira os rastreamentos no console do AWS CloudWatch / X-Ray!

### Passo 5: FinOps para IA Generativa (LAB 07 - Gestão de Custos e Auditoria)

1. **Estimativa Pré-Deploy (Shift-Left FinOps):**
   ```powershell
   python finops_cost_estimator.py
   ```
   Gera estimativas de custos da infraestrutura serverless e Tokenomics (Nova Micro vs Nova Lite vs Llama 3.1 vs Llama 3) para 1k, 10k e 100k requisições/mês.

2. **Monitoramento Pós-Deploy (AWS Cost Explorer):**
   ```powershell
   python finops_actual_tracker.py
   ```
   Consulta a API do Cost Explorer em tempo real para exibir o gasto consolidado do mês vigente.

---

## 🤖 Esteira de DevSecOps com GitHub Actions

O repositório inclui a pipeline automatizada [`.github/workflows/devsecops-ai-pipeline.yml`](../../.github/workflows/devsecops-ai-pipeline.yml) que implementa um **Security Quality Gate** contínuo e governança **FinOps**.

### 🔑 Configuração de Secrets no GitHub
Para habilitar a execução da pipeline:
1. No seu repositório GitHub, acesse **Settings** > **Secrets and variables** > **Actions**.
2. Adicione as seguintes *Repository Secrets*:
   - `AWS_ACCESS_KEY_ID`: ID da chave de acesso do seu usuário IAM.
   - `AWS_SECRET_ACCESS_KEY`: Chave secreta de acesso do IAM.
   - `AWS_REGION`: Região da AWS (ex: `us-east-1`).

### 🔄 Como Funciona o Fluxo com Gate de Aprovação e FinOps (Plan -> Approval -> Apply)
```
[ Pull Request / Commit / Dispatch ]
                 │
                 ▼
┌─────────────────────────────────┐
│ 1. Linting & Validação Estática │  -> `terraform fmt -check`, `terraform validate`, `py_compile`
└────────────────┬────────────────┘
                 ▼
┌─────────────────────────────────┐
│ 2. Terraform Plan + FinOps Est. │  -> Gera o `tfplan` e executa `finops_cost_estimator.py`
└────────────────┬────────────────┘     com projeção de custos anexada ao Step Summary.
                 ▼
     ⏸️ GATE DE APROVAÇÃO MANUAL ⏸️  -> O GitHub pausa o workflow no environment `production`
                 │                      e aguarda o clique em "Review deployments" -> "Approve and deploy".
                 ▼ (Após Aprovação)
┌─────────────────────────────────┐
│ 3. Terraform Apply + FinOps Act.│  -> Aplica o plano e executa `finops_actual_tracker.py`
└────────────────┬────────────────┘     reportando gastos reais consolidados via AWS Cost Explorer.
                 ▼
┌─────────────────────────────────┐
│ 4. Red Team Security Gate       │  -> Dispara os 5 testes OWASP Top 10 (LAB 02) contra a API
└────────────────┬────────────────┘
                 │
                 ├── Se vulnerável (ex: sem Guardrail)? ──> ❌ BUILD FAIL (Bloqueia promoção)
                 └── Se protegido?                      ──> ✅ BUILD PASS (Relatório no Step Summary)
```

### ⚡ Auditoria FinOps sob Demanda (Ação `finops-audit`)
Você pode auditar gastos e estimativas a qualquer momento sem realizar alterações na nuvem:
1. Vá em **Actions** > **DevSecOps GenAI Pipeline**.
2. Clique em **Run workflow** > selecione a ação **`finops-audit`**.
3. O pipeline executará o Job 6 e gerará a auditoria financeira completa no Step Summary.

### 🛡️ Configurando a Aprovação Manual no GitHub:
1. No seu repositório GitHub, acesse **Settings** > **Environments**.
2. Clique no ambiente **`production`** (criado automaticamente pelo workflow, ou crie clicando em *New environment* com o nome `production`).
3. Marque a opção **Required reviewers** e adicione o seu usuário.
4. Pronto! A partir desse momento, o Terraform Plan será executado e o GitHub exibirá um botão amarelo **"Review deployments"** exigindo que você aprove explicitamente antes de disparar o `terraform apply`!
---

## 🧹 Destruição do Ambiente (Clean Up)

Para evitar custos indesejados ao final da aula, destrua todos os recursos criados com um único comando:

```powershell
terraform destroy -auto-approve
```
