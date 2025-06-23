variable "vpc_id" {
  description = "VPC ID for the EC2 Instance Connect Endpoint"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 Instance Connect Endpoint"
  type        = string
  default     = ""
}

variable "admin_public_ips" {
  description = "List of admin public IPs to allow EC2 Instance Connect Endpoint access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}