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
    Project = "Hermes-Agent-Cloud"
  }
}

# Attach SSM managed instance core so Session Manager shells work without an open SSH port
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.hermes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "hermes" {
  name = "hermes-agent-profile"
  role = aws_iam_role.hermes.name
}
