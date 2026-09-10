# ==============================================================================
# LAB 05: Observabilidade e Monitoramento de GenAI (X-Ray, Signals e Invocations)
# ==============================================================================
# Provisiona:
# 1. Anexo de políticas IAM para AWS X-Ray Daemon Write Access na Lambda
# 2. Anexo da política gerenciada do CloudWatch Application Signals
# 3. CloudWatch Log Group (/aws/bedrock/modelinvocations) para auditoria
# 4. IAM Role de Logging para o Bedrock assumir
# 5. Habilitação do Bedrock Model Invocation Logging (Text, Image, Embeddings)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Políticas IAM de Rastreamento (X-Ray e Application Signals na Lambda)
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count = var.enable_observability ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_app_signals" {
  count = var.enable_observability ? 1 : 0

  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaApplicationSignalsExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# 2. CloudWatch Log Group de Auditoria do Bedrock (/aws/bedrock/modelinvocations)
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "bedrock_invocations" {
  count = var.enable_observability ? 1 : 0

  name              = "/aws/bedrock/modelinvocations"
  retention_in_days = var.bedrock_logging_retention_in_days
}

# ------------------------------------------------------------------------------
# 3. IAM Role e Permissões para o Serviço Bedrock Gravar Logs
# ------------------------------------------------------------------------------

resource "aws_iam_role" "bedrock_logging" {
  count = var.enable_observability ? 1 : 0

  name = "${var.project_name}-bedrock-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_logging_policy" {
  count = var.enable_observability ? 1 : 0

  name = "BedrockLoggingPolicy"
  role = aws_iam_role.bedrock_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.bedrock_invocations[0].arn}:*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 4. Configuração Centralizada de Invocação de Modelos no Amazon Bedrock
# ------------------------------------------------------------------------------

resource "aws_bedrock_model_invocation_logging_configuration" "bedrock_logging_config" {
  count = var.enable_observability ? 1 : 0

  logging_config {
    text_data_delivery_enabled      = true
    image_data_delivery_enabled     = true
    embedding_data_delivery_enabled = true

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock_invocations[0].name
      role_arn       = aws_iam_role.bedrock_logging[0].arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.bedrock_invocations,
    aws_iam_role_policy.bedrock_logging_policy
  ]
}
