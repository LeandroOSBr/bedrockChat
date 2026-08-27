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
> **Atualização da AWS**: A página tradicional *"Model access"* foi descontinuada pela AWS. Os modelos de Fundação Serverless (como **Meta Llama 3**, **Llama 3.1** e **Amazon Nova**) agora são **habilitados automaticamente sob demanda** assim que sua função Lambda ou o console faz a primeira chamada (inferência), desde que sua conta/role IAM possua permissões do Bedrock.

#### Como validar a disponibilidade dos modelos:
1. Acesse o **Console AWS** na região **us-east-1 (N. Virginia)**.
2. No menu de busca, digite **Bedrock** e clique em **Amazon Bedrock**.
3. No menu lateral esquerdo, clique em **Model catalog** (Catálogo de modelos).
4. Você pode explorar os modelos disponíveis:
   - **Meta:** `Llama 3 8B Instruct` (`meta.llama3-8b-instruct-v1:0`) ou `Llama 3.1 8B Instruct` (`us.meta.llama3-1-8b-instruct-v1:0`)
   - **Amazon:** `Amazon Nova Lite v1` (`us.amazon.nova-lite-v1:0`) ou `Amazon Nova Micro v1` (`us.amazon.nova-micro-v1:0`)
   - **Anthropic:** `Claude 3.5 Haiku` (`us.anthropic.claude-3-5-haiku-20241022-v1:0`)
5. *(Opcional)* Clique em **Playgrounds** > **Chat** no menu lateral para fazer um teste interativo rápido. 
   *(Nota: O antigo Claude 3 Haiku foi marcado como Legacy pela Anthropic/AWS; caso vá utilizar a Anthropic, utilize a nova versão 3.5 Haiku).*

---

### 2. Criar e Configurar a Função Lambda (AWS Lambda)

1. No console AWS, acesse o serviço **Lambda** (certifique-se de estar na região `us-east-1` / N. Virginia).
2. Na página inicial de **Functions**, clique no botão laranja **Create function** (Criar função) no canto superior direito.
3. Na tela de criação:
   - Selecione a opção padrão: **Author from scratch** (Criar do zero).
   - **Function name (Nome da função):** Digite exatamente `bedrockChatFunction` (sem espaços).
   - **Runtime (Tempo de execução):** Selecione `Python 3.12`.
   - **Architecture (Arquitetura):** Mantenha `x86_64`.
   - **Change default execution role (Permissões):** Mantenha a opção padrão marcada: *Create a new role with basic Lambda permissions* (Criar uma nova função com permissões básicas).
4. Role até o final da página e clique no botão laranja **Create function** (Criar função). Aguarde a mensagem de confirmação.

---

#### 2.1 Anexar Permissões do Bedrock à IAM Execution Role
1. Na página da função `bedrockChatFunction`, clique na aba **Configuration** (Configuração).
2. No menu lateral esquerdo, clique em **Permissions** (Permissões).
3. Na seção **Execution role** (Papel de execução), clique no link azul com o nome da role gerada (ex: `bedrockChatFunction-role-xxxx`). Isso abrirá o console do **IAM** em uma nova aba.
4. Na aba do IAM que abriu:
   - Clique no botão **Add permissions** (Adicionar permissões) > selecione **Attach policies** (Anexar políticas).
   - Na barra de busca, digite `AmazonBedrockFullAccess` e marque a caixa de seleção ao lado dela.
   - Clique no botão laranja **Add permissions** (Adicionar permissões) no canto inferior direito.
5. Feche a aba do IAM e retorne à aba da sua função Lambda.

---

#### 2.2 Ajustar o Timeout (Tempo Limite)
1. Na aba **Configuration** (Configuração) da função Lambda:
2. No menu lateral esquerdo, clique em **General configuration** (Configuração geral).
3. Clique no botão **Edit** (Editar).
4. Na seção **Timeout** (Tempo limite), altere de `3 sec` (padrão) para **`1 min 30 sec`** (necessário para inferências de IA sem corte abrupto).
5. Clique no botão laranja **Save** (Salvar).

---

#### 2.3 Upload do Código Python
1. Na função Lambda, clique na aba **Code** (Código) no menu superior.
2. No painel do editor de código, você verá o arquivo `lambda_function.py`.
3. Apague todo o código de exemplo e cole o conteúdo completo do arquivo [`bedrockChatFunction.py`](../bedrockChatFunction.py).
4. Clique no botão **Deploy** (botão azul na barra de ferramentas do editor de código).
5. Aguarde a mensagem verde indicando que o deploy foi realizado com sucesso.

---

### 3. Configurar o Gatilho HTTP (API Gateway)

#### 3.1 Adicionar Trigger na Função Lambda
1. Na página da função Lambda, na seção **Function overview** (Visão geral da função) no topo, clique no botão **+ Add trigger** (+ Adicionar gatilho).
2. No formulário de configuração do gatilho:
   - **Select a source (Selecione uma origem):** Escolha **API Gateway**.
   - **Intent (Intenção):** Selecione **Create a new API** (Criar uma API).
   - **API type (Tipo de API):** Selecione **HTTP API**.
   - **Security (Segurança):** Selecione **Open** (Aberta - sem autenticação para fins de laboratório).
3. Clique no botão laranja **Add** (Adicionar).
4. Na seção *Triggers* (Gatilhos), localize o **API Gateway** recém-criado e **COPIE o Endpoint de API** (ex: `https://xxxxxxxx.execute-api.us-east-1.amazonaws.com/default/bedrockChatFunction`). Guarde este link!

---

#### 3.2 Configurar CORS no API Gateway
1. No console AWS, acesse o serviço **API Gateway** (ou clique no link da API no gatilho).
2. Clique no nome da API criada (algo como `bedrockChatFunction-API`).
3. No menu lateral esquerdo, na seção *Develop*, clique em **CORS**:
4. Clique no botão **Configure** (Configurar) e preencha:
   - **Access-Control-Allow-Origin:** `*`
   - **Access-Control-Allow-Headers:** `content-type,authorization,x-amz-date,x-api-key,x-amz-security-token`
   - **Access-Control-Allow-Methods:** Marque `POST` e `OPTIONS`.
5. Clique no botão laranja **Save** (Salvar).

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
