# 🛡️ Lab de Segurança em Cloud Computing e Aplicações de IA (AWS Bedrock)

Material didático e laboratórios práticos desenvolvidos para a disciplina **Cloud Computing e Segurança de Aplicações de IA**.

O objetivo deste projeto é guiar os estudantes através de uma jornada completa de segurança em IA Generativa:
1. **Construção de uma Aplicação Serverless** com AWS Lambda, API Gateway, S3 e Bedrock.
2. **Exploração de Vulnerabilidades** com base no **OWASP Top 10 for Large Language Models (LLM)**.
3. **Hardening e Defesa Ativa** utilizando **AWS Bedrock Guardrails** (Filtros de Jailbreak, Anonimização de PII, Tópicos Negados).
4. **Data Poisoning & RAG Hardening** demonstrando **Injeção Indireta de Prompt** em bases de conhecimento e mitigação com **Contextual Grounding**.
5. **FinOps para IA Generativa** com estimativa pré-deploy (*Shift-Left*), governança via **AWS Cost Explorer** e telemetria de consumo em tempo real.

---

## 🏗️ Arquitetura do Sistema

```
[ Usuário / Aluno ] 
        │
        ▼
[ Amazon S3 ] ──(Interface Web chat.html + Telemetria FinOps)
        │
        ▼ (Requisição HTTP / JSON)
[ Amazon API Gateway ] ──(HTTP API + CORS)
        │
        ▼
[ AWS Lambda (bedrockChatFunction.py) ] ──(Bedrock Converse API + Cálculo de Custos)
        │
        ├── 🛡️ AWS Bedrock Guardrails (Input & Output Inspection)
        │
        ▼
[ Amazon Bedrock (Meta Llama 3 / Amazon Nova) ]
```

---

## 📚 Trilha de Laboratórios Práticos

A disciplina é estruturada em 7 laboratórios modulares:

| Laboratório | Arquivo | Descrição |
| :--- | :--- | :--- |
| **LAB 01** | [`labs/LAB01_Setup_and_Insecure_Chat.md`](labs/LAB01_Setup_and_Insecure_Chat.md) | Provisionamento inicial da arquitetura Serverless e deploy do chat base desprotegido. |
| **LAB 02** | [`labs/LAB02_OWASP_Top10_Exploitation.md`](labs/LAB02_OWASP_Top10_Exploitation.md) | Execução de ataques práticos: Prompt Injection, Jailbreaking, Vazamento de PII (LLM06), System Prompt Extraction (LLM07) e XSS (LLM02). |
| **LAB 03** | [`labs/LAB03_Bedrock_Guardrails_Setup.md`](labs/LAB03_Bedrock_Guardrails_Setup.md) | Criação de Guardrails no console AWS, configuração de políticas de conteúdo/Jailbreak/PII e testes comparativos (*Before vs After*). |
| **LAB 04** | [`labs/LAB04_RAG_and_Data_Poisoning.md`](labs/LAB04_RAG_and_Data_Poisoning.md) | Simulação de RAG, envenenamento de documentos (*Indirect Prompt Injection*) e mitigação com **Contextual Grounding**. |
| **LAB 05** | [`labs/LAB05_Observability_XRay_ApplicationSignals.md`](labs/LAB05_Observability_XRay_ApplicationSignals.md) | Observabilidade e monitoramento de GenAI com **AWS X-Ray** e **CloudWatch Application Signals**. |
| **LAB 06** | [`labs/LAB06_DevSecOps_Terraform_Guardrails.md`](labs/LAB06_DevSecOps_Terraform_Guardrails.md) | **DevSecOps para IA**: Automação completa de infraestrutura e Guardrails como código via **Terraform** e testes automatizados de Red Teaming. |
| **LAB 07** | [`labs/LAB07_FinOps_GenAI_Cost_Management.md`](labs/LAB07_FinOps_GenAI_Cost_Management.md) | **FinOps para IA Generativa**: Gestão de custos, Tokenomics (Nova vs Llama), precificação de Guardrails, estimativas pré-deploy e auditoria via AWS Cost Explorer. |

