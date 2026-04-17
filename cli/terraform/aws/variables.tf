variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (minimum: t3.large for Hermes 5 GB RAM requirement)"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair in the selected region"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to reach port 22 (SSH) and port 8080 (gateway)"
  type        = string
}
