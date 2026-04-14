variable "location" {
  description = "Azure region to deploy into"
  type        = string
  default     = "eastasia"
}

variable "vm_size" {
  description = "Azure VM size (minimum Standard_D2s_v3 for Hermes 5 GB RAM requirement)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key content (the full key string, not a file path)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH (port 22) and gateway (port 8080)"
  type        = string
}

variable "key_vault_name" {
  description = "Azure Key Vault name — must be globally unique, 5–24 alphanumeric/hyphen chars"
  type        = string
}

variable "openrouter_api_key" {
  description = "OpenRouter API key — stored as Key Vault secret 'openrouter-api-key'"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key — stored as Key Vault secret 'openai-api-key'"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic (Claude) API key — stored as Key Vault secret 'anthropic-api-key'"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Google Gemini API key — stored as Key Vault secret 'gemini-api-key'"
  type        = string
  sensitive   = true
  default     = ""
}
