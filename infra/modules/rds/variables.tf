
# -------------- Database access parameters ---------------

variable "rds_name" {
  description = "The name of the RDS instance"
  type        = string
  default     = "db"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.rds_name))
    error_message = "RDS database name must be alphanumeric and can include hyphens."
  }
}

variable "database_engine" {
  description = "database engine"
  type        = string
  default     = "postgres"
}

variable "database_engine_version" {
  description = "database engine version"
  type        = string
  default     = "16.3"
}

variable "database_instance_class" {
  description = "database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_storage_type" {
  description = "database storage type"
  type        = string
  default     = "gp3"
}

variable "database_allocated_storage" {
  description = "database allocated storage size in GB"
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "database max allocated storage size in GB"
  type        = number
  default     = 30
}

variable "database_backup_retention_period" {
  description = "database backup retention period in days"
  type        = number
  default     = 30
}

variable "database_maintenance_window" {
  description = "database maintenance window"
  type        = string
  default     = "Sun:02:00-Sun:04:00"
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "Database name variable passed through a file secret.tfvars or an environment variable TF_database_name"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.database_name))
    error_message = "Database name must begin with a letter and contain only alphanumeric characters"
  }
}

variable "database_username" {
  description = "Database username variable passed through a file secret.tfvars or environment variable TF_database_username"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to apply to RDS and its resources"
  type        = map(string)
  default     = {}
}

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
  description = "A security group id of an application server that can access the RDS database"
  type        = string
  default     = null
}

variable "add_security_rules_for_appserver" {
  description = "Add rules to the RDS security group to allow access from the application server"
  type        = bool
  default     = false
}