resource "aws_kms_key" "database_encrypt_key" {
  # checkov:skip=CKV2_AWS_64
  description             = "A key to encrypt database"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.rds_name}-rds-encrypt-key"
  })
}

resource "aws_kms_key" "sm_secret_encrypt_key" {
  description             = "A key to encrypt secrets in Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.rds_name}-sm_secret_encrypt_key"
  })
}

resource "aws_kms_key_policy" "sm_secret_encrypt_key_policy" {
  key_id = aws_kms_key.sm_secret_encrypt_key.id
  policy = jsonencode({
    Id = "${var.rds_name}-sm-secret-encrypt-key-policy"
    Statement = [
      {
        Sid       = "Enable IAM Permissions for Root User"
        Effect    = "Allow"
        Action    = ["kms:*"]
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Resource  = aws_kms_key.sm_secret_encrypt_key.arn
      },
      {
        Sid    = "Allow Network Load Balancer to write access logs to encrypted S3 bucket"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy"
        ]
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${local.iam_username}" }
        Resource  = aws_kms_key.sm_secret_encrypt_key.arn
      }
    ]
    Version = "2012-10-17"
  })
}
