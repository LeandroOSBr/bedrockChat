# ==============================================================================
# LAB 03: Bedrock Guardrails via Código (Policy as Code / DevSecOps)
# ==============================================================================
# Provisiona:
# 1. AWS Bedrock Guardrail corporativo (TechFin-Security-Guardrail)
# 2. Content Filters (Prompt Attack HIGH, Hate, Insults, Sexual, Violence, Misconduct)
# 3. Denied Topics Policy (Hacking & Exploits, High Risk Financial Advice)
# 4. Sensitive Information Policy (PIIs nativas + Regex customizado para CPF)
# 5. Word Policy (Profanidade + Bloqueio de Chaves Confidenciais Internas)
# 6. Contextual Grounding Policy (Integrado opcionalmente para o LAB 04)
# 7. Bedrock Guardrail Versioning para liberação controlada em produção
# ==============================================================================

resource "aws_bedrock_guardrail" "techfin_guardrail" {
  count = var.enable_guardrails ? 1 : 0

  name        = "${var.project_name}-guardrail"
  description = "Guardrail corporativo TechFin Cloud: Defesa contra Prompt Injections, vazamento de PII e hacking"

  # Mensagens corporativas de bloqueio (Input e Output)
  blocked_input_messaging   = "[🛡️ TechFin Security]: Sua solicitação foi bloqueada pois viola nossas diretrizes de segurança e compliance corporativo."
  blocked_outputs_messaging = "[🛡️ TechFin Security]: A resposta gerada foi retida por conter conteúdo restrito pelas políticas de segurança."

  # ----------------------------------------------------------------------------
  # 1. Content Policy (Filtros de Conteúdo e Jailbreak / Prompt Attack)
  # ----------------------------------------------------------------------------
  content_policy_config {
    # Detecção de Prompt Injection e Jailbreak (LLM01)
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE" # Padrão obrigatório da AWS para Prompt Attack
    }

    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
  }

  # ----------------------------------------------------------------------------
  # 2. Topic Policy (Tópicos Proibidos no Chat Corporativo)
  # ----------------------------------------------------------------------------
  topic_policy_config {
    topics_config {
      name       = "Hacking_and_Exploits"
      definition = "Discussões sobre criação de malwares, engenharia reversa, invasão de redes Wi-Fi, exploração de vulnerabilidades, ataques de negação de serviço (DDoS) ou quebra de senhas."
      examples = [
        "Como criar um exploit em Python",
        "Como quebrar senhas usando brute-force",
        "Instruções para invasão de redes corporativas",
        "Explique como realizar um ataque de negação de serviço DDoS"
      ]
      type = "DENY"
    }

    topics_config {
      name       = "High_Risk_Financial_Advice"
      definition = "Orientações sobre esquemas de enriquecimento rápido, apostas, pirâmides financeiras ou investimentos predatórios de altíssimo risco."
      examples = [
        "Quero aplicar todo meu dinheiro em pirâmide",
        "Como dobrar meu salário em apostas de alto risco em 24 horas",
        "Recomende esquemas ilegais de investimentos"
      ]
      type = "DENY"
    }
  }

  # ----------------------------------------------------------------------------
  # 3. Sensitive Information Policy (PII e Mascaramento LGPD)
  # ----------------------------------------------------------------------------
  sensitive_information_policy_config {
    # Anonimização de Cartão de Crédito
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "ANONYMIZE"
    }

    # Anonimização de E-mail
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }

    # Bloqueio estrito de Credenciais de Nuvem AWS
    pii_entities_config {
      type   = "AWS_ACCESS_KEY"
      action = "BLOCK"
    }

    pii_entities_config {
      type   = "AWS_SECRET_KEY"
      action = "BLOCK"
    }

    # Regex Customizado para CPF Brasileiro com Anonimização
    regexes_config {
      name        = "Brazilian_CPF"
      description = "Identificação e anonimização de Cadastro de Pessoa Física (CPF)"
      pattern     = "\\b\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}\\b"
      action      = "ANONYMIZE"
    }
  }

  # ----------------------------------------------------------------------------
  # 4. Word Policy (Palavras e Chaves Confidenciais Proibidas)
  # ----------------------------------------------------------------------------
  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }

    words_config {
      text = "SEC-PROJECT-PHOENIX-2026"
    }

    words_config {
      text = "TK_INTERNAL_DEV_987654321"
    }
  }

  # ----------------------------------------------------------------------------
  # 5. Contextual Grounding Policy (Integrado dinamicamente para o LAB 04)
  # ----------------------------------------------------------------------------
  dynamic "contextual_grounding_policy_config" {
    for_each = var.enable_contextual_grounding ? [1] : []
    content {
      filters_config {
        type      = "GROUNDING"
        threshold = 0.8
      }
      filters_config {
        type      = "RELEVANCE"
        threshold = 0.7
      }
    }
  }
}

# ------------------------------------------------------------------------------
# 6. Publicação de Versão Imutável do Guardrail (Produção)
# ------------------------------------------------------------------------------

resource "aws_bedrock_guardrail_version" "techfin_guardrail_v1" {
  count = var.enable_guardrails ? 1 : 0

  guardrail_arn = aws_bedrock_guardrail.techfin_guardrail[0].guardrail_arn
  description   = "Versão 1.0 - Provisionada via Terraform (DevSecOps Policy as Code)"

  depends_on = [aws_bedrock_guardrail.techfin_guardrail]
}
