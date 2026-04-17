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
