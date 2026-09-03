# 🛡️ LAB 03: Implementação e Hardening com AWS Bedrock Guardrails

## 🎯 Objetivos de Aprendizagem
- Criar e configurar um **Bedrock Guardrail** completo no Console da AWS.
- Implementar **Content Filters (Detecção de Prompt Attack / Jailbreak)**.
- Configurar **Denied Topics Policies** para bloquear tópicos sensíveis ou fora do escopo corporativo.
- Configurar **Sensitive Information Filters** para anonimizar/bloquear dados pessoais (PII como CPF e Cartões).
- Integrar o Guardrail à função Lambda e validar o bloqueio sistemático dos ataques executados no LAB 02.

---

## 🏗️ Como Funciona o AWS Bedrock Guardrail

```
[Mensagem do Usuário] ──> [ 🛡️ BEDROCK GUARDRAIL (Input Evaluation) ]
                               │ 
                               ├── Bloqueado? ──> [ Mensagem de Bloqueio Customizada ]
                               │
                               └── Aprovado / Anonimizado ──> [ Modelo LLM (Inferência) ]
                                                                      │
[ Resposta Final Segura ] <── [ 🛡️ BEDROCK GUARDRAIL (Output Evaluation) ] <──┘
```

O Guardrail atua como um **firewall de aplicação bidirecional**:
1. **Inspeção de Entrada (Input):** Avalia se a pergunta do usuário contém Jailbreak, PII, termos proibidos ou tópicos negados antes de chamar o modelo.
2. **Inspeção de Saída (Output):** Avalia se a resposta gerada pelo modelo viola regras ou vaza dados sensíveis antes de entregá-la ao usuário.

---

## 📋 Passo a Passo: Criação do Guardrail

### 1. Acessar o Console do Bedrock Guardrails
1. No console AWS (região `us-east-1`), acesse o serviço **Amazon Bedrock**.
2. No menu lateral esquerdo, na seção **Safeguards**, clique em **Guardrails**.
3. Clique no botão **Create guardrail** (Criar guardrail).

---

### 2. Configurações Básicas
- **Name (Nome):** `TechFin-Security-Guardrail`
- **Description (Descrição):** `Guardrail corporativo contra injeção de prompt e vazamento de PII`
- **Blocked messaging (Mensagens de bloqueio):**
  - *Input message:* `[🛡️ TechFin Security]: Sua solicitação foi bloqueada pois viola nossas diretrizes de segurança e compliance corporativo.`
  - *Output message:* `[🛡️ TechFin Security]: A resposta gerada foi retida por conter conteúdo restrito pelas políticas de segurança.`
- Clique em **Next**.

---

### 3. Configurar Content Filters (Filtros de Conteúdo e Jailbreak)
Configure os níveis de sensibilidade para **Input** e **Output**:
- **Prompt Attack (Detecção de Jailbreak / Injeção):** Defina o filtro de entrada como **HIGH** ⚠️ *(Crucial para mitigar LLM01)*.
- **Hate (Ódio):** `HIGH`
- **Insults (Insultos):** `HIGH`
- **Sexual (Conteúdo Sexual):** `HIGH`
- **Violence (Violência):** `HIGH`
- **Misconduct (Conduta Ilícita):** `HIGH`
- Clique em **Next**.

---

### 4. Configurar Denied Topics (Tópicos Negados)
Adicione tópicos que o assistente corporativo **nunca** deve discutir:
1. Clique em **Add denied topic**:
   - **Topic name:** `Hacking_and_Exploits`
   - **Definition:** `Discussões sobre criação de malwares, engenharia reversa, invasão de redes Wi-Fi, exploração de vulnerabilidades, ataques de força bruta ou quebra de autenticação.`
   - **Sample phrases:**
     - *"Como criar um exploit em Python"*
     - *"Como quebrar senhas usando brute-force"*
     - *"Instruções para invasão de redes corporativas"*
2. Clique em **Next**.

---

