import json
import os 
import boto3
from botocore.exceptions import ClientError

# --- Boas Práticas: Inicialize o cliente fora do handler ---
bedrock_runtime = boto3.client(service_name='bedrock-runtime')

# --- Boas Práticas: Centralize configurações usando variáveis de ambiente ---
MODEL_ID = os.environ.get('MODEL_ID', 'anthropic.claude-3-haiku-20240307-v1:0')
GUARDRAIL_ID = os.environ.get('GUARDRAIL_ID', 'exlca7bwua71')
GUARDRAIL_VERSION = os.environ.get('GUARDRAIL_VERSION', '4')
ALLOWED_ORIGIN = os.environ.get('ALLOWED_ORIGIN', '*')

# --- Boas Práticas (DRY): Defina os headers CORS em um único lugar ---
CORS_HEADERS = {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "OPTIONS,POST"
}

def lambda_handler(event, context):
    """
    Invoca um modelo no Bedrock, lida com CORS e controla o uso do Guardrail via parâmetro de API.
    """
    
    http_method = event.get('requestContext', {}).get('http', {}).get('method', '')

    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps('CORS Preflight Check Successful')
        }

    elif http_method == 'POST':
        try:
            body = json.loads(event.get('body', '{}'))
            user_message = body.get('message', '')
            
            # --- AJUSTE PRINCIPAL AQUI ---
            # Lendo o parâmetro 'useGuardrail' (camelCase) enviado pelo JavaScript.
            # Se não for encontrado, o padrão é True (ligado).
            use_guardrail = body.get('useGuardrail', True)
            
            if not user_message:
                return {
                    'statusCode': 400,
                    'headers': CORS_HEADERS,
                    'body': json.dumps({'error': 'A mensagem não pode estar vazia.'})
                }
            
            payload = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1024,
                "messages": [{"role": "user", "content": [{"type": "text", "text": user_message}]}]
            }

            invoke_args = {
                'body': json.dumps(payload),
                'modelId': MODEL_ID,
                'contentType': 'application/json',
                'accept': 'application/json'
            }
            
            # Lógica condicional para adicionar o Guardrail
            if use_guardrail and GUARDRAIL_ID and GUARDRAIL_VERSION:
                print(f"INFO: Guardrail HABILITADO para a requisição.")
                invoke_args['guardrailIdentifier'] = GUARDRAIL_ID
                invoke_args['guardrailVersion'] = GUARDRAIL_VERSION
            else:
                print(f"INFO: Guardrail DESABILITADO para a requisição.")

            response = bedrock_runtime.invoke_model(**invoke_args)
            response_body_json = json.loads(response.get('body').read())
            
            # Lógica do Guardrail (continua útil para saber se a resposta foi alterada)
            guardrail_assessment = response_body_json.get('amazon-bedrock-guardrailAssessment', {})
            if guardrail_assessment.get('topicPolicy', {}).get('action') == 'BLOCKED':
                model_response = "Desculpe, não posso discutir este tópico pois ele viola nossas políticas de segurança (Resposta do Guardrail)."
            else:
                model_response = response_body_json.get('content', [{}])[0].get('text', 'Não foi possível gerar uma resposta de fallback.')

            return {
                'statusCode': 200,
                'headers': CORS_HEADERS,
                'body': json.dumps({'response': model_response})
            }
        
        except (ClientError, json.JSONDecodeError, Exception) as e:
            print(f"ERRO: Erro ao processar a requisição POST: {e}")
            return {
                'statusCode': 500,
                'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Ocorreu um erro interno ao processar sua solicitação.'})
            }

    else:
        return {
            'statusCode': 405,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': f"Método HTTP '{http_method}' não é suportado."})
        }
