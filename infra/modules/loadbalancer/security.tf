resource "aws_security_group" "this" {
  name        = join("_", [var.lb_name, "_lb-security-group"])
  description = "security group for loadbalancer ${var.lb_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.lb_name}-lb-sg"
  })
}

# A security group rule to allow inbound HTTPS traffic to the internet-facing load balancer.
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "lb_allow_inbound_https_from_all" {
  count = var.lb_internal ? 0 : 1

  type              = "ingress"
  description       = "HTTPS ingress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = [local.anywhere]
  security_group_id = aws_security_group.this.id
}

# A security group rule to allow inbound HTTP traffic to the internet-facing load balancer.
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "lb_allow_inbound_http_from_all" {
  #checkov:skip=CKV_AWS_260: We allow HTTP traffic to the load balancer and redirect it to HTTPS.
  count = var.lb_internal ? 0 : 1

  type              = "ingress"
  description       = "HTTP ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = [local.anywhere]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "lb_allow_outbound_http_to_appserver" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "egress"
  description              = "Egress from LoadBalancer to AppServer"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = var.appserver_sg_id
  security_group_id        = aws_security_group.this.id
}

resource "aws_security_group_rule" "appserver_allow_inbound_http_from_loadbalancer" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "ingress"
  description              = "Ingress to AppServer from LoadBalancer "
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this.id
  security_group_id        = var.appserver_sg_id
}

resource "aws_security_group_rule" "lb_allow_inbound_ssh_from_ssh_cidrs" {
  for_each = var.lb_type == "network" && !var.lb_internal && var.ssh_cidrs != null ? var.ssh_cidrs : []

  type              = "ingress"
  description       = "SSH ingress"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "lb_allow_outbound_ssh_to_appserver" {
  count = var.lb_type == "network" && var.add_security_rules_for_appserver ? 1 : 0

  type                     = "egress"
  description              = "SSH egress"
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = var.appserver_sg_id
  security_group_id        = aws_security_group.this.id
}

resource "aws_security_group_rule" "appserver_allow_inbound_ssh_from_network_loadbalancer" {
  count = var.lb_type == "network" && var.add_security_rules_for_appserver ? 1 : 0

  type                     = "ingress"
  description              = "Ingress SSH to AppServer from LoadBalancer "
  from_port                = local.ssh_port
  to_port                  = local.ssh_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this.id
  security_group_id        = var.appserver_sg_id
}
