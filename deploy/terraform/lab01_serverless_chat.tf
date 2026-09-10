# ==============================================================================
# LAB 01: Infraestrutura Serverless Base & Chat Desprotegido
# ==============================================================================
# Provisiona:
# 1. Bucket S3 para hospedagem do Frontend Web estático (chat.html)
# 2. Empacotamento automático da função Lambda (bedrockChatFunction.py)
# 3. IAM Execution Role para a Lambda com permissões do Bedrock e S3
# 4. Função AWS Lambda (Python 3.12)
# 5. Amazon API Gateway (HTTP API v2) com suporte a CORS e rota $default
# ==============================================================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# 1. S3 Bucket para Hospedagem de Site Estático (Frontend chat.html)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "chat.html"
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# Injeção dinâmica dos endpoints e Guardrails no chat.html antes de subir para o S3
locals {
  chat_html_injected = replace(
    replace(
      file("${path.module}/../../chat.html"),
      "__API_ENDPOINT__",
      "${aws_apigatewayv2_api.http_api.api_endpoint}/chat"
    ),
    "__GUARDRAIL_ID__",
    var.enable_guardrails ? aws_bedrock_guardrail.techfin_guardrail[0].guardrail_id : ""
  )
}

# Upload do arquivo chat.html diretamente para o S3 com injeção automática de parâmetros
resource "aws_s3_object" "chat_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "chat.html"
  content      = local.chat_html_injected
  content_type = "text/html"
  etag         = md5(local.chat_html_injected)
}

# ------------------------------------------------------------------------------
# 2. Empacotamento do Código Python da Lambda
# ------------------------------------------------------------------------------

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../bedrockChatFunction.py"
  output_path = "${path.module}/bedrockChatFunction.zip"
}

# ------------------------------------------------------------------------------
# 3. IAM Execution Role para a Função Lambda
# ------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Permissões de logging básico no CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permissões do Amazon Bedrock e Leitura no S3
resource "aws_iam_policy" "lambda_bedrock_s3" {
  name        = "${var.project_name}-bedrock-s3-policy"
  description = "Permite a Lambda invocar modelos Bedrock, aplicar Guardrails e ler documentos RAG no S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInferenceAndGuardrails"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:Converse",
          "bedrock:ConverseStream",
          "bedrock:ApplyGuardrail",
          "bedrock:GetGuardrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3RAGBucketRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.rag.arn,
          "${aws_s3_bucket.rag.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_bedrock_s3.arn
}

# ------------------------------------------------------------------------------
# 4. Função AWS Lambda (bedrockChatFunction)
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "bedrock_chat" {
  function_name    = "${var.project_name}-function"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "bedrockChatFunction.lambda_handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  tracing_config {
    mode = var.enable_observability ? "Active" : "PassThrough"
  }

  environment {
    variables = {
      MODEL_ID          = var.default_model_id
      GUARDRAIL_ID      = var.enable_guardrails ? aws_bedrock_guardrail.techfin_guardrail[0].guardrail_id : ""
      GUARDRAIL_VERSION = var.enable_guardrails ? aws_bedrock_guardrail_version.techfin_guardrail_v1[0].version : "DRAFT"
      RAG_BUCKET        = aws_s3_bucket.rag.id
      RAG_KEY           = "rag-docs/politica_reembolso.txt"
      ALLOWED_ORIGIN    = "*"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_logs,
    aws_iam_role_policy_attachment.lambda_bedrock_s3_attach
  ]
}

# ------------------------------------------------------------------------------
# 5. Amazon API Gateway (HTTP API v2)
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS", "GET"]
    allow_headers = [
      "content-type",
      "authorization",
      "x-amz-date",
      "x-api-key",
      "x-amz-security-token"
    ]
    max_age = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.bedrock_chat.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "chat_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permissão para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock_chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
