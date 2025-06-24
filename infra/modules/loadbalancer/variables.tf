variable "domain_name" {
  description = "Domain name"
  type        = string
}

# ---------------- Network parameters -------------------

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnets ids"
  type        = list(string)
}

# ----------------- Load balancer parameters -----------------

variable "lb_name" {
  description = "A name of a load balancer"
  type        = string
}

variable "lb_internal" {
  description = "Is a load balancer intenal"
  type        = bool
  default     = false
}

variable "lb_type" {
  description = "A type of a load balancer"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network", "gateway"], var.lb_type)
    error_message = "Valid values for a variable lb_type are application, network, gateway."
  }
}

variable "lb_access_logs_bucket_name" {
  description = "Bucket name for website access logs "
  type        = string

  validation {
    condition     = var.lb_access_logs_bucket_name != null ? can(regex("^[a-z0-9.-]+$", var.lb_access_logs_bucket_name)) : true
    error_message = "S3 bucket name for LB access logs must be a valid DNS-compliant name."
  }
}

variable "listeners" {
  description = "A map of listeners for a load balancer"
  type = set(object({
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

  validation {
    condition = alltrue([
      for listener in var.listeners : tonumber(listener.port) == floor(listener.port)
    ])
    error_message = "port property of a variable listeners should be an integer!"
  }

  validation {
    condition = alltrue([
      for listener in var.listeners : listener.port >= 0
    ])
    error_message = "port property of a variable listeners should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for listener in var.listeners : contains(["HTTP", "HTTPS", "TCP", "TLS"], listener.protocol)
    ])
    error_message = "Valid values for a property protocol in a variable listeners are HTTP, HTTPS, TCP, or TLS."
  }

  validation {
    condition = alltrue([
      for listener in var.listeners : listener.ssl_policy == null ? true : contains([
        "ELBSecurityPolicy-TLS13-1-3-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Res-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Ext2-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Ext1-2021-06",
        "ELBSecurityPolicy-TLS-1-2-Ext-2018-06",
        "ELBSecurityPolicy-TLS-1-2-2017-01"
      ], listener.ssl_policy)
    ])
    error_message = "Valid values for a property ssl_policy in a variable listeners can be found at https://docs.aws.amazon.com/elasticloadbalancing/latest/network/describe-ssl-policies.html"
  }
}

variable "target_groups" {
  description = "A map of target groups for a load balancer"
  type = set(object({
    name                             = string
    port                             = number
    protocol                         = string
    preserve_client_ip               = optional(bool, null)
    deregistration_delay             = optional(number, 300) # in seconds
    health_check_healthy_threshold   = optional(number, 3)
    health_check_unhealthy_threshold = optional(number, 3)
    health_check_interval            = optional(number, 60)
    health_check_timeout             = optional(number, 30)
    health_check_path                = optional(string, null)
    health_check_matcher             = optional(string, null)        # e.g. HTTP code "200"
    stickiness_type                  = optional(string, "lb_cookie") # e.g. "lb_cookie", "app_cookie", "source_ip", "source_ip_dest_ip", "source_ip_dest_ip_proto"
    cookie_duration                  = optional(number, 86400)       # in seconds
  }))

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.port) == floor(tg.port)
    ])
    error_message = "port property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.port >= 0
    ])
    error_message = "port property of a variable target_groups should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : contains(["HTTP", "HTTPS", "TCP", "TCP_UDP", "TLS", "UDP"], tg.protocol)
    ])
    error_message = "Valid values for a property stickiness_type in a variable target_groups are HTTP, HTTPS, TCP, TCP_UDP, TLS, or UDP."
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.deregistration_delay) == floor(tg.deregistration_delay)
    ])
    error_message = "deregistration_delay property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.deregistration_delay >= 0
    ])
    error_message = "deregistration_delay property of a variable target_groups should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : contains(["lb_cookie", "app_cookie", "source_ip", "source_ip_dest_ip", "source_ip_dest_ip_proto"], tg.stickiness_type)
    ])
    error_message = "Valid values for a property stickiness_type in a variable target_groups are lb_cookie, app_cookie."
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.cookie_duration) == floor(tg.cookie_duration)
    ])
    error_message = "cookie_duration property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.cookie_duration >= 0
    ])
    error_message = "cookie_duration property of a variable target_groups should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.health_check_healthy_threshold) == floor(tg.health_check_healthy_threshold)
    ])
    error_message = "health_check_healthy_threshold property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.health_check_healthy_threshold >= 0
    ])
    error_message = "health_check_healthy_threshold property of a variable target_groups should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.health_check_unhealthy_threshold) == floor(tg.health_check_unhealthy_threshold)
    ])
    error_message = "health_check_unhealthy_threshold property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.health_check_unhealthy_threshold >= 0
    ])
    error_message = "health_check_unhealthy_threshold property of a variable target_groups should be a positive integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.health_check_interval) == floor(tg.health_check_interval)
    ])
    error_message = "health_check_interval property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.health_check_interval >= 0
    ])
    error_message = "health_check_interval property of a variable target_groups should be a positive integer!"
  }
  validation {
    condition = alltrue([
      for tg in var.target_groups : tonumber(tg.health_check_timeout) == floor(tg.health_check_timeout)
    ])
    error_message = "health_check_timeout property of a variable target_groups should be an integer!"
  }

  validation {
    condition = alltrue([
      for tg in var.target_groups : tg.health_check_timeout >= 0
    ])
    error_message = "health_check_timeout property of a variable target_groups should be a positive integer!"
  }
}

variable "waf_enabled" {
  description = "Enable WAF for the load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to apply to a load balancer and its resources"
  type        = map(string)
  default     = {}
}
