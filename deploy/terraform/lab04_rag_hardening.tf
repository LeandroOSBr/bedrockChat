# ==============================================================================
# LAB 04: RAG, Datasets Corporativos e Proteção contra Data Poisoning
# ==============================================================================
# Provisiona:
# 1. Bucket S3 privado para armazenamento da Base de Conhecimento RAG
# 2. Bloqueio total de acesso público no bucket de dados (Least Privilege)
# 3. Upload automatizado do documento corporativo legítimo (politica_reembolso.txt)
# 4. Upload do documento envenenado para testes de injeção indireta
# 
# Nota: A regra de Contextual Grounding (Grounding: 0.8 / Relevance: 0.7) é
# aplicada no Guardrail em lab03_bedrock_guardrails.tf quando
# 'var.enable_contextual_grounding = true'.
# ==============================================================================

resource "aws_s3_bucket" "rag" {
  bucket        = "${var.project_name}-rag-${random_string.suffix.result}"
  force_destroy = true
}

# Governança S3: Garantir que a base de conhecimento RAG seja estritamente privada
resource "aws_s3_bucket_public_access_block" "rag" {
  bucket = aws_s3_bucket.rag.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload do documento legítimo como documento ativo em rag-docs/politica_reembolso.txt
resource "aws_s3_object" "rag_doc_legitimo" {
  bucket = aws_s3_bucket.rag.id
  key    = "rag-docs/politica_reembolso.txt"
  source = "${path.module}/../../datasets_poisoning/politica_reembolso_legitima.txt"
  etag   = filemd5("${path.module}/../../datasets_poisoning/politica_reembolso_legitima.txt")
}

# Upload do documento com payload envenenado para simulações de ataque
resource "aws_s3_object" "rag_doc_envenenado" {
  bucket = aws_s3_bucket.rag.id
  key    = "rag-docs/politica_reembolso_envenenada.txt"
  source = "${path.module}/../../datasets_poisoning/politica_reembolso_envenenada.txt"
  etag   = filemd5("${path.module}/../../datasets_poisoning/politica_reembolso_envenenada.txt")
}
