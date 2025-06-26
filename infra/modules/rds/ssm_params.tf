resource "aws_ssm_parameter" "database_host" {
  name        = join("_", [var.rds_name, "db_host"])
  description = "RDS database host"
  type        = "SecureString"
  key_id      = aws_kms_key.sm_secret_encrypt_key.id
  value       = aws_db_instance.primary.address

  tags = merge(var.tags, {
    Name = "${var.rds_name}-rds-host-param"
  })
}

resource "aws_ssm_parameter" "database_master_secret_arn" {
  name        = join("_", [var.rds_name, "db_master_secret_arn"])
  description = "ARN of the master_user_secret of the RDS database"
  type        = "SecureString"
  key_id      = aws_kms_key.sm_secret_encrypt_key.id
  value       = aws_db_instance.primary.master_user_secret[0].secret_arn

  tags = merge(var.tags, {
    Name = "${var.rds_name}-rds-master_secret_arn-param"
  })
}

resource "aws_iam_policy" "allow_read_only_access_to_ssm_paramers_and_secrets" {
  name        = "AllowReadOnlyAccessToSSMParamersAndSecretsCreatedByRDS"
  description = "Allow EC2 instance to read SSM parameters and Secrets Manager secrets created by RDS module"
  policy      = data.aws_iam_policy_document.allow_read_only_access_to_ssm_paramers_and_secrets.json

  tags = merge(var.tags, {
    Name = "${var.rds_name}-rds-policy-read-ssm-params-secrets"
  })
}