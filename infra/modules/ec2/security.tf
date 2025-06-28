resource "aws_security_group" "ec2_instance" {
  name        = join("_", [coalesce(var.tags["Name"], "noname"), "security-group"])
  description = "security group for EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = join("_", [coalesce(var.tags["Name"], "noname"), "ec2-instance-sg"])
  })
}

resource "aws_security_group_rule" "allow_inbound_ssh_to_ec2_instance_from_admin_ip" {
  for_each = var.admin_public_ips != null ? toset(var.admin_public_ips) : []

  type              = "ingress"
  description       = "SSH ingress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [format("%s/%s", each.value, 32)]
  security_group_id = aws_security_group.ec2_instance.id
}

resource "aws_security_group_rule" "allow_inbound_ssh_to_ec2_instance_from_bastion" {
  count = var.enable_bastion_access ? 1 : 0

  type                     = "ingress"
  description              = "SSH ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  security_group_id        = aws_security_group.ec2_instance.id
}

resource "aws_security_group_rule" "allow_outbound_ssh_from_bastion_to_ec2_instance" {
  count = var.enable_bastion_access ? 1 : 0

  type                     = "egress"
  description              = "SSH egress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_instance.id
  security_group_id        = var.bastion_security_group_id
}

resource "aws_security_group_rule" "allow_inbound_ssh_to_ec2_instance_from_ec2_connect_endpoint" {
  count = var.enable_ec2_instance_connect_endpoint ? 1 : 0

  type                     = "ingress"
  description              = "SSH ingress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = var.ec2_connect_endpoint_security_group_id
  security_group_id        = aws_security_group.ec2_instance.id
}

resource "aws_security_group_rule" "allow_outbound_ssh_from_ec2_instance_to_ec2_connect_endpoint" {
  count = var.enable_ec2_instance_connect_endpoint ? 1 : 0

  type                     = "egress"
  description              = "SSH egress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_instance.id
  security_group_id        = var.ec2_connect_endpoint_security_group_id
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr 
resource "aws_security_group_rule" "allow_outbound_https_from_ec2_instance_to_all" {
  type              = "egress"
  description       = "HTTPS egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = [local.anywhere]
  security_group_id = aws_security_group.ec2_instance.id
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr 
resource "aws_security_group_rule" "allow_outbound_http_from_ec2_instance_to_all" {
  type              = "egress"
  description       = "HTTP egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = [local.anywhere]
  security_group_id = aws_security_group.ec2_instance.id
}

resource "aws_security_group_rule" "allow_outbound_icmp_from_ec2_instance_to_8_8_8_8" {
  type        = "egress"
  description = "ICMP egress"
  # https://blog.jwr.io/terraform/icmp/ping/security/groups/2018/02/02/terraform-icmp-rules.html
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = [local.ip_8_8_8_8]
  security_group_id = aws_security_group.ec2_instance.id
}
