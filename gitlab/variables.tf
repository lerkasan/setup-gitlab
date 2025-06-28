variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "gitlab_token" {
  description = "GitLab API token"
  type        = string
  sensitive   = true
}

variable "gitlab_base_url" {
  description = "GitLab base URL"
  type        = string
  default     = "https://gitlab.com"
}

variable "admin_name" {
  description = "Name of the GitLab admin user"
  type        = string
  default     = "GitLab Admin"
}

variable "admin_username" {
  description = "Username for the GitLab admin user"
  type        = string
  sensitive = true
}

variable "admin_password" {
  description = "Password for the GitLab admin user"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Email address for the GitLab admin user"
  type        = string
  sensitive   = true
}