# ---------------- VPC parameters ----------------

variable "vpc_name" {
  description = "VPC name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vpc_name))
    error_message = "VPC name must have lowercase letters, numbers, and hyphens only)."
  }
}

variable "cidr_block" {
  description = "A CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 32))
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

  validation {
    condition = alltrue([
      for subnet in var.public_subnets : can(cidrhost(subnet, 32))
    ])
    error_message = "Public subnets must have valid IPv4 CIDRs."
  }
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.0.220.0/24", "10.0.230.0/24", "10.0.240.0/24", "10.0.250.0/24"]

  validation {
    condition = alltrue([
      for subnet in var.private_subnets : can(cidrhost(subnet, 32))
    ])
    error_message = "Private subnets must nave valid IPv4 CIDRs."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "The number of days to retain flow logs in CloudWatch log group. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 365

  validation {
    condition     = var.flow_logs_retention_days >= 0
    error_message = "Flow logs retention days must be a non-negative integer."
  }
}

variable "tags" {
  description = "Tags for a bucket"
  type        = map(string)
  default     = {}
}