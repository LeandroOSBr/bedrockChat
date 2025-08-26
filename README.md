# 🚀 Projeto: Chat com IA usando AWS Bedrock

## 📚 Visão Geral

Este projeto demonstra como criar um sistema de chat com IA usando AWS Bedrock, Lambda, API Gateway e S3. É uma excelente oportunidade para praticar conceitos de Cloud Computing e Segurança de Aplicações de IA.

## 🎯 Objetivos de Aprendizagem

- Configurar serviços AWS (Lambda, API Gateway, S3, Bedrock)
- Implementar uma função Lambda para processar mensagens
- Configurar API Gateway com CORS
- Hospedar interface web em S3
- Trabalhar com modelos de IA via AWS Bedrock

## 🏗️ Arquitetura do Sistema

```
[Usuário] → [S3 (Site Estático)] → [API Gateway] → [Lambda] → [Bedrock (Claude 3 Haiku)]
```

## 📋 Pré-requisitos

- Conta AWS ativa
- Logado com usuário **root**
- Região escolhida **Norte da Virgínia us-east-1**
- Acesso ao serviço AWS Bedrock
- Conhecimento básico de Python e HTML/JavaScript

## 🔧 Configuração Passo a Passo

### 1. Configuração do AWS Bedrock

#### 1.1 Acessar o Console AWS Bedrock
- Faça login no [Console AWS](https://console.aws.amazon.com/)
- No console, procure por **Bedrock** na barra de pesquisa (digite "bedrock")
- Clique no serviço **Amazon Bedrock** quando aparecer
- **IMPORTANTE**: Solicite acesso aos modelos Anthropic (Claude)

#### 1.2 Solicitar Acesso ao Modelo proposto
- No console do Bedrock, no menu lateral esquerdo, no final, clique em **Acesso ao modelo**
- Clique no botão **Gerenciar acesso ao modelo** (botão azul no centro da tela) ou **Modificar acesso aos modelos** (botão laranja)
- Na lista de provedores, procure por **Claude 3 Haiku** (deve estar na lista)
- Clique na caixa de seleção ao lado de do modelo
- Clique no botão **Próximo** no final da página (botão laranja)
- Em seguida, clique no botão **Enviar** (botão laranja)
- Você verá uma mensagem "Solicitação enviada com sucesso" ou "Atualizações de acesso a modelo enviadas"
- **IMPORTANTE**: A aprovação pode levar algumas horas.
- **DICA**: Enquanto aguarda, continue com os próximos passos até que o modelo esteja disponível;

### 2. Criação da Função Lambda

#### 2.1 Criar Nova Função
- No console AWS, procure por **Lambda** na barra de pesquisa (digite "lambda")
- Clique no serviço **Lambda** quando aparecer
- Na página do Lambda, clique no botão **Criar função** (botão laranja)
- Na tela "Criar função", selecione **Criar do zero** (primeira opção)
- Agora configure os campos:
  - **Nome da função**: Digite exatamente `bedrockChatFunction` (sem espaços)
  - **Runtime**: Clique na seta e selecione `Python 3.12` (ou superior)
  - **Arquitetura**: Deixe marcado `x86_64` (padrão)
  - **Função de execução**: Selecione `Criar uma nova função com permissões básicas do Lambda`
- Clique no botão **Criar função** (botão laranja na parte inferior)
- **AGUARDE** a função ser criada (pode demorar alguns segundos)

#### 2.2 Configurar Permissões IAM
- Após criar a função, você estará na tela da função Lambda
- No menu superior, clique na aba **Configuração**
- No menu lateral esquerdo, clique em **Permissões**
- Na seção "Papel de execução", você verá um link azul com o nome da role (algo como "bedrockChatFunction-role-abc123")
- **CLIQUE** nesse link azul (ele abrirá o console IAM em uma nova aba)
- Na nova aba do IAM, clique no botão **Adicionar permissões** e em seguida **Anexar políticas** (botão azul)
- Na barra de pesquisa, digite `AmazonBedrockFullAccess`
- Marque a caixa ao lado de `AmazonBedrockFullAccess`
- Clique no botão **Adicionar permissões** (botão laranja na parte inferior)
- Você verá a mensagem "Êxito ao anexar a política ao perfil."
- **VOLTE** para a aba do Lambda (não feche a aba do IAM ainda)


#### 2.3 Configurar Timeout
- Na aba do Lambda, clique na aba **Configuração** (se não estiver selecionada)
- No menu lateral esquerdo, clique em **Configuração geral**
- Clique no botão **Editar**  em "Configuração geral"
- Na seção "Configurações básicas", procure por **Tempo limite**
- Mude o valor de **3 seg** para **1 min e 30** segundos
- Clique no botão **Salvar** (botão laranja)
- Você verá a mensagem "A função [NOME DA FUNÇÃO] foi atualizada com êxito."

#### 2.4 Fazer Upload do Código
- Na aba do Lambda, clique na aba **Código** (deve estar selecionada por padrão)
- No editor de código, você verá um arquivo chamado `lambda_function.py` com código de exemplo
- **DELETE** todo o conteúdo desse arquivo (Ctrl+A, depois Delete)
- Abra o arquivo `bedrockChatFunction.py` que você baixou do projeto
- **COPIE** todo o conteúdo (Ctrl+A, Ctrl+C)
- **VOLTE** para o editor do Lambda e cole o código (Ctrl+V)
- Clique no botão **Deploy** (botão azul)
- **AGUARDE** a mensagem informando que função foi atualizada com sucesso.
- **IMPORTANTE**: Se aparecer algum erro, verifique se copiou todo o código corretamente

### 3. Configuração do Gatilho HTTP na Função Lambda

#### 3.1 Adicionar Gatilho HTTP
- Na função Lambda, em **Visão geral da função**
- Na seção "Gatilhos", clique no botão **+ Adicionar gatilho** (botão azul)
- Na tela "Adicionar gatilho", configure:
  - Em "Configuração do gatilho", no combo logo abaixo "Selecione uma origem" Selecione **API Gateway** na lista
  - Em "Intenção", marque a opção "Criar uma API"
  - Em **Tipo de API**: Selecione a opção **API HTTP**  
  - **Método de segurança**: Selecione **Abrir** (permite acesso público)  
  - Clique no botão **Adicionar** (botão laranja)
  - Aguarde até que a mensagem "O gatilho [[NOME DA FUNÇÃO]-API] foi adicionado com êxito à função [NOME DA FUNÇÃO]. A função agora recebe eventos do gatilho."
 

#### 3.2 Verificar Configuração
- Após adicionar o gatilho, você verá na seção "Gatilhos":
  - **API Gateway** com o nome `[NOME DA FUNÇÃO]-API`
  - Endpoint de API: algo parecido com "https://********.execute-api.[REGIÃO].amazonaws.com/default/[NOME DA FUNÇÃO]"
  

**IMPORTANTE**: **COPIE** essa URL do "Endpoint de API" e **ANOTE** em um lugar seguro - você precisará dela depois!
- **DICA**: A URL termina com `/default` - isso é normal

### 4. Configuração do Bucket S3

#### 4.1 Criar Bucket
- No console AWS, procure por **S3** na barra de pesquisa (digite "s3")
- Clique no serviço **S3** quando aparecer
- Na página do S3, clique no botão **Criar bucket** (botão laranja)
- Na tela "Criar bucket", configure:
  - **Nome do bucket**: Digite `seu-nome-bedrock-chat` (substitua "seu-nome" pelo seu nome real)
  - **IMPORTANTE**: O nome deve ser único no mundo inteiro, então adicione números se necessário
  - **Região**: Clique na seta e selecione a mesma região dos outros serviços (provavelmente `us-east-1`)
  - **Propriedade de objeto**: Deixe marcado `ACLs desabilitados` (padrão)
  - **Configurações de bloqueio de acesso público**: **DESMARQUE** a caixa "Bloquear todo o acesso público"
  - **Controle de versão do bucket**: Deixe desmarcado (não precisamos)
  - **Criptografia padrão**: Deixe marcado `Habilitar` (padrão)
- Clique no botão **Criar bucket** (botão laranja na parte inferior)
- **AGUARDE** a mensagem "Bucket criado com sucesso"

#### 4.2 Configurar Permissões
- Após criar o bucket, clique no nome do bucket na lista
- Na página do bucket, clique na aba **Permissões** (no topo)
- Role a página para baixo até encontrar **Política do bucket**
- Clique no botão **Editar** (botão azul)
- Na tela "Editar política do bucket", você verá um editor de texto
- **DELETE** todo o conteúdo que estiver lá
- **COPIE** e cole a política abaixo:

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

**IMPORTANTE**: Substitua `SEU-BUCKET-NAME` pelo nome real do seu bucket!
- **EXEMPLO**: Se seu bucket se chama `joao-bedrock-chat-123`, a linha ficará:
  `"Resource": "arn:aws:s3:::joao-bedrock-chat-123/*"`
- Clique no botão **Salvar alterações** (botão azul)
- **AGUARDE** a mensagem "Política do bucket atualizada com sucesso"

#### 4.3 Configurar Site Estático
- Na mesma página do bucket, clique na aba **Propriedades** (no topo)
- Role a página para baixo até encontrar **Hospedagem de site estático**
- Clique no botão **Editar** (botão azul)
- Na tela "Editar hospedagem de site estático", configure:
  - **Hospedagem de site estático**: Clique em **Habilitar**
  - **Documento de índice**: Digite `chat.html`  
- Clique no botão **Salvar alterações** (botão laranja)
- **AGUARDE** a mensagem "Hospedagem de site estático atualizada com sucesso"
- **IMPORTANTE**: Após salvar, você verá a URL do seu site em "Endpoint de site de bucket" (algo como `http://[NOME DO BUCKET].s3-website-[REGIÃO].amazonaws.com`)
- **COPIE** essa URL também - você precisará dela!

### 5. Configuração Final

#### 5.1 Atualizar API Gateway
- Abra o arquivo `chat.html` que você baixo do projeto em um editor de texto (Notepad, VS Code, etc.)
- Procure pela linha que contém `const API_ENDPOINT` (use Ctrl+F para encontrar)
- Você verá algo como:
  ```javascript
  const API_ENDPOINT = 'https://abc123def.execute-api.us-east-1.amazonaws.com/default/[NOME DA FUNÇÃO]'
  ```
- **SUBSTITUA** toda essa linha pela URL do seu API Gateway
- **EXEMPLO**: Se sua URL é `https://xyz789.execute-api.us-east-1.amazonaws.com/default`, a linha ficará:
  ```javascript
  const API_ENDPOINT = 'https://xyz789.execute-api.us-east-1.amazonaws.com/default'
  ```
- **IMPORTANTE**: Não esqueça das aspas e do ponto e vírgula no final!
- **SALVE** o arquivo

#### 5.2 Fazer Upload dos Arquivos
- Na mesma página do bucket, clique na aba **Objetos** (deve estar selecionada por padrão)
- Clique no botão **Carregar** (botão laranja)
- Na tela "Carregar", clique no botão **Adicionar arquivos** (botão azul)
- Selecione o arquivo `chat.html` que você baixou do projeto
- **IMPORTANTE**: Antes de fazer upload, precisamos renomear o arquivo
- Clique no botão **Carregar** (botão laranja na parte inferior)
- **AGUARDE** a mensagem "Upload concluído com sucesso"
- **VERIFIQUE**: O arquivo deve aparecer na lista com o nome `chat.html`

#### 5.3 Configurar API Gateway
##### 5.3.1 Rotas
- No console AWS, procure por **API GATEWAY** na barra de pesquisa (digite "API Gateway")
- Clique no serviço **API GATEWAY** quando aparecer
- Clique no recurso **[NOME DA FUNÇÃO]-API** criada via AWS Lambda
- Clique em **Routes**, no menu a esquerda;
- Clique em **ANY** em "Rotas para [NOME DA FUNÇÃO]-API";
- Em **Detalhes da rota**, clique em **Editar** (botão azul)
- Em "Editar rota" e "Rota e método", onde está **ANY**, altere para "POST" e clique no botão Salvar
- Em "Rotas para [NOME DA FUNÇÃO]-API", clique em **Criar** (botão em azul);
- Em "Editar rota" e "Rota e método", onde está **ANY**, altere para "OPTIONS" e altere o "/" para "/[NOME DA FUNÇÃO]" e clique no botão Salvar

##### 5.3.2 CORS:
- Ainda na console do API Gateway, vá em **CORS** no menu a esquerda logo abaixo de "Develop"
- Em "Compartilhamento de recursos entre origens (CORS)", clique no botão **Configurar** (botão azul);
- No campo "Access-Control-Allow-Origin", informe a URI do seu bucket, aquele copiado no passo 4.3, cole a URI do bucket e clique em **Adicionar** (botão azul);
- Em "Access-Control-Allow-Headers", informe o valor "content-type" e clique em **Adicionar** (botão azul);
- Em "Access-Control-Allow-Methods", clique e selecione **POST** e **OPTIONS**.
- Os demais campos deixe como está e clique em **Salvar**, (botão laranja no canto inferior direito);


##### 5.3.3 Implantação do API Gateway
- 
- Clique em **Stages**, no menu a esquerda na seção **Deploy**;
- Em **Estágios** e "Estágios para a [NOME DA FUNÇÃO]-API", clique em **Criar** (botão azul);
- Em **Detalhes do estágio**, informe o nome "dev" e clique em **Criar**, no canto inferior esquerdo da página.
- Ainda na página de detalhes do "API Gateway", clique no botão **Implantar** (botão laranja)
- Selecione o Estágio "dev" e clique no botão **Implantar** (botão laranja)
- **IMPORTANTE**: Abaixo do "/[NOME DA FUNÇÃO]", agora estará o "OPTIONS e o "POST". Observe que a direite, em "Detalhes da rota" quando a rota "POST" estiver selecionada, será apresentada uma integração. Ao selecionar a rota "OPTIONS", no lugar do nome da integração estará o texto "Nenhuma integração anexada a essa rota.". Isso é para que quando o método for "POST", a requisição deverá ser enviada à função Lamda. Caso o método seja "OPTIONS", o próprio API Gateway é quem irá responder;


#### 5.2 Testar o Sistema
- Assegure que o modelo que você solicitou autorização de acesso, esteja disponível;
- **TESTE** o sistema:
  - Acesse a URL do seu site S3 (que você copiou no passo 4.3)
  - Você deve ver a interface do chat
  - Digite uma mensagem como "Olá, como você está?"
  - Clique no botão de enviar (seta →)
  - **AGUARDE** a resposta da IA (pode demorar alguns segundos)
- **SE FUNCIONAR**: Parabéns! Seu projeto está funcionando!
- **SE NÃO FUNCIONAR**: Continue lendo para resolver problemas

## 📋 Resumo dos Passos Realizados

### ✅ O que você acabou de configurar:
1. **AWS Bedrock** - Serviço de IA (aguardando aprovação)
2. **Lambda Function** - Função que processa as mensagens
3. **Gatilho HTTP** - Interface para receber requisições via API Gateway
4. **S3 Bucket** - Site estático para o chat
5. **Sistema funcionando** - Chat com IA operacional

### 🔄 Próximos passos (nas próximas aulas):
- Melhorar postura de segurança!

---



## 🚨 Solução de Problemas Comuns

### ❌ Erro: CORS no Frontend
**O que significa**: O navegador bloqueia a comunicação entre o site e a API
**Como identificar**: Mensagem de erro no console do navegador (F12)
**Como resolver**:
1. Verifique se o CORS está habilitado no API Gateway
2. Confirme se a URL da API no arquivo `chat.html` está correta
3. Verifique se não há espaços extras na URL
4. Teste se a API está funcionando (pode usar o botão "Test" na função Lambda)

### 🎯 Antes de continuar, verifique se TUDO está funcionando:


### 🎉 Se TUDO estiver funcionando:
**Parabéns!** Você configurou com sucesso um sistema de chat com IA na AWS!
- ✅ Sua função Lambda está processando mensagens
- ✅ Seu API Gateway está recebendo requisições
- ✅ Seu site S3 está funcionando
- ✅ A IA está respondendo às mensagens

**Agora você pode continuar para as próximas aulas onde implementaremos medidas de segurança!**

---

## 📚 Recursos Adicionais

- [Documentação AWS Bedrock](https://docs.aws.amazon.com/bedrock/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [API Gateway Tutorial](https://docs.aws.amazon.com/apigateway/)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

## 🤝 Suporte

Para dúvidas sobre este projeto:
- Consulte a documentação oficial da AWS
- Use o fórum da disciplina
- Conversaremos na aula síncrona!

---

**⚠️ IMPORTANTE**: Este projeto é para fins educacionais. Em produção, implemente medidas de segurança mais robustas e siga as melhores práticas da AWS.

**🎓 Boa sorte nos estudos!** 🚀