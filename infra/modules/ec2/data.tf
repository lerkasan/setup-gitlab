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

data "aws_vpc_endpoint" "s3" {
  count = var.userdata_config != null && var.userdata_config.registry_s3_storage_enabled ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

data "aws_s3_bucket" "this" {
  count = var.userdata_config != null && var.userdata_config.registry_s3_storage_enabled ? 1 : 0

  bucket = var.userdata_config.registry_s3_bucket
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
              region                        = data.aws_region.current.name,
              domain_name                   = var.userdata_config.domain_name,
              external_loadbalancer_enabled = var.userdata_config.external_loadbalancer_enabled,
              external_postgres_enabled     = var.userdata_config.external_postgres_enabled,
              external_redis_enabled        = var.userdata_config.external_redis_enabled,
              registry_enabled              = var.userdata_config.registry_enabled,
              registry_s3_storage_enabled   = var.userdata_config.registry_s3_storage_enabled,
              registry_s3_bucket            = var.userdata_config.registry_s3_storage_enabled ? var.userdata_config.registry_s3_bucket : null,
              # Currently in gitlab_rb.tftpl we do not use property 'regionendpoint' => '${s3_vpc_regionendpoint}' in registry configuration. 
              # TODO: research which value should be used for regionendpoint property, if we have a VPC endpoint for S3 and proper routes
              # s3_vpc_regionendpoint         = var.userdata_config.registry_s3_storage_enabled ? data.aws_vpc_endpoint.s3[0].arn : null,
              db_adapter  = var.userdata_config.db_adapter,
              db_host     = var.userdata_config.db_host,
              db_port     = var.userdata_config.db_port,
              db_name     = var.userdata_config.db_name,
              db_username = var.userdata_config.db_username,
              redis_host  = var.userdata_config.redis_host,
              redis_port  = var.userdata_config.redis_port
            })
          },
          {
            "path"        = "/tmp/populate_gitlab_config.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.module}/templates/populate_gitlab_config_sh.tftpl", {
              region = data.aws_region.current.name
            })
          },
          {
            "path"        = "/tmp/install_docker.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.module}/templates/install_docker_sh.tftpl", {
              docker_version = var.userdata_config.docker_version
            })
          },
          {
            "path"        = "/tmp/add_gitlab_runner.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.module}/templates/add_gitlab_runner_sh.tftpl", {
              region                = data.aws_region.current.name,
              domain_name           = var.userdata_config.domain_name,
              gitlab_runner_version = var.userdata_config.gitlab_runner_version
              docker_image          = var.userdata_config.docker_image,
              domain_name           = var.userdata_config.domain_name
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
      region                = data.aws_region.current.name,
      install_gitlab        = var.userdata_config.install_gitlab,
      install_gitlab_runner = var.userdata_config.install_gitlab_runner,
      gitlab_version        = var.userdata_config.gitlab_version,
      public_ssh_keys       = [for key in data.aws_ssm_parameter.admin_public_ssh_keys : key.value]
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