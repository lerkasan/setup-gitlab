resource "aws_kms_key" "this" {
  # checkov:skip=CKV2_AWS_64:False Positive. The KMS key policy is actually created via "aws_kms_key_policy" resource.
  count = var.enable_encryption && !var.bucket_key_enabled ? 1 : 0

  description         = "KMS key for S3 encryption"
  enable_key_rotation = true

  tags = merge(var.tags, {
    Name = "${var.bucket_name}-bucket-encrypt-key"
  })
}

resource "aws_kms_alias" "this" {
  count = var.enable_encryption && !var.bucket_key_enabled ? 1 : 0

  name          = "alias/${var.bucket_name}-bucket-encrypt-key"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    # checkov:skip=CKV_AWS_145: We might need to use bucket key for encryption of the bucket for web access logs when using Application Load Balancer.
    # Application Load Balancer supports writing access logs into encrypted bucket only if a bucket key was used to encrypt the bucket. 
    # However, Network Load Balancer supports writing access logs into encrypted bucket only if a KMS key was used to encrypt the bucket.
    bucket_key_enabled = var.bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.bucket_key_enabled ? "AES256" : "aws:kms"
      kms_master_key_id = var.bucket_key_enabled ? null : aws_kms_key.this[0].arn
    }
  }
}

resource "aws_kms_key_policy" "this" {
  count = var.enable_encryption && !var.bucket_key_enabled ? 1 : 0

  key_id = aws_kms_key.this[0].id
  policy = jsonencode({
    Id = "${var.bucket_name}-encrypt-key-policy"
    Statement = [
      {
        Sid       = "Enable IAM Permissions for Root User"
        Effect    = "Allow"
        Action    = "kms:*"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Resource  = aws_kms_key.this[0].arn
      },
      {
        Sid    = "Allow Network Load Balancer to write access logs to encrypted S3 bucket"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Resource  = aws_kms_key.this[0].arn
      }
    ]
    Version = "2012-10-17"
  })
}
