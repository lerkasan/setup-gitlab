resource "aws_security_group" "additional_sg_for_appserver" {
  for_each = { for ec2 in var.ec2_appservers : coalesce(ec2.tags["Name"], "noname") => ec2 }

  name        = "${each.key}-additional-sg"
  description = "Additional security group for EC2 instance ${each.key}"
  vpc_id      = module.vpc[each.value.vpc_cidr].vpc_id

  tags = merge(each.value.tags, {
    Name = "${each.key}-additional-sg"
  })
}

resource "aws_security_group_rule" "alb_allow_inbound_http_from_nlb" {
  type                     = "ingress"
  description              = "HTTP ingress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = module.loadbalancer["gitlab-nlb"].security_group_id
  security_group_id        = module.loadbalancer["gitlab-alb"].security_group_id
}

resource "aws_security_group_rule" "alb_allow_inbound_https_from_nlb" {
  type                     = "ingress"
  description              = "HTTPS ingress"
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  source_security_group_id = module.loadbalancer["gitlab-nlb"].security_group_id
  security_group_id        = module.loadbalancer["gitlab-alb"].security_group_id
}

resource "aws_security_group_rule" "nlb_allow_outbound_http_to_alb" {
  type                     = "egress"
  description              = "HTTP egress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = module.loadbalancer["gitlab-alb"].security_group_id
  security_group_id        = module.loadbalancer["gitlab-nlb"].security_group_id
}

resource "aws_security_group_rule" "nlb_allow_outbound_https_to_alb" {
  type                     = "egress"
  description              = "HTTPS egress"
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  source_security_group_id = module.loadbalancer["gitlab-alb"].security_group_id
  security_group_id        = module.loadbalancer["gitlab-nlb"].security_group_id
}