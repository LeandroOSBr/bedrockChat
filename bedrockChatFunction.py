import json
import boto3

# Cria um cliente do Bedrock Runtime
bedrock_runtime = boto3.client(service_name='bedrock-runtime')

def lambda_handler(event, context):
    """
    Invoca o modelo Anthropic Claude 3 Haiku no Bedrock usando a Messages API.
    """
    
    # 1. Parse da mensagem do usuário
    try:
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('message', '')

        if not user_message:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'A mensagem não pode estar vazia...!'})
            }
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Corpo da requisição em formato JSON inválido.'})
        }

    # 2. Configuração para Claude 3 Haiku com o payload da Messages API
    model_id = 'anthropic.claude-3-haiku-20240307-v1:0'
    
    # AJUSTE PRINCIPAL: O payload agora usa o formato "messages"
    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": user_message
                    }
                ]
            }
        ]
    }

    # 3. Invocação do Modelo no Bedrock
    try:
        response = bedrock_runtime.invoke_model(
            body=json.dumps(payload),
            modelId=model_id,
            contentType='application/json',
            accept='application/json'
        )

        # 4. Processamento da Resposta (específico para a Messages API)
        response_body_json = json.loads(response.get('body').read())
        # A resposta agora está dentro de uma lista 'content'
        model_response = response_body_json.get('content', [{}])[0].get('text', 'Não foi possível gerar uma resposta.')

        # 5. Retorno da Resposta de Sucesso
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'response': model_response})
        }

    except Exception as e:
        print(f"Erro ao invocar o modelo: {e}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Ocorreu um erro interno ao processar sua solicitação.'})
        }