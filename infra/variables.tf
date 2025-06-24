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

    iam_policy_statements = optional(set(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      condition = optional(map(string))
      # principals  = optional(map(string))
    })))
    tags = map(string)
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

variable "load_balancers" {
  type = list(object({
    # lb_sg_id                        = string
    lb_name                    = string
    lb_internal                = optional(bool, false)
    lb_type                    = optional(string, "application")
    vpc_cidr                   = string
    public_subnets             = list(string)
    domain_name                = string
    lb_access_logs_bucket_name = optional(string, null)
    waf_enabled                = optional(bool, false)

    target_groups = optional(list(object({
      name                             = string
      port                             = number
      protocol                         = string
      preserve_client_ip               = optional(bool, null)
      deregistration_delay             = optional(number, 300)
      health_check_healthy_threshold   = optional(number, 5)
      health_check_unhealthy_threshold = optional(number, 3)
      health_check_interval            = optional(number, 60)
      health_check_timeout             = optional(number, 30)
      health_check_path                = optional(string, null)
      health_check_matcher             = optional(string, null)
      stickiness_type                  = optional(string, "lb_cookie")
      cookie_duration                  = optional(number, 86400) # 1 day in seconds
    })))

    listeners = set(object({
      port                 = number
      protocol             = string
      default_action       = optional(string, "forward") # e.g. "forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc"
      target_group_name    = optional(string, null)
      redirect_host        = optional(string, null) # e.g. "api.lerkasan.net"
      redirect_port        = optional(string, null) # e.g. "443"
      redirect_protocol    = optional(string, null) # e.g. "HTTPS"
      redirect_status_code = optional(string, null) # e.g. "HTTP_301"
      ssl_policy           = optional(string, null) # e.g. "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn      = optional(string, null) # e.g. "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
    }))

    tags = optional(map(string), {})
  }))

  default = []
}

variable "s3_buckets" {
  type = list(object({
    name                = string
    region              = optional(string)
    enable_encryption   = optional(bool, true)
    enable_logging      = optional(bool, true)
    logging_bucket_name = optional(string, null)
    versioning_status   = optional(string, "Enabled")
    lifecycle_rule = optional(object({
      status                             = optional(string, "Enabled")
      prefix                             = optional(string, "")
      expiration_days                    = optional(number, 0)
      noncurrent_version_expiration_days = optional(number, 90)
      noncurrent_version_transition_days = optional(number, 30)
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for bucket in var.s3_buckets : can(regex("^[a-z0-9-]+$", bucket.name))
    ])
    error_message = "S3 bucket name must be a valid DNS-compliant name."
  }

  validation {
    condition = alltrue([
      for bucket in var.s3_buckets : contains(["Enabled", "Suspended", "Disabled"], bucket.versioning_status)
    ])
    error_message = "Valid values for s3_bucket.versioning_status are Enabled, Suspended, Disabled"
  }

  default = []
}
