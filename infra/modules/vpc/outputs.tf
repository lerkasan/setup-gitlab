output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "subnets" {
  description = "A map of subnets keyed by subnet CIDR block"
  value = merge(
    { for subnet in aws_subnet.public : subnet.cidr_block => subnet },
    { for subnet in aws_subnet.private : subnet.cidr_block => subnet }
  )
}