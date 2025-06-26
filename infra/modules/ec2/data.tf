data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "architecture"
    values = [local.ami_architecture]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ami_virtualization]
  }

  owners = [local.ami_owner_id]
}

data "aws_ssm_parameter" "admin_public_ssh_keys" {
  for_each = toset(var.admin_public_ssh_key_names)

  name            = each.value
  with_decryption = true
}

# ------------------- User data for cloud-init --------------------------
# The additional public ssh key will be added to ec2 instances using cloud-init
data "cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = var.userdata_config != null ? [1] : []

    content {
      content_type = "text/cloud-config"
      content = yamlencode({
        "write_files" = [
          {
            "path"        = "/etc/gitlab/gitlab.rb.template"
            "permissions" = "0600"
            "owner"       = "root:root"
            "content" = templatefile("${path.module}/templates/gitlab_rb.tftpl", {
              vpc_cidr                      = data.aws_vpc.this.cidr_block,
              domain_name                   = var.userdata_config.domain_name,
              external_loadbalancer_enabled = var.userdata_config.external_loadbalancer_enabled,
              external_postgres_enabled     = var.userdata_config.external_postgres_enabled,
              external_redis_enabled        = var.userdata_config.external_redis_enabled,
              db_adapter                    = var.userdata_config.db_adapter,
              db_host                       = var.userdata_config.db_host,
              db_port                       = var.userdata_config.db_port,
              db_name                       = var.userdata_config.db_name,
              db_username                   = var.userdata_config.db_username,
              redis_host                    = var.userdata_config.redis_host,
              redis_port                    = var.userdata_config.redis_port
            })
          },
          {
            "path"        = "/tmp/populate_gitlab_config.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.module}/templates/populate_gitlab_config_sh.tftpl", {
              region = data.aws_region.current.name
            })
          }
        ]
        }
      )
    }
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/userdata.tftpl", {
      region          = data.aws_region.current.name,
      install_gitlab  = var.userdata_config.install_gitlab,
      gitlab_version  = var.userdata_config.gitlab_version,
      public_ssh_keys = [for key in data.aws_ssm_parameter.admin_public_ssh_keys : key.value]
    })
  }
}


# ------------- Obtain my public IP to grant SSH access -------------------

# Only for using with local terraform runs. 
# In case of using with terraform as a part of CI/CD pipeline this should be replaced with a variable that equals to admin public ip-address. 
# Otherwise admin_public_ip would be evaluated to the ip-address of CI/CD runner
#
# data "external" "admin_public_ip" {
#   program = ["bash", "-c", "jq -n --arg admin_public_ip $(dig +short myip.opendns.com @resolver1.opendns.com -4) '{\"admin_public_ip\":$admin_public_ip}'"]
# }

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  for_each = { for statement in var.iam_policy_statements : statement.sid => statement }

  statement {
    sid       = each.value.sid
    effect    = each.value.effect
    actions   = each.value.actions
    resources = each.value.resources
  }
}