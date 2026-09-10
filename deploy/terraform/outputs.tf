# ==============================================================================
# Outputs da Infraestrutura (TechFin Bedrock Chat)
# ==============================================================================

output "api_gateway_url" {
  description = "URL base da API Gateway (HTTP API)"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_chat_endpoint" {
  description = "Endpoint completo de chat para configurar no chat.html ou ferramentas de teste"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/chat"
}

output "s3_website_url" {
  description = "URL pública de acesso ao Frontend Web (chat.html)"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}/chat.html"
}

output "frontend_bucket_name" {
  description = "Nome do Bucket S3 de hospedagem do Frontend"
  value       = aws_s3_bucket.frontend.id
}

output "rag_bucket_name" {
  description = "Nome do Bucket S3 de documentos RAG"
  value       = aws_s3_bucket.rag.id
}

output "lambda_function_name" {
  description = "Nome da função AWS Lambda criada"
  value       = aws_lambda_function.bedrock_chat.function_name
}

output "guardrail_id" {
  description = "[LAB 03] ID do AWS Bedrock Guardrail gerado"
  value       = var.enable_guardrails ? aws_bedrock_guardrail.techfin_guardrail[0].guardrail_id : "N/A (Desabilitado)"
}

output "guardrail_version" {
  description = "[LAB 03] Versão imutável do Guardrail para uso em produção"
  value       = var.enable_guardrails ? aws_bedrock_guardrail_version.techfin_guardrail_v1[0].version : "N/A (Desabilitado)"
}

output "cloudwatch_log_group_invocations" {
  description = "[LAB 05] Log Group do CloudWatch para auditoria de Prompts e Respostas"
  value       = var.enable_observability ? aws_cloudwatch_log_group.bedrock_invocations[0].name : "N/A (Desabilitado)"
}
