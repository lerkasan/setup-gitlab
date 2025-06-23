output "security_group_id" {
  description = "Security group ID of the EC2 Instance Connect Endpoint"
  value       = aws_security_group.this.id
}