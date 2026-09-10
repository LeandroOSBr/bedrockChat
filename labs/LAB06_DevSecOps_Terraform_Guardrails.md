# 🛡️ LAB 06: DevSecOps para IA — Automação de Guardrails e Infraestrutura como Código (Terraform)

---

## 🎯 Objetivos de Aprendizagem

Ao final deste laboratório, você será capaz de:
1. Compreender os paradigmas de **Policy-as-Code** e **Security-as-Code** aplicados à segurança de Large Language Models (LLMs).
2. Substituir processos manuais (*click-ops*) no console da AWS por templates idempotentes e declarativos em **Terraform**.
3. Provisionar o ciclo de vida completo de um **AWS Bedrock Guardrail** via código:
   - Filtros de conteúdo e Jailbreak (`PROMPT_ATTACK: HIGH`).
   - Tópicos restritos corporativos (`DENIED_TOPICS`).
   - Anonimização de PII (Cartão, E-mail e Regex customizado para CPF brasileiro).
   - Bloqueio de chaves confidenciais do sistema (*Word Policy*).
   - Ancoragem factual e relevância (*Contextual Grounding* para RAG).
   - Versionamento imutável de Guardrail para ambientes de produção.
4. Implementar e executar testes automatizados de **Red Teaming as Code** baseados no **OWASP Top 10 for LLM** para validação de conformidade em esteiras de CI/CD.
5. Provisionar a camada de **Observabilidade GenAI** (AWS X-Ray, CloudWatch Application Signals e Bedrock Model Invocation Logging) via código.

---

## 🧠 Conceito: DevSecOps para Inteligência Artificial Generativa

Em arquiteturas convencionais de Cloud Computing, o time de DevSecOps declara redes, firewalls (WAF) e regras de IAM via código. 

Na era da **IA Generativa**, o "firewall semântico" da aplicação é o **Guardrail**. Configurar guardrails manualmente pelo console web traz riscos graves para organizações:
* **Falta de rastreabilidade:** Quem alterou a sensibilidade do filtro de jailbreak ou removeu um tópico negado?
* **Drift de configuração:** O ambiente de homologação comporta-se de forma diferente da produção.
* **Impossibilidade de testes contínuos de regressão:** Como garantir que uma atualização de prompt ou modelo não quebrou as regras de compliance corporativo?

```mermaid
flowchart LR
    subgraph Repositorio ["📦 Git Repository"]
        A["main.tf / variables.tf"]
        B["lab03_bedrock_guardrails.tf"]
        C["tests/test_lab02_owasp_redteam.py"]
    end

    subgraph Pipeline ["⚙️ Pipeline CI/CD (DevSecOps)"]
        D["1. Terraform Plan & Validate"]
        E["2. Terraform Apply"]
        F["3. Automated Red Teaming Tests"]
    end

    subgraph AWS_Cloud ["☁️ AWS Environment"]
        G["🛡️ Bedrock Guardrail"]
        H["⚡ AWS Lambda"]
        I["🚪 API Gateway"]
        J["📊 X-Ray & Bedrock Logging"]
    end

    A & B --> D --> E
    E --> G & H & I & J
    C --> F
    F -->|Injeta Ataques OWASP| I
    I --> H
    H --> G
    G -->|Bloqueio / Anonimização| F
```

---

## 📁 Estrutura Modular dos Recursos em `deploy/terraform/`

Para manter alinhamento pedagógico com as fases da disciplina, o código Terraform foi organizado em arquivos modulares correspondentes a cada laboratório:

