variable "project_id" {
  description = "GCP project ID to deploy into"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-east2"
}

variable "zone" {
  description = "GCP zone within the region"
  type        = string
  default     = "asia-east2-a"
}

variable "machine_type" {
  description = "GCP machine type (minimum e2-standard-2 for Hermes 5 GB RAM requirement)"
  type        = string
  default     = "e2-standard-2"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH (port 22) and gateway (port 8080)"
  type        = string
}

variable "openrouter_api_key" {
  description = "OpenRouter API key — stored in Secret Manager as hermes-openrouter-api-key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key — stored in Secret Manager as hermes-openai-api-key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic (Claude) API key — stored in Secret Manager as hermes-anthropic-api-key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Google Gemini API key — stored in Secret Manager as hermes-gemini-api-key"
  type        = string
  sensitive   = true
  default     = ""
}
