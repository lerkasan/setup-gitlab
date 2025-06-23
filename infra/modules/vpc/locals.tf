locals {
  iam_user_arn_parts = split("/", data.aws_caller_identity.current.arn)
  iam_username       = element(local.iam_user_arn_parts, length(local.iam_user_arn_parts) - 1)
}