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

# # ------------------- User data for cloud-init --------------------------
# # The additional public ssh key will be added to ec2 instances using cloud-init
data "cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/userdata.tftpl", {
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