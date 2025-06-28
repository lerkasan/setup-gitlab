# ---------------- EC2 parameters -----------
variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID for the EC2 instance"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
  default     = ""
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the EC2 instance"
  type        = bool
  default     = false
}

variable "volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 10
}

variable "delete_on_termination" {
  description = "Delete EBS volume on instance termination"
  type        = bool
  default     = true
}

variable "private_ssh_key_name" {
  description = "Name of the SSH keypair to use with appserver"
  type        = string
  default     = "appserver_ssh_key_pair"
  sensitive   = true
}

variable "admin_public_ssh_key_names" {
  description = "List of names of the SSM parameters with admin public ssh keys"
  type        = list(string)
  default     = ["ssh_public_key"]
}

variable "admin_public_ips" {
  description = "List of admin public IPs to allow SSH access"
  type        = list(string)
  default     = []
}

variable "enable_bastion_access" {
  description = "Enable access to the EC2 instance via a bastion host"
  type        = bool
  default     = false
}

variable "enable_ec2_instance_connect_endpoint" {
  description = "Enable EC2 Instance Connect Endpoint"
  type        = bool
  default     = false
}

variable "additional_security_group_ids" {
  description = "Set of additional security group IDs to attach to the EC2 instance"
  type        = set(string)
  default     = []
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  type        = string
  default     = ""
}

variable "ec2_connect_endpoint_security_group_id" {
  description = "Security group ID of the EC2 Instance Connect Endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ---------------- OS parameters --------------------

variable "os" {
  description = "AMI OS"
  type        = string
  default     = "ubuntu"
}

variable "os_product" {
  description = "AMI OS product. Values: server or server-minimal"
  type        = string
  default     = "server"
}

variable "os_architecture" {
  description = "OS architecture"
  type        = string
  default     = "amd64"
}

variable "os_version" {
  description = "OS version"
  type        = string
  default     = "22.04"
}

variable "os_releases" {
  description = "OS release"
  type        = map(string)
  default = {
    "22.04" = "jammy"
  }
}

# ---------------- AMI filters ----------------------

variable "ami_virtualization" {
  description = "AMI virtualization type"
  type        = string
  default     = "hvm"
}

variable "ami_architectures" {
  description = "AMI architecture filters"
  type        = map(string)
  default = {
    "amd64" = "x86_64"
  }
}

variable "ami_owner_ids" {
  description = "AMI owner id"
  type        = map(string)
  default = {
    "ubuntu" = "099720109477" #Canonical
  }
}

variable "iam_policy_statements" {
  description = "AWS IAM policies to attach to the EC2 instance role"
  type = set(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
    condition = optional(map(string))
    # principals  = optional(map(string))
  }))

  default = []
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the EC2 instance role"
  type        = list(string)
  default     = []
}

variable "attach_to_target_group" {
  description = "Whether to attach the EC2 instance to a target group"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group to attach the EC2 instance to"
  type        = string
  default     = null
}

variable "userdata_config" {
  description = "Application configuration for the EC2 instance"
  type = object({
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
    # registry_s3_vpc_regionendpoint = optional(string, null)
    db_adapter  = optional(string, null)
    db_host     = optional(string, null)
    db_port     = optional(number, null)
    db_name     = optional(string, null)
    db_username = optional(string, null)
    redis_host  = optional(string, null)
    redis_port  = optional(number, null)
    # GitLab Runner parameters
    install_gitlab_runner = optional(bool, false)
    gitlab_runner_version = optional(string, "17.11.4-1")
    docker_version        = optional(string, "5:28.3.0-1~ubuntu.22.04~jammy")
    docker_image          = optional(string, "docker:28.3.0-dind-rootless")
  })

  default = {}
}