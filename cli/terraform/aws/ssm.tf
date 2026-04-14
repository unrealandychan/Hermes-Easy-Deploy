# Each parameter is only created when the corresponding key was actually provided.
# Values are SecureString (KMS-encrypted at rest). The instance fetches them via
# its IAM role at boot — the keys never appear in user_data or the console.

resource "aws_ssm_parameter" "openrouter_api_key" {
  count = var.openrouter_api_key != "" ? 1 : 0

  name        = "/hermes/openrouter_api_key"
  type        = "SecureString"
  value       = var.openrouter_api_key
  description = "Hermes Agent — OpenRouter API key"
  overwrite   = true

  tags = {
    Project = "hermes-deploy"
  }
}

resource "aws_ssm_parameter" "openai_api_key" {
  count = var.openai_api_key != "" ? 1 : 0

  name        = "/hermes/openai_api_key"
  type        = "SecureString"
  value       = var.openai_api_key
  description = "Hermes Agent — OpenAI API key"
  overwrite   = true

  tags = {
    Project = "hermes-deploy"
  }
}

resource "aws_ssm_parameter" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0

  name        = "/hermes/anthropic_api_key"
  type        = "SecureString"
  value       = var.anthropic_api_key
  description = "Hermes Agent — Anthropic (Claude) API key"
  overwrite   = true

  tags = {
    Project = "hermes-deploy"
  }
}

resource "aws_ssm_parameter" "gemini_api_key" {
  count = var.gemini_api_key != "" ? 1 : 0

  name        = "/hermes/gemini_api_key"
  type        = "SecureString"
  value       = var.gemini_api_key
  description = "Hermes Agent — Google Gemini API key"
  overwrite   = true

  tags = {
    Project = "hermes-deploy"
  }
}