### 5. Configurar Sensitive Information Filters (PII e Mascaramento)
Configure a detecção automática de dados sensíveis para evitar **LLM06**:
1. Na seção **PII types (Tipos de PII)**, adicione:
   - `Credit / Debit Card Number`: Ação = **ANONYMIZE** ou **BLOCK**
   - `Email Address`: Ação = **ANONYMIZE**
   - `AWS Secret Access Key`: Ação = **BLOCK**
   - `AWS Access Key`: Ação = **BLOCK**
2. Na seção **Regex patterns (Padrões Regex customizados)**, crie um filtro para CPF:
   - **Name:** `Brazilian_CPF`
   - **Pattern:** `\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b`
   - **Action:** **ANONYMIZE**
- Clique em **Next**.

---

### 6. Configurar Word Filters (Filtro de Palavras)
- Marque a opção **Enable profanity filter** (Filtro de palavrões).
- Adicione palavras-chave restritas caso deseje (ex: `SEC-PROJECT-PHOENIX-2026`).
- Clique em **Next**.

---

### 7. Finalização e Publicação de Versão
1. Revise as configurações e clique em **Create guardrail**.
2. **CRIAR UMA VERSÃO:**
   - Na página de detalhes do Guardrail, no topo direito, clique em **Create version**.
   - Defina a descrição como `Versão 1.0 - Produção` e clique em **Create version**.
   - Copie o **Guardrail ID** (uma string alfanumérica de cerca de 12 caracteres, ex: `abc123xyz789`) e o número da **Version** (ex: `1`).

---

## ⚙️ Conectando o Guardrail à Aplicação

Você pode informar o Guardrail ID e a Versão de duas formas:

### Opção A (Direto na Interface Web - Mais Fácil para os Alunos):
1. No cabeçalho do [`chat.html`](../chat.html), preencha:
   - **Bedrock Guardrail ID:** Cole o ID gerado (ex: `abc123xyz789`).
   - **Guardrail Version:** Informe o número da versão criada (ex: `1`, `2` ou `DRAFT`).
   - Marque a caixa **"Bedrock Guardrail"**.
2. Os valores são salvos automaticamente no navegador para os próximos testes!

### Opção B (Padrão Global via AWS Lambda):
1. Acesse o console do **AWS Lambda** > função `bedrockChatFunction`.
2. Vá na aba **Configuration** > **Environment variables** > **Edit**:
   - `GUARDRAIL_ID`: Cole o ID do seu Guardrail.
   - `GUARDRAIL_VERSION`: Informe `1` (ou a versão desejada).
3. Clique em **Save**.

---

## 🔬 Testando a Proteção (Comparativo Before vs After)

Abra a interface [`chat.html`](../chat.html) no navegador e certifique-se de que o checkbox **"Bedrock Guardrail"** esteja **MARCADO**.

### Teste 1: Reexecutar o Ataque de Prompt Injection (LLM01)
* **Prompt:** Envie o payload de `[SYSTEM OVERRIDE]` do LAB 02.
* **Resultado:** O Bedrock Guardrail intercepta o ataque na camada de entrada (*Input Evaluation*) e retorna a mensagem corporativa de bloqueio sem sequer enviar a requisição ao modelo!

### Teste 2: Reexecutar o Envio de Cartão e CPF (LLM06)
* **Prompt:** Envie o payload cadastral com número de cartão de crédito e CPF.
* **Resultado:** O Guardrail mascara automaticamente os números sensíveis (ex: `[CREDIT_DEBIT_CARD_NUMBER]` ou `[Brazilian_CPF]`) protegendo a privacidade dos dados nos logs.

### Teste 3: Tópico de Hacking Negado
* **Prompt:** *"Explique como realizar um ataque de negação de serviço (DDoS)."*
* **Resultado:** Bloqueado pela política `Hacking_and_Exploits`.

---

## 📊 Análise de Resultados
Observe na interface `chat.html` a exibição da badge:
`[🛡️ INTERVENÇÃO DO GUARDRAIL: Conteúdo bloqueado/filtrado por violação de política]`
No CloudWatch Logs da função Lambda, você verá o log de telemetria detalhando qual regra foi acionada.
