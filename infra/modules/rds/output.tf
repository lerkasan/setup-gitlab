output "master_user_secret_arn" {
  value       = aws_db_instance.primary.master_user_secret[0].secret_arn
  description = "ARN of the master user secret for the RDS instance"
}

output "policy_arn_for_access_to_ssm_params_and_secrets" {
  value       = aws_iam_policy.allow_read_only_access_to_ssm_paramers_and_secrets.arn
  description = "ARN of the IAM policy that allows read-only access to SSM parameters and Secrets Manager secrets created by the RDS module"
}

output "host" {
  value       = aws_db_instance.primary.address
  description = "Hostname of the RDS instance"
}

output "port" {
  value       = aws_db_instance.primary.port
  description = "Port of the RDS instance"
}

output "endpoint" {
  value       = "${aws_db_instance.primary.address}:${aws_db_instance.primary.port}"
  description = "Endpoint of the RDS instance"
}
