# 🧪 LAB 01: Provisionamento Serverless e Chat Inseguro na AWS

## 🎯 Objetivos de Aprendizagem
- Configurar permissões e acesso aos modelos de Fundação no **Amazon Bedrock**.
- Implementar o backend com **AWS Lambda (Python 3.12)** utilizando a **Bedrock Converse API**.
- Configurar o **API Gateway (HTTP API)** com suporte a CORS.
- Hospedar a interface web estática no **Amazon S3**.
- Observar o funcionamento de uma aplicação LLM sem camadas externas de defesa (*baseline*).

---

## 🏗️ Arquitetura do Laboratório

```
┌──────────────┐      ┌───────────────┐      ┌──────────────┐      ┌────────────────────────┐
│  Navegador   │ ---> │  Amazon S3    │      │  API Gateway │ ---> │ AWS Lambda             │
│  (Estudante) │      │ (Site Estático│ ---> │  (HTTP API)  │      │ (bedrockChatFunction)  │
└──────────────┘      └───────────────┘      └──────────────┘      └───────────┬────────────┘
                                                                               │
                                                                               ▼
                                                                   ┌────────────────────────┐
                                                                   │ Amazon Bedrock         │
                                                                   │ (Llama 3 / Titan)      │
                                                                   └────────────────────────┘
```

---

## 📋 Passo a Passo de Configuração

### 1. Acesso aos Modelos no Amazon Bedrock (Acesso Automático / Simplificado)

> [!NOTE]
> **Atualização da AWS**: A página tradicional *"Model access"* foi descontinuada pela AWS. Os modelos de Fundação Serverless (como **Meta Llama 3**, **Llama 3.1** e **Amazon Titan**) agora são **habilitados automaticamente sob demanda** assim que sua função Lambda ou o console faz a primeira chamada (inferência), desde que sua conta/role IAM possua permissões do Bedrock.

#### Como validar a disponibilidade dos modelos:
1. Acesse o **Console AWS** na região **us-east-1 (N. Virginia)**.
2. No menu de busca, digite **Bedrock** e clique em **Amazon Bedrock**.
3. No menu lateral esquerdo, clique em **Model catalog** (Catálogo de modelos).
4. Você pode explorar os modelos disponíveis:
   - **Meta:** `Llama 3 8B Instruct` ou `Llama 3.1 8B Instruct` (Modelos recomendados para a aula)
   - **Amazon:** `Titan Text G1 - Express`
   - **Anthropic:** `Claude 3 Haiku`
5. *(Opcional)* Clique em **Playgrounds** > **Chat** no menu lateral para fazer um teste interativo rápido. 
   *(Nota: Para modelos Anthropic Claude, se for o primeiro uso na conta, a AWS pode exibir um breve formulário solicitando informações do caso de uso da empresa/estudo).*

---

### 2. Criar e Configurar a Função Lambda
1. No console AWS, acesse o serviço **AWS Lambda** e clique em **Criar função**.
2. Selecione **Criar do zero**:
   - **Nome da função:** `bedrockChatFunction`
   - **Runtime:** `Python 3.12`
   - **Arquitetura:** `x86_64`
   - **Permissões:** `Criar uma nova função com permissões básicas do Lambda`
3. Clique em **Criar função**.

#### 2.1 Anexar Permissões do Bedrock à IAM Role
1. Na aba **Configuração** > **Permissões**, clique no nome da role (perfil de execução).
2. Na aba do IAM, clique em **Adicionar permissões** > **Anexar políticas**.
3. Procure por `AmazonBedrockFullAccess` e anexe à role.

#### 2.2 Ajustar Timeout
1. Na aba **Configuração** > **Configuração geral** > **Editar**:
   - Altere o **Tempo limite (Timeout)** de `3s` para `1 min e 30s`.
2. Clique em **Salvar**.

#### 2.3 Upload do Código
1. Na aba **Código**, abra o editor e substitua o conteúdo do arquivo pelo código de `bedrockChatFunction.py`.
2. Clique no botão **Deploy**.

---

### 3. Configurar o API Gateway (HTTP API)
1. Na tela da função Lambda, na seção *Visão geral da função*, clique em **+ Adicionar gatilho**.
2. Em **Origem**, selecione **API Gateway**:
   - **Intenção:** `Criar uma API`
   - **Tipo de API:** `API HTTP`
   - **Segurança:** `Aberta` (Open)
3. Clique em **Adicionar** e copie o **Endpoint de API** gerado (ex: `https://xxxx.execute-api.us-east-1.amazonaws.com/default/bedrockChatFunction`).

#### 3.1 Configurar CORS no API Gateway
1. No serviço **API Gateway**, acesse a API criada.
2. No menu lateral, clique em **CORS** > **Configurar**:
   - **Access-Control-Allow-Origin:** `*`
   - **Access-Control-Allow-Headers:** `content-type,authorization,x-amz-date,x-api-key,x-amz-security-token`
   - **Access-Control-Allow-Methods:** `POST, OPTIONS`
3. Clique em **Salvar**.

---

### 4. Hospedagem Frontend no Amazon S3
1. Acesse o **Amazon S3** e crie um bucket com nome único (ex: `lab-seguranca-ia-seu-nome`).
2. **Desmarque** a opção *Bloquear todo o acesso público* e confirme o aviso de risco.
3. Na aba **Propriedades** > **Hospedagem de site estático**:
   - Habilite e defina o documento de índice como `chat.html`.
4. Na aba **Permissões** > **Política do bucket**, adicione a permissão de leitura pública:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::SEU-BUCKET-NAME/*"
        }
    ]
}
```
5. No arquivo local `chat.html`, atualize a constante `API_ENDPOINT` com a URL da sua API Gateway criada no passo 3.
6. Faça o upload do arquivo `chat.html` para o bucket S3.

---

### 5. Validação do Ambiente
- Abra a URL do site gerada pelo S3 (encontrada na aba *Propriedades* > *Hospedagem de site estático*).
- Envie a mensagem: `"Olá! Você está funcionando?"`.
- Certifique-se de que a IA responde normalmente. O ambiente de testes desprotegido está pronto para a exploração no **LAB 02**.
