resource "aws_security_group" "this" {
  name        = join("_", [var.rds_name, "_rds-sg"])
  description = "security group for RDS instance ${var.rds_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.rds_name}-rds-sg"
  })
}

resource "aws_security_group_rule" "rds_allow_inbound_tcp_from_appserver" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "ingress"
  description              = "Ingress to RDS from AppServer"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = var.appserver_sg_id
  security_group_id        = aws_security_group.this.id
}

resource "aws_security_group_rule" "appserver_allow_outbound_tcp_to_rds" {
  count = var.add_security_rules_for_appserver ? 1 : 0

  type                     = "egress"
  description              = "Egress from AppServer to RDS"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this.id
  security_group_id        = var.appserver_sg_id
}
