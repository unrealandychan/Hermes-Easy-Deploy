resource "aws_security_group" "hermes" {
  name        = "hermes-sg"
  description = "Hermes Agent - allow SSH and gateway only from deployer IP"

  ingress {
    description = "SSH from deployer IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Hermes gateway from deployer IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound (LLM API calls, package installs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "hermes-sg"
    Project = "Hermes-Agent-Cloud"
  }
}
