resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn         = aws_iam_role.this[0].arn
  log_destination      = aws_cloudwatch_log_group.this[0].arn
  log_destination_type = "cloud-watch-logs"

  traffic_type = "ALL"
  vpc_id       = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-vpc-flow-logs"
  })
}

resource "aws_iam_role" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name               = "${var.vpc_name}-vpc_flow_logs_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-vpc_flow_logs_role"
  })
}

resource "aws_iam_role_policy" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name   = "${var.vpc_name}-vpc_flow_logs_policy"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.allow_logs.json
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "vpc-flow-logs-${var.vpc_name}"
  kms_key_id        = aws_kms_alias.this[0].arn
  retention_in_days = var.flow_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-vpc-flow-logs"
  })

  depends_on = [aws_kms_key_policy.this]
}

resource "aws_kms_key" "this" {
  # checkov:skip=CKV2_AWS_64:False Positive. The KMS key policy is actually created via "aws_kms_key_policy" resource.

  count = var.enable_flow_logs ? 1 : 0

  description         = "KMS key for CloudWatch encryption"
  enable_key_rotation = true

  tags = merge(var.tags, {
    Name = "${aws_vpc.this.id}-flow-logs-cloudwatch-key"
  })
}

resource "aws_kms_alias" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name          = "alias/cloudwatch-${var.vpc_name}"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_kms_key_policy" "this" {
  count = var.enable_flow_logs ? 1 : 0

  key_id = aws_kms_key.this[0].id
  policy = jsonencode({
    Id = "cloudwatch-key-policy-${var.vpc_name}"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = aws_kms_key.this[0].arn
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${local.iam_username}"
        },
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = aws_kms_key.this[0].arn
      },
      {
        Sid    = "Allow the key to be used to encrypt CloudWatch logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = aws_kms_key.this[0].arn
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:vpc-flow-logs-${var.vpc_name}"
          }
        }
      }
    ]
    Version = "2012-10-17"
  })
}