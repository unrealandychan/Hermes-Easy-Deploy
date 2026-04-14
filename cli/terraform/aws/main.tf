terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Latest Ubuntu 24.04 LTS AMI (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "hermes" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.hermes.id]
  iam_instance_profile   = aws_iam_instance_profile.hermes.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  # bootstrap.sh is a Terraform templatefile — cloud values injected at plan time.
  # The instance pulls API keys from SSM at boot via its IAM role; no secrets in user_data.
  user_data = base64encode(templatefile("${path.module}/bootstrap.sh", {
    HERMES_CLOUD  = "aws"
    AWS_REGION    = var.aws_region
    SSM_PREFIX    = "/hermes"
    AZURE_KV_NAME = ""
    GCP_PROJECT   = ""
  }))

  # Prevent user_data churn from forcing instance replacement on re-plan
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name    = "hermes-agent"
    Project = "hermes-deploy"
  }
}
