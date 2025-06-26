data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_policy_document" "allow_read_only_access_to_ssm_paramers_and_secrets" {
  statement {
    sid     = "SystemsManagerParameterReadOnly"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      aws_ssm_parameter.database_host.arn,
      aws_ssm_parameter.database_master_secret_arn.arn
    ]
  }

  statement {
    sid       = "SecretsManagerSecretReadOnly"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.primary.master_user_secret[0].secret_arn]
  }

  statement {
    sid       = "KMSDecryptKeyForSecretsManagerSecretAndSystemManagerParameter"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.sm_secret_encrypt_key.arn]
  }
}