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

output "public_subnets" {
  description = "A map of public subnets keyed by subnet CIDR block"
  value       = { for subnet in aws_subnet.public : subnet.cidr_block => subnet }
}

output "private_subnets" {
  description = "A map of private subnets keyed by subnet CIDR block"
  value       = { for subnet in aws_subnet.private : subnet.cidr_block => subnet }
}