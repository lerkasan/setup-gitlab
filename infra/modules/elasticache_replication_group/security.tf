resource "aws_security_group" "this" {
  name        = join("_", [var.cache_replication_group_name, "cache-sg"])
  description = "security group for Elasticache ${var.cache_replication_group_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cache_replication_group_name}-cache-sg"
  })
}

resource "aws_security_group_rule" "elasticache_allow_inbound_tcp_from_appserver" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "ingress"
  description              = "Ingress to Elasticache from AppServer"
  from_port                = var.cache_port
  to_port                  = var.cache_port
  protocol                 = "tcp"
  source_security_group_id = var.appserver_sg_id
  security_group_id        = aws_security_group.this.id
}

resource "aws_security_group_rule" "appserver_allow_outbound_tcp_to_elasticache" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "egress"
  description              = "Egress from AppServer to Elasticache"
  from_port                = var.cache_port
  to_port                  = var.cache_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this.id
  security_group_id        = var.appserver_sg_id
}

