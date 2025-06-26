output "target_group_arns" {
  description = "Target group ARNs of the load balancer"
  value       = [for tg in aws_lb_target_group.this : tg.arn]
}