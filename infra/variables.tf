variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_networks" {
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
      for vpc in var.vpc_networks : can(regex("^[a-z0-9-]+$", vpc.name))
    ])
    error_message = "VPC name must have lowercase letters, numbers, and hyphens only)."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpc_networks : can(cidrhost(vpc.cidr_block, 32))
    ])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpc_networks : alltrue([
        for subnet in vpc.public_subnets : length(subnet) > 0 ? can(cidrhost(subnet, 32)) : true
      ])
    ])
    error_message = "Public subnets must have valid IPv4 CIDRs."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpc_networks : alltrue([
        for subnet in vpc.private_subnets : length(subnet) > 0 ? can(cidrhost(subnet, 32)) : true
      ])
    ])
    error_message = "Private subnets must have valid IPv4 CIDRs."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpc_networks : vpc.enable_flow_logs ? (vpc.flow_logs_retention_days >= 0) : true
    ])
    error_message = "Flow logs retention days must be 0 or greater if flow logs are enabled."
  }

  default = []
}

variable "ec2_appservers" {
  type = list(object({
    ec2_instance_type           = string
    vpc_cidr                    = string
    subnet_cidr                 = string
    associate_public_ip_address = optional(bool, false)
    bastion_name                = optional(string, "")
    volume_type                 = optional(string, "gp3")
    volume_size                 = optional(number, 10)
    delete_on_termination       = optional(bool, true)
    private_ssh_key_name        = string
    admin_public_ssh_key_names  = optional(list(string), [])
    ami_id                      = optional(string, null)
    os                          = string
    os_product                  = optional(string, "server")
    os_architecture             = optional(string, "amd64")
    os_version                  = string
    os_releases                 = map(string)
    ami_virtualization          = optional(string, "hvm")
    ami_architectures           = optional(map(string), { "amd64" = "x86_64" })
    ami_owner_ids               = optional(map(string), { "ubuntu" = "099720109477" }) # Canonical for Ubuntu AMIs

    enable_ec2_instance_connect_endpoint = optional(bool, false)

    enable_bastion_access     = optional(bool, false)
    bastion_security_group_id = optional(string, "")

    additional_security_group_ids = optional(set(string), [])

    attach_to_target_group = optional(bool, false)     # Whether to attach the EC2 instance to a target group
    target_group_arns      = optional(set(string), []) # ARN of the target group to attach the EC2 instance to

    additional_policy_arns = optional(list(string), [])
    iam_policy_statements = optional(set(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      condition = optional(map(string))
    })))

    user_data = optional(string, null)
    userdata_config = optional(object({
      vpc_cidr = optional(string, "10.0.0.0/16")
      # GitLab EE parameters    
      domain_name                   = optional(string, "localhost")
      install_gitlab                = optional(bool, false)
      gitlab_version                = optional(string, "17.11.4-ee.0")
      external_loadbalancer_enabled = optional(bool, false)
      external_postgres_enabled     = optional(bool, false)
      external_redis_enabled        = optional(bool, false)
      registry_enabled              = optional(bool, false)
      registry_s3_storage_enabled   = optional(bool, false)
      registry_s3_bucket            = optional(string, null)
      obj_store_s3_enabled          = optional(bool, false)
      obj_store_s3_bucket_prefix    = optional(string, "")
      db_adapter                    = optional(string, null)
      db_host                       = optional(string, null)
      db_port                       = optional(number, null)
      db_name                       = optional(string, null)
      db_username                   = optional(string, null)
      redis_host                    = optional(string, null)
      redis_port                    = optional(number, null)
      # GitLab Runner parameters
      install_gitlab_runner = optional(bool, false)
      gitlab_runner_version = optional(string, "17.11.4-1")
      docker_version        = optional(string, "5:28.3.0-1~ubuntu.22.04~jammy")
      docker_image          = optional(string, "docker:28.3.0-dind-rootless")
    }))

    tags = map(string)
  }))

  validation {
    condition     = alltrue([for ec2 in var.ec2_appservers : can(cidrhost(ec2.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

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
    additional_security_group_ids        = optional(set(string), [])
    user_data                            = optional(string, null)
    ami_id                               = optional(string, null)
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

  validation {
    condition     = alltrue([for ec2 in var.ec2_bastions : can(cidrhost(ec2.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

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
    lb_name                          = string
    lb_internal                      = optional(bool, false)
    lb_type                          = optional(string, "application")
    vpc_cidr                         = string
    subnets                          = list(string)
    domain_name                      = string
    subdomains                       = optional(set(string), [])
    lb_access_logs_bucket_name       = optional(string, null)
    waf_enabled                      = optional(bool, false)
    add_security_rules_for_appserver = optional(bool, false)       # Whether to add security group rules to allow traffic from the application server to the load balancer
    appserver_sg_id                  = optional(string, null)      # Security group ID for the application server that needs traffic to be allowed in the security group of the load balancer
    ssh_cidrs                        = optional(set(string), null) # CIDRs to allow SSH access to the load balancer (for NLB only)

    target_groups = optional(list(object({
      name                             = string
      target_type                      = optional(string, "instance") # e.g. "instance", "ip", "lambda", "alb"
      port                             = number
      protocol                         = string
      preserve_client_ip               = optional(bool, null)
      deregistration_delay             = optional(number, 300)
      health_check_healthy_threshold   = optional(number, 5)
      health_check_unhealthy_threshold = optional(number, 3)
      health_check_interval            = optional(number, 60)
      health_check_timeout             = optional(number, 30)
      health_check_protocol            = optional(string, "HTTP") # e.g. "HTTP", "HTTPS", "TCP", "TLS"
      health_check_path                = optional(string, null)
      health_check_matcher             = optional(string, null)
      stickiness_type                  = optional(string, null)
      cookie_duration                  = optional(number, 86400) # 1 day in seconds
    })))

    listeners = set(object({
      port                 = number
      protocol             = string
      default_action       = optional(string, "forward") # e.g. "forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc"
      target_group_name    = optional(string, null)
      redirect_host        = optional(string, null)
      redirect_port        = optional(string, null)
      redirect_protocol    = optional(string, null)
      redirect_status_code = optional(string, null) # e.g. "HTTP_301"
      ssl_policy           = optional(string, null) # e.g. "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn      = optional(string, null)
    }))

    member_of_target_groups = optional(set(string), []) # Names of the target group to attach the ALB to

    tags = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for lb in var.load_balancers : can(cidrhost(lb.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  default = []
}

variable "s3_buckets" {
  type = list(object({
    name                = string
    region              = optional(string)
    enable_encryption   = optional(bool, true)
    bucket_key_enabled  = optional(bool, true)
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

variable "rds_instances" {
  type = set(object({
    rds_name                   = string
    vpc_cidr                   = string
    private_subnets            = list(string)
    db_instance_class          = string
    db_engine                  = optional(string, "postgres")
    db_engine_version          = string
    db_port                    = optional(number, 5432)
    db_instance_storage_type   = optional(string, "gp3")
    db_allocated_storage       = optional(number, 20)
    db_max_allocated_storage   = optional(number, 30)
    db_backup_retention_period = optional(number, 30)
    db_maintenance_window      = optional(string, "Sun:02:00-Sun:04:00")
    db_name                    = string
    db_username                = string

    add_security_rules_for_appserver = optional(bool, false)  # Add rules to the RDS security group to allow access from the application server
    appserver_sg_id                  = optional(string, null) # Security group ID for the application server that needs traffic to be allowed in the security group of the RDS instance
    tags                             = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for instance in var.rds_instances : can(regex("^[a-z0-9]+$", instance.db_name))])
    error_message = "Database name must begin with a letter and contain only alphanumeric characters"
  }

  validation {
    condition     = alltrue([for instance in var.rds_instances : can(regex("^[a-zA-Z0-9-]+$", instance.rds_name))])
    error_message = "RDS instance name must be alphanumeric and can include hyphens."
  }

  validation {
    condition     = alltrue([for rds in var.rds_instances : can(cidrhost(rds.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  default = []
}

variable "cache_instances" {
  type = set(object({
    vpc_cidr                         = string
    private_subnets                  = list(string)
    cache_cluster_id                 = string
    cache_parameter_group_name       = string
    cache_parameter_group_family     = optional(string, "redis7")
    cache_engine                     = optional(string, "redis")
    cache_engine_version             = optional(string, "7.1")
    cache_node_type                  = string
    cache_num_nodes                  = optional(number, 1)
    cache_port                       = optional(number, 6379)
    cache_maintenance_window         = optional(string, "Sun:02:00-Sun:04:00")
    cache_snapshot_window            = optional(string, "05:00-09:00")
    cache_snapshot_retention_limit   = optional(number, 7)
    cache_multi_az_enabled           = optional(bool, false)
    cache_log_group_name             = string
    cache_log_retention_in_days      = optional(number, 365)
    add_security_rules_for_appserver = optional(bool, false)  # Whether to add security group rules to allow traffic from the application server to the cache instance
    appserver_sg_id                  = optional(string, null) # Security group ID for the application server that needs traffic to be allowed in the security group of the cache instance
    tags                             = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for rds in var.cache_instances : can(cidrhost(rds.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  default = []

}

variable "ec2_runners" {
  type = list(object({
    ec2_instance_type           = string
    vpc_cidr                    = string
    subnet_cidr                 = string
    associate_public_ip_address = optional(bool, false)
    bastion_name                = optional(string, "")
    volume_type                 = optional(string, "gp3")
    volume_size                 = optional(number, 10)
    delete_on_termination       = optional(bool, true)
    private_ssh_key_name        = string
    admin_public_ssh_key_names  = optional(list(string), [])
    ami_id                      = optional(string, null)
    os                          = string
    os_product                  = optional(string, "server")
    os_architecture             = optional(string, "amd64")
    os_version                  = string
    os_releases                 = map(string)
    ami_virtualization          = optional(string, "hvm")
    ami_architectures           = optional(map(string), { "amd64" = "x86_64" })
    ami_owner_ids               = optional(map(string), { "ubuntu" = "099720109477" }) # Canonical for Ubuntu AMIs

    enable_ec2_instance_connect_endpoint = optional(bool, false)

    enable_bastion_access     = optional(bool, false)
    bastion_security_group_id = optional(string, "")

    additional_security_group_ids = optional(set(string), [])

    additional_policy_arns = optional(list(string), [])
    iam_policy_statements = optional(set(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      condition = optional(map(string))
    })))

    user_data = optional(string, null)
    userdata_config = optional(object({
      domain_name = optional(string, "localhost")
      # GitLab Runner parameters
      install_gitlab_runner = optional(bool, false)
      gitlab_runner_version = optional(string, "17.11.4-1")
      docker_version        = optional(string, "5:28.3.0-1~ubuntu.22.04~jammy")
      docker_image          = optional(string, "docker:28.3.0-dind-rootless")
      concurrent            = optional(number, 1)
      check_interval        = optional(number, 0)
      connection_max_age    = optional(string, "15m0s")
      shutdown_timeout      = optional(number, 0)
      session_timeout       = optional(number, 1800)
    }))

    tags = map(string)
  }))

  validation {
    condition     = alltrue([for ec2 in var.ec2_runners : can(cidrhost(ec2.vpc_cidr, 32))])
    error_message = "VPC CIDR must be a valid IPv4 CIDR."
  }

  default = []
}

variable "admin_public_ssh_key_names" {
  description = "List of names of the SSM parameters with admin public ssh keys"
  type        = list(string)
  default     = []
}