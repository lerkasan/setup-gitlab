output "target_groups" {
  description = "Target group ARNs of the load balancer"
  value       = { for tg in aws_lb_target_group.this : tg.name => tg }
}

output "security_group_id" {
  description = "Security group ID of the load balancer"
  value       = aws_security_group.this.id
}