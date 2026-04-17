# ─── API Key Variables ───────────────────────────────────────────────────────
variable "openrouter_api_key" {
  description = "OpenRouter API key — stored as a SecureString in SSM Parameter Store"
  type        = string
  default     = ""
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key — stored as a SecureString in SSM Parameter Store"
  type        = string
  default     = ""
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "Anthropic (Claude) API key — stored as a SecureString in SSM Parameter Store"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key — stored as a SecureString in SSM Parameter Store"
  type        = string
  default     = ""
  sensitive   = true
}

# ─── SSM Parameter Store ─────────────────────────────────────────────────────
resource "aws_ssm_parameter" "openrouter_api_key" {
  count = var.openrouter_api_key != "" ? 1 : 0
  name  = "/hermes/OPENROUTER_API_KEY"
  type  = "SecureString"
  value = var.openrouter_api_key
  tags  = { Project = "hermes" }
}

resource "aws_ssm_parameter" "openai_api_key" {
  count = var.openai_api_key != "" ? 1 : 0
  name  = "/hermes/OPENAI_API_KEY"
  type  = "SecureString"
  value = var.openai_api_key
  tags  = { Project = "hermes" }
}

resource "aws_ssm_parameter" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0
  name  = "/hermes/ANTHROPIC_API_KEY"
  type  = "SecureString"
  value = var.anthropic_api_key
  tags  = { Project = "hermes" }
}

resource "aws_ssm_parameter" "gemini_api_key" {
  count = var.gemini_api_key != "" ? 1 : 0
  name  = "/hermes/GEMINI_API_KEY"
  type  = "SecureString"
  value = var.gemini_api_key
  tags  = { Project = "hermes" }
}
