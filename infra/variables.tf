variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpcs" {
  type = list(object({
    name                     = string
    region                   = optional(string)
    cidr_block               = string
    public_subnets           = optional(list(string), [])
    private_subnets          = optional(list(string), [])
    enable_dns_hostnames     = optional(bool, true)
    enable_dns_support       = optional(bool, true)
    enable_flow_logs         = optional(bool, true)
    flow_logs_retention_days = optional(number, 365)
    admin_public_ips         = optional(list(string), [])
    tags                     = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for vpc in var.vpcs : can(regex("^[a-z0-9-]+$", vpc.name))
    ])
    error_message = "VPC name must have lowercase letters, numbers, and hyphens only)."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : can(cidrhost(vpc.cidr_block, 32))
    ])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : alltrue([
        for subnet in vpc.public_subnets : length(subnet) > 0 ? can(cidrhost(subnet, 32)) : true
      ])
    ])
    error_message = "Public subnets must have valid IPv4 CIDRs."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : alltrue([
        for subnet in vpc.private_subnets : length(subnet) > 0 ? can(cidrhost(subnet, 32)) : true
      ])
    ])
    error_message = "Private subnets must have valid IPv4 CIDRs."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : vpc.enable_flow_logs ? (vpc.flow_logs_retention_days >= 0) : true
    ])
    error_message = "Flow logs retention days must be 0 or greater if flow logs are enabled."
  }

  default = []
}

variable "ec2_appservers" {
  type = list(object({
    ec2_instance_type                    = string
    vpc_cidr                             = string
    subnet_cidr                          = string
    associate_public_ip_address          = optional(bool, false)
    bastion_name                         = optional(string, "")
    volume_type                          = optional(string, "gp3")
    volume_size                          = optional(number, 10)
    delete_on_termination                = optional(bool, true)
    private_ssh_key_name                 = string
    admin_public_ssh_key_names           = optional(list(string), [])
    enable_bastion_access                = optional(bool, false)
    bastion_security_group_id            = optional(string, "")
    enable_ec2_instance_connect_endpoint = optional(bool, false)
    os                                   = string
    os_product                           = optional(string, "server")
    os_architecture                      = optional(string, "amd64")
    os_version                           = string
    os_releases                          = map(string)
    ami_virtualization                   = optional(string, "hvm")
    ami_architectures                    = optional(map(string), { "amd64" = "x86_64" })
    ami_owner_ids                        = optional(map(string), { "ubuntu" = "099720109477" }) # Canonical for Ubuntu AMIs
    tags                                 = map(string)
  }))

  default = []
}

variable "ec2_bastions" {
  type = list(object({
    ec2_instance_type                    = string
    vpc_cidr                             = string
    subnet_cidr                          = string
    associate_public_ip_address          = optional(bool, false)
    volume_type                          = optional(string, "gp3")
    volume_size                          = optional(number, 10)
    delete_on_termination                = optional(bool, true)
    private_ssh_key_name                 = string
    admin_public_ssh_key_names           = optional(list(string), [])
    enable_ec2_instance_connect_endpoint = optional(bool, false)
    os                                   = string
    os_product                           = optional(string, "server")
    os_architecture                      = optional(string, "amd64")
    os_version                           = string
    os_releases                          = map(string)
    ami_virtualization                   = optional(string, "hvm")
    ami_architectures                    = optional(map(string), { "amd64" = "x86_64" })
    ami_owner_ids                        = optional(map(string), { "ubuntu" = "099720109477" }) # Canonical for Ubuntu AMIs
    tags                                 = map(string)
  }))

  default = []
}

variable "ec2_instance_connect_endpoints" {
  type = list(object({
    vpc_cidr    = string
    subnet_cidr = string
    tags        = map(string)
  }))

  default = []
}

variable "admin_public_ips" {
  description = "List of admin public IPs to allow SSH access"
  type        = list(string)
  default     = []
}
