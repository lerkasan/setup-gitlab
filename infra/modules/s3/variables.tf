variable "bucket_name" {
  description = "S3 bucket name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.bucket_name))
    error_message = "S3 bucket name must be a valid DNS-compliant name."
  }
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "bucket_key_enabled" {
  description = "Enable bucket key for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable access logging for the S3 bucket"
  type        = bool
  default     = true
}

variable "logging_bucket_name" {
  description = "Name of S3 bucket for logging access to the main S3 bucket"
  type        = string

  validation {
    condition     = var.logging_bucket_name != null ? can(regex("^[a-z0-9.-]+$", var.logging_bucket_name)) : true
    error_message = "S3 bucket name must be a valid DNS-compliant name."
  }
}

variable "versioning_status" {
  description = "Versioning status for the S3 bucket"
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.versioning_status)
    error_message = "Valid values for versioning_status are Enabled, Suspended, Disabled"
  }
}

variable "lifecycle_rule" {
  description = "Lifecycle rule for the S3 bucket"
  type = object({
    status                             = optional(string, "Enabled")
    prefix                             = optional(string, "")
    expiration_days                    = optional(number, 0)
    noncurrent_version_expiration_days = optional(number, 90)
    noncurrent_version_transition_days = optional(number, 30)
  })

  default = {
    status                             = "Enabled"
    prefix                             = ""
    expiration_days                    = 0
    noncurrent_version_expiration_days = 90
    noncurrent_version_transition_days = 30
  }
}

variable "tags" {
  description = "Tags for a bucket"
  type        = map(string)
  default     = {}
}