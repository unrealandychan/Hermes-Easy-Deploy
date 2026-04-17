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
