locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  iam_user_arn_parts = split("/", data.aws_caller_identity.current.arn)
  iam_username       = element(local.iam_user_arn_parts, length(local.iam_user_arn_parts) - 1)
}