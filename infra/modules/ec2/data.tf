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

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/userdata.tftpl", {
      public_ssh_keys = [for key in data.aws_ssm_parameter.admin_public_ssh_keys : key.value]
    })
  }
}

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