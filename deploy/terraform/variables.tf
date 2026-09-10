variable "aws_region" {
  type        = string
  description = "Região da AWS para deploy dos recursos"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Prefixo padrão para nomeação de recursos"
  default     = "techfin-bedrock-chat"
}

variable "environment" {
  type        = string
  description = "Ambiente de execução (dev, homolog, prod)"
  default     = "dev"
}

variable "default_model_id" {
  type        = string
  description = "ID do modelo Bedrock padrão utilizado na função Lambda"
  default     = "meta.llama3-8b-instruct-v1:0"
}

variable "enable_guardrails" {
  type        = bool
  description = "[LAB 03] Se true, provisiona o AWS Bedrock Guardrail e injeta o ID na função Lambda"
  default     = true
}

variable "enable_contextual_grounding" {
  type        = bool
  description = "[LAB 04] Se true, ativa filtros de Contextual Grounding (Grounding e Relevance) no Guardrail"
  default     = true
}

variable "enable_observability" {
  type        = bool
  description = "[LAB 05] Se true, habilita AWS X-Ray Active Tracing, Application Signals e Bedrock Model Invocation Logging"
  default     = true
}

variable "lambda_timeout" {
  type        = number
  description = "Timeout da função Lambda em segundos (necessário >= 60s para inferências de LLM)"
  default     = 90
}

variable "lambda_memory_size" {
  type        = number
  description = "Memória alocada para a função Lambda em MB"
  default     = 256
}

variable "bedrock_logging_retention_in_days" {
  type        = number
  description = "Tempo de retenção em dias para o CloudWatch Log Group do Bedrock Model Invocation Logging"
  default     = 7
}