```text
bedrockChat/
├── deploy/
│   └── terraform/
│       ├── versions.tf                  <- Provedores AWS (>= 5.50), Archive e Random
│       ├── variables.tf                 <- Definição de parâmetros e feature flags didáticas
│       ├── terraform.tfvars.example     <- Modelo de valores customizáveis
│       ├── lab01_serverless_chat.tf     <- S3 website, API Gateway v2, Lambda e IAM
│       ├── lab03_bedrock_guardrails.tf  <- Bedrock Guardrail completo (Jailbreak, PII, Regex CPF, Tópicos)
│       ├── lab04_rag_hardening.tf      <- Bucket S3 de RAG e upload dos documentos de teste
│       ├── lab05_observability.tf       <- AWS X-Ray, Application Signals e Log Group /aws/bedrock/modelinvocations
│       ├── outputs.tf                   <- URLs, Guardrail ID e nomes de recursos gerados
│       ├── tests/
│       │   └── test_lab02_owasp_redteam.py <- Suíte de testes ofensivos OWASP Top 10 (LAB 02 DevSecOps)
│       └── README.md                    <- Guia operacional rápido do Terraform
```

---

## 🔬 Roteiro Prático de Aula: Ciclo DevSecOps Hands-On

### Fase 1: Inicialização do Terraform

1. Abra o terminal (PowerShell no Windows ou Bash no Linux) na raiz do projeto `bedrockChat`.
2. Navegue até o diretório do Terraform e inicialize os provedores:
   ```powershell
   cd deploy/terraform
   terraform init
   ```
3. Crie seu arquivo de configuração local:
   ```powershell
   cp terraform.tfvars.example terraform.tfvars
   ```

---

### Fase 2: Deploy do Baseline Inseguro (LAB 01)

No arquivo `terraform.tfvars`, defina as feature flags para subir apenas a aplicação desprotegida:

```hcl
enable_guardrails           = false
enable_contextual_grounding = false
enable_observability        = false
```

