output "target_groups" {
  description = "Target group ARNs of the load balancer"
  value       = { for tg in aws_lb_target_group.this : tg.name => tg }
}

output "security_group_id" {
  description = "Security group ID of the load balancer"
  value       = aws_security_group.this.id
}

output "member_of_target_groups" {
  description = "List of target group ARNs the load balancer is attached to"
  value       = var.member_of_target_groups
}

output "arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}