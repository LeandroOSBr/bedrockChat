# 🛡️ Lab de Segurança em Cloud Computing e Aplicações de IA (AWS Bedrock)

Material didático e laboratórios práticos desenvolvidos para a disciplina **Cloud Computing e Segurança de Aplicações de IA**.

O objetivo deste projeto é guiar os estudantes através de uma jornada completa de segurança em IA Generativa:
1. **Construção de uma Aplicação Serverless** com AWS Lambda, API Gateway, S3 e Bedrock.
2. **Exploração de Vulnerabilidades** com base no **OWASP Top 10 for Large Language Models (LLM)**.
3. **Hardening e Defesa Ativa** utilizando **AWS Bedrock Guardrails** (Filtros de Jailbreak, Anonimização de PII, Tópicos Negados).
4. **Data Poisoning & RAG Hardening** demonstrando **Injeção Indireta de Prompt** em bases de conhecimento e mitigação com **Contextual Grounding**.

---

## 🏗️ Arquitetura do Sistema

```
[ Usuário / Aluno ] 
        │
        ▼
[ Amazon S3 ] ──(Interface Web chat.html)
        │
        ▼ (Requisição HTTP / JSON)
[ Amazon API Gateway ] ──(HTTP API + CORS)
        │
        ▼
[ AWS Lambda (bedrockChatFunction.py) ] ──(Bedrock Converse API)
        │
        ├── 🛡️ AWS Bedrock Guardrails (Input & Output Inspection)
        │
        ▼
[ Amazon Bedrock (Meta Llama 3 / Titan / Claude 3) ]
```

---

## 📚 Trilha de Laboratórios Práticos

A disciplina é estruturada em 4 laboratórios modulares:

| Laboratório | Arquivo | Descrição |
| :--- | :--- | :--- |
| **LAB 01** | [`labs/LAB01_Setup_and_Insecure_Chat.md`](labs/LAB01_Setup_and_Insecure_Chat.md) | Provisionamento inicial da arquitetura Serverless e deploy do chat base desprotegido. |
| **LAB 02** | [`labs/LAB02_OWASP_Top10_Exploitation.md`](labs/LAB02_OWASP_Top10_Exploitation.md) | Execução de ataques práticos: Prompt Injection, Jailbreaking, Vazamento de PII (LLM06), System Prompt Extraction (LLM07) e XSS (LLM02). |
| **LAB 03** | [`labs/LAB03_Bedrock_Guardrails_Setup.md`](labs/LAB03_Bedrock_Guardrails_Setup.md) | Criação de Guardrails no console AWS, configuração de políticas de conteúdo/Jailbreak/PII e testes comparativos (*Before vs After*). |
| **LAB 04** | [`labs/LAB04_RAG_and_Data_Poisoning.md`](labs/LAB04_RAG_and_Data_Poisoning.md) | Simulação de RAG, envenenamento de documentos (*Indirect Prompt Injection*) e mitigação com **Contextual Grounding**. |

---

## 📁 Estrutura do Repositório

```text
bedrockChat/
├── README.md                                <- Documento principal e visão geral da disciplina
├── bedrockChatFunction.py                   <- Função Lambda backend (Bedrock Converse API)
├── chat.html                                <- Frontend web educacional com presets OWASP e telemetria
├── labs/
│   ├── LAB01_Setup_and_Insecure_Chat.md     <- Guia passo a passo de deploy AWS
│   ├── LAB02_OWASP_Top10_Exploitation.md   <- Roteiro com 6 ataques do OWASP Top 10
│   ├── LAB03_Bedrock_Guardrails_Setup.md   <- Guia de criação de Bedrock Guardrails
│   └── LAB04_RAG_and_Data_Poisoning.md     <- Laboratório de RAG, Injeção Indireta e Grounding
└── datasets_poisoning/
    ├── politica_reembolso_legitima.txt      <- Documento corporativo limpo para testes RAG
    └── politica_reembolso_envenenada.txt    <- Documento com payload de injeção indireta oculta
```

---

## ⚡ Início Rápido

1. **Backend:** Suba o código de [`bedrockChatFunction.py`](bedrockChatFunction.py) na sua função AWS Lambda (Python 3.12).
2. **Frontend:** Configure o endpoint do API Gateway no arquivo [`chat.html`](chat.html) e faça o upload para o seu bucket S3 com hospedagem de site estático habilitada.
3. **Modelos Recomendados:** Habilite o modelo `meta.llama3-8b-instruct-v1:0` ou `amazon.titan-text-express-v1` no console do Bedrock para permitir a demonstração didática dos ataques antes da ativação dos Guardrails.
4. **Laboratórios:** Siga o passo a passo nos arquivos da pasta `labs/`.

---

## 🎓 Recursos e Referências

* [OWASP Top 10 for Large Language Model Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
* [AWS Bedrock Guardrails Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)
* [Amazon Bedrock Converse API Reference](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference.html)
* [AWS Well-Architected Framework - Machine Learning Lens](https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/welcome.html)