Execute o planejamento e o provisionamento:
```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

Ao término, o Terraform exibirá as URLs geradas:
* `api_chat_endpoint`: URL do backend HTTP API.
* `s3_website_url`: URL do frontend web no S3.

---

### Fase 3: Execução da Suíte de Red Teaming Automatizada (LAB 02)

Agora, valide as vulnerabilidades nativas da aplicação antes da ativação dos Guardrails utilizando o script automatizado:

```powershell
python tests/test_lab02_owasp_redteam.py --no-guardrail
```

**Comportamento Observado no Terminal:**
* ✖ **LLM01 (Prompt Injection):** O modelo aceita a ordem de subversão de persona.
* ✖ **LLM07 (System Prompt Leakage):** Os segredos do sistema (`SEC-PROJECT-PHOENIX-2026` e `TK_INTERNAL_DEV_987654321`) são vazados na íntegra.
* ✖ **LLM06 (Sensitive Information Disclosure):** O CPF (`234.567.890-12`) e o cartão de crédito são refletidos sem máscara.
* ✖ **Denied Topics:** O modelo discute técnicas de ataque cibernético (DDoS).

O script finaliza emitindo o alerta:
> `🚨 RESULTADO: Vulnerabilidades exploradas com sucesso. Habilite o Guardrail no Terraform!`

---

### Fase 4: Policy as Code — Ativando o Bedrock Guardrail (LAB 03)

Edite o arquivo `terraform.tfvars` ativando o Guardrail:

```hcl
enable_guardrails           = true
enable_contextual_grounding = false
enable_observability        = false
```

Aplique a atualização:
```powershell
terraform apply -auto-approve
```

O Terraform executará as seguintes ações:
1. Criará o recurso `aws_bedrock_guardrail.techfin_guardrail` com todas as políticas de segurança.
2. Criará a versão imutável `aws_bedrock_guardrail_version.techfin_guardrail_v1`.
3. Injetará automaticamente o `GUARDRAIL_ID` e a `GUARDRAIL_VERSION` nas variáveis de ambiente da função Lambda.

---

### Fase 5: Teste de Regressão de Segurança (Security Gate)

Reexecute o script de Red Teaming:

```powershell
python tests/test_lab02_owasp_redteam.py
```

**Resultado Obtido:**
* ✔ **LLM01:** Interceptado pelo filtro `PROMPT_ATTACK: HIGH` com mensagem corporativa customizada.
* ✔ **LLM07:** Interceptado pelo Word Policy (`SEC-PROJECT-PHOENIX-2026`).
* ✔ **LLM06:** CPF e Cartão substituídos automaticamente por `[Brazilian_CPF]` e `[CREDIT_DEBIT_CARD_NUMBER]`.
* ✔ **Denied Topics:** Requisição bloqueada pela política `Hacking_and_Exploits`.

> `🎉 RESULTADO: Todas as políticas de segurança foram validadas com sucesso!`

---

### Fase 6: Ativação de RAG Hardening e Observabilidade Total (LAB 04 & LAB 05)

No `terraform.tfvars`, ative o ecossistema completo:

```hcl
enable_guardrails           = true
enable_contextual_grounding = true
enable_observability        = true
```

Aplique a mudança final:
```powershell
terraform apply -auto-approve
```

1. **Contextual Grounding (LAB 04):** Adiciona dinamicamente ao Guardrail as regras de ancoragem factual (`threshold = 0.8`) e relevância (`threshold = 0.7`).
2. **Observabilidade (LAB 05):**
   - Habilita `tracing_config { mode = "Active" }` na Lambda para o **AWS X-Ray**.
   - Cria a role `BedrockModelInvocationLoggingRole` e o Log Group `/aws/bedrock/modelinvocations`.
   - Ativa o **Bedrock Model Invocation Logging** em toda a região `us-east-1`.

---

### Fase 7: Automação Contínua com GitHub Actions (CI/CD Security Gate)

Em vez de executar os comandos apenas localmente, o repositório inclui a pipeline profissional [`.github/workflows/devsecops-ai-pipeline.yml`](../.github/workflows/devsecops-ai-pipeline.yml).

#### 1. Configurar Secrets no GitHub:
No seu repositório GitHub, navegue até **Settings > Secrets and variables > Actions** e cadastre:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (ex: `us-east-1`)

#### 2. Os 3 Estágios da Pipeline:
```
┌───────────────────────────┐      ┌───────────────────────────┐      ┌───────────────────────────┐
│ 1. Lint & Validate        │ ---> │ 2. Terraform Deploy       │ ---> │ 3. Red Team Security Gate │
│ (fmt, validate, py_compile│      │ (S3, Lambda, Guardrail)   │      │ (5 Ataques OWASP Top 10)  │
└───────────────────────────┘      └───────────────────────────┘      └─────────────┬─────────────┘
                                                                                    │
                                               ┌────────────────────────────────────┴────────────────────────────────────┐
                                               ▼                                                                         ▼
                                      [ ✅ 100% Protegido ]                                                    [ ❌ Vulnerabilidade ]
                                      Pipeline Aprovada (PASS)                                                  Pipeline Abortada (FAIL)
```

#### 3. Exercício de Simulação: Forçar a Quebra do Security Gate
1. Vá até a aba **Actions** no GitHub e selecione o workflow **DevSecOps GenAI Pipeline**.
2. Clique em **Run workflow**:
   - Defina `action` como `apply`.
   - **Desmarque** o checkbox `enable_guardrails` (simulando um desenvolvedor tentando subir uma IA sem proteções).
3. **Resultado:** 
   - A etapa 2 provisionará a aplicação insegura.
   - A etapa 3 (Security Gate) executará os ataques do OWASP Top 10 e detectará vazamento de PII e injeção de prompt.
   - A pipeline emitirá **Exit Code 1**, marcando o **Job como FALHO (vermelho)** e impedindo a homologação da release!

---

## 🧹 Limpeza dos Recursos (Clean Up)

Para destruir 100% dos recursos criados e evitar qualquer custo residual:

```powershell
terraform destroy -auto-approve
```

---

## 💬 Questões para Discussão em Aula

1. **Shift-Left em GenAI:** Qual a diferença entre detectar vulnerabilidades de IA em produção versus barrá-las na esteira de CI/CD através de testes automatizados de Red Teaming?
2. **Imutabilidade e Versionamento:** Por que ambientes de produção devem apontar para um `aws_bedrock_guardrail_version` numérico específico ao invés da versão `DRAFT`?
3. **Auditoria e Compliance:** Como o gerenciamento de Guardrails via código simplifica auditorias de conformidade (ex: SOC 2, ISO 27001 e LGPD)?
