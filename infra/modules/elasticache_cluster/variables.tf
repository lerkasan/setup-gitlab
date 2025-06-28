# -------------- Network parameters ---------------

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnets ids"
  type        = list(string)
}

variable "appserver_sg_id" {
  description = "A security group id of an application server"
  type        = string
  default     = null
}

variable "add_security_rules_for_appserver" {
  description = "Add rules to the Elasticache security group to allow access from the application server"
  type        = bool
  default     = false
}

# --------------- Cache parameters

variable "cache_cluster_id" {
  description = "Cache cluster name"
  type        = string
}

variable "cache_parameter_group_name" {
  description = "Cache name"
  type        = string
}

variable "cache_parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "redis7"

  validation {
    condition     = contains(["redis2.6", "redis2.8", "redis3.2", "redis4.0", "redis5.0", "redis6.x", "redis7"], var.cache_parameter_group_family)
    error_message = "Valid values for a variable cache_parameter_group_family are: redis2.6 | redis2.8 | redis3.2 | redis4.0 | redis5.0 | redis6.x | redis7"
  }
}

variable "cache_node_type" {
  description = "Cache node type"
  type        = string
}

variable "cache_num_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1

  validation {
    condition     = tonumber(var.cache_num_nodes) == floor(var.cache_num_nodes)
    error_message = "cache_num_nodes should be an integer."
  }

  validation {
    condition     = var.cache_num_nodes >= 1
    error_message = "cache_num_nodes should be greater or equal 1"
  }
}

variable "cache_engine" {
  description = "Cache engine"
  type        = string
  default     = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.cache_engine)
    error_message = "Valid values for a variable cache_engine are: redis | valkey"
  }
}

variable "cache_engine_version" {
  description = "Cache engine version"
  type        = string
}

variable "cache_port" {
  description = "Cache port"
  type        = number
  default     = 6379
}

variable "cache_maintenance_window" {
  description = "cache maintenance window"
  type        = string
  default     = "Sun:02:00-Sun:04:00"
}

variable "cache_snapshot_window" {
  description = "cache snapshot window"
  type        = string
  default     = "05:00-09:00"
}

variable "cache_snapshot_retention_limit" {
  description = "cache snapshot retention limit"
  type        = number

  validation {
    condition     = tonumber(var.cache_snapshot_retention_limit) == floor(var.cache_snapshot_retention_limit)
    error_message = "cache_snapshot_retention_limit should be an integer."
  }

  validation {
    condition     = var.cache_snapshot_retention_limit >= 0
    error_message = "cache_snapshot_retention_limit should be greater or equal 0"
  }
}

variable "cache_log_group_name" {
  description = "cache log_group name for CloudWatch"
  type        = string
}

variable "cache_log_retention_in_days" {
  description = "Number of days to keep Elasticache logs in CloudWatch"
  type        = number
  default     = 90

  validation {
    condition     = tonumber(var.cache_log_retention_in_days) == floor(var.cache_log_retention_in_days)
    error_message = "cache_log_retention_in_days should be an integer!"
  }
  validation {
    condition     = var.cache_log_retention_in_days >= 0
    error_message = "cache_log_retention_in_days should be a positive integer!"
  }
}

variable "tags" {
  description = "A map of tags to apply to Elasticache and its resources"
  type        = map(string)
  default     = {}
}