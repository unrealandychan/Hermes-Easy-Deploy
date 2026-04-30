# ──────────────────────────────────────────────────────────────────────────────
#  IAM Role + Instance Profile for Hermes Agent
#  Policies are conditionally attached based on wizard-selected permission profile
# ──────────────────────────────────────────────────────────────────────────────

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

# ── Always attached: SSM Session Manager (no open SSH port required) ─────────
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.hermes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── Optional: S3 read + write access ─────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "s3_full" {
  count      = var.enable_s3 ? 1 : 0
  role       = aws_iam_role.hermes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ── Optional: Billing read-only (Cost Explorer + Billing console) ─────────────
data "aws_iam_policy_document" "billing_read" {
  statement {
    sid    = "BillingReadOnly"
    effect = "Allow"
    actions = [
      "ce:Get*",
      "ce:Describe*",
      "ce:List*",
      "budgets:ViewBudget",
      "aws-portal:ViewBilling",
      "aws-portal:ViewUsage",
      "cur:DescribeReportDefinitions",
      "pricing:GetProducts",
      "pricing:DescribeServices",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_read" {
  count       = var.enable_billing ? 1 : 0
  name        = "hermes-billing-read"
  description = "Hermes Agent — billing and cost read-only access"
  policy      = data.aws_iam_policy_document.billing_read.json

  tags = {
    Project = "Hermes-Agent-Cloud"
  }
}

resource "aws_iam_role_policy_attachment" "billing_read" {
  count      = var.enable_billing ? 1 : 0
  role       = aws_iam_role.hermes.name
  policy_arn = aws_iam_policy.billing_read[0].arn
}

# ── Optional: RDS full access (create, modify, describe, delete RDS instances) ─
resource "aws_iam_role_policy_attachment" "rds_full" {
  count      = var.enable_rds ? 1 : 0
  role       = aws_iam_role.hermes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# ── Instance profile ─────────────────────────────────────────────────────────
resource "aws_iam_instance_profile" "hermes" {
  name = "hermes-agent-profile"
  role = aws_iam_role.hermes.name
}