---

## 📁 Estrutura do Repositório

```text
bedrockChat/
├── README.md                                <- Documento principal e visão geral da disciplina
├── bedrockChatFunction.py                   <- Função Lambda backend (Bedrock Converse API + FinOps)
├── chat.html                                <- Frontend web educacional com presets OWASP e telemetria FinOps
├── deploy/
│   └── terraform/                           <- Automação completa de IaC e DevSecOps para IA
│       ├── versions.tf                      <- Provedores AWS, Archive e Random
│       ├── variables.tf / terraform.tfvars  <- Configurações e Feature Flags
│       ├── lab01_serverless_chat.tf         <- S3 web, API GW HTTP, Lambda e IAM
│       ├── lab03_bedrock_guardrails.tf      <- Bedrock Guardrail (Jailbreak, PII, Regex CPF)
│       ├── lab04_rag_hardening.tf          <- Datasets S3 e Contextual Grounding
│       ├── lab05_observability.tf           <- AWS X-Ray e Bedrock Logging
│       ├── outputs.tf                       <- URLs e IDs de recursos gerados
│       ├── finops_cost_estimator.py         <- [LAB 07] Estimador de custos pré-deploy (Shift-Left)
│       ├── finops_actual_tracker.py         <- [LAB 07] Rastreador de custos reais via AWS Cost Explorer
│       ├── tests/
│       │   └── test_lab02_owasp_redteam.py  <- [LAB 02] Suíte de testes ofensivos automatizados
│       └── README.md                        <- Guia de execução do Terraform
├── labs/
│   ├── LAB01_Setup_and_Insecure_Chat.md     <- Guia passo a passo de deploy AWS
│   ├── LAB02_OWASP_Top10_Exploitation.md   <- Roteiro com 6 ataques do OWASP Top 10
│   ├── LAB03_Bedrock_Guardrails_Setup.md   <- Guia de criação de Bedrock Guardrails
│   ├── LAB04_RAG_and_Data_Poisoning.md     <- Laboratório de RAG, Injeção Indireta e Grounding
│   ├── LAB05_Observability_XRay_ApplicationSignals.md <- Guia de Observabilidade GenAI
│   ├── LAB06_DevSecOps_Terraform_Guardrails.md <- Guia de DevSecOps, Terraform e Policy-as-Code
│   └── LAB07_FinOps_GenAI_Cost_Management.md   <- Guia de FinOps para IA Generativa
└── datasets_poisoning/
    ├── politica_reembolso_legitima.txt      <- Documento corporativo limpo para testes RAG
    └── politica_reembolso_envenenada.txt    <- Documento com payload de injeção indireta oculta
```

---

## ⚡ Início Rápido

1. **Backend:** Suba o código de [`bedrockChatFunction.py`](bedrockChatFunction.py) na sua função AWS Lambda (Python 3.12).
2. **Frontend:** Configure o endpoint do API Gateway no arquivo [`chat.html`](chat.html) e faça o upload para o seu bucket S3 com hospedagem de site estático habilitada.
3. **Modelos Recomendados:** Utilize o modelo `meta.llama3-8b-instruct-v1:0` ou `us.amazon.nova-lite-v1:0` no console do Bedrock para demonstrar os ataques e vulnerabilidades antes da ativação dos Guardrails.
4. **Laboratórios:** Siga o passo a passo nos arquivos da pasta `labs/`.

---

## 🎓 Recursos e Referências

* [OWASP Top 10 for Large Language Model Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
* [AWS Bedrock Guardrails Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)
* [Amazon Bedrock Converse API Reference](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference.html)
* [AWS Well-Architected Framework - Machine Learning Lens](https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/welcome.html)