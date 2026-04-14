data "aws_iam_policy_document" "hermes_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "hermes" {
  name               = "hermes-agent-role"
  assume_role_policy = data.aws_iam_policy_document.hermes_assume_role.json

  tags = {
    Project = "hermes-deploy"
  }
}

# Attach SSM managed instance core so Session Manager shells work without an open SSH port
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.hermes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Inline policy: allow the instance to read its own secrets from SSM
data "aws_iam_policy_document" "ssm_read_hermes" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter/hermes/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "hermes-ssm-read"
  role   = aws_iam_role.hermes.id
  policy = data.aws_iam_policy_document.ssm_read_hermes.json
}

resource "aws_iam_instance_profile" "hermes" {
  name = "hermes-agent-profile"
  role = aws_iam_role.hermes.name
}
