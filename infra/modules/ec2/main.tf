#trivy:ignore:AVD-AWS-0131  # TODO: Add KMS key, add permissions for the user to access KMS key, and then encrypt root EBS volume
resource "aws_instance" "this" {
  ami                         = data.aws_ami.this.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.private_ssh_key_name
  vpc_security_group_ids      = [aws_security_group.ec2_instance.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  user_data                   = data.cloudinit_config.user_data.rendered
  ebs_optimized               = true
  monitoring                  = true

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size
    # encrypted             = true  # TODO: Add KMS key, add permissions for the user to access KMS key, and then encrypt root EBS volume
    delete_on_termination = var.delete_on_termination
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = join("_", [coalesce(var.tags["Name"], "noname"), "iam-profile"])
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name = join("_", [coalesce(var.tags["Name"], "noname"), "iam-profile"])
  })
}

resource "aws_iam_role" "this" {
  name               = join("_", [coalesce(var.tags["Name"], "noname"), "iam-role"])
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = join("_", [coalesce(var.tags["Name"], "noname"), "iam-role"])
  })
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  count = var.enable_ec2_instance_connect_endpoint ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}