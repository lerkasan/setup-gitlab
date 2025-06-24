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
  type              = "ingress"
  description       = "HTTP ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = [local.anywhere]
  security_group_id = aws_security_group.this.id
}

# resource "aws_security_group_rule" "lb_allow_outbound_to_gitlab_server" {
#   type                     = "egress"
#   description              = "Egress to GitLab Server"
#   from_port                = local.http_port
#   to_port                  = local.http_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.appserver.id
#   security_group_id        = aws_security_group.this.id
# }