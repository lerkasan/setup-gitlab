resource "aws_elasticache_cluster" "this" {
  cluster_id     = var.cache_cluster_id
  node_type      = var.cache_node_type
  engine         = var.cache_engine
  engine_version = var.cache_engine_version
  port           = var.cache_port

  num_cache_nodes          = var.cache_num_nodes
  subnet_group_name        = aws_elasticache_subnet_group.this.name
  security_group_ids       = [aws_security_group.this.id]
  parameter_group_name     = aws_elasticache_parameter_group.this.name
  apply_immediately        = false
  maintenance_window       = var.cache_maintenance_window
  snapshot_window          = var.cache_snapshot_window
  snapshot_retention_limit = var.cache_snapshot_retention_limit

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.slow_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.engine_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  tags = var.tags
}

resource "aws_elasticache_subnet_group" "this" {
  name       = join("-", [var.cache_cluster_id, "cache-subnet-group"])
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cache_cluster_id}-cache-subnet-group"
  })
}

resource "aws_elasticache_parameter_group" "this" {
  name   = var.cache_parameter_group_name
  family = var.cache_parameter_group_family

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }

  tags = merge(var.tags, {
    Name = "${var.cache_cluster_id}-cache-parameter-group"
  })
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "slow_logs" {
  # checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
  name              = join("-", [var.cache_cluster_id, var.cache_log_group_name, "slow-logs"])
  retention_in_days = var.cache_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.cache_cluster_id}-cache-slow-log-group"
  })
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "engine_logs" {
  # checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
  name              = join("-", [var.cache_cluster_id, var.cache_log_group_name, "engine-logs"])
  retention_in_days = var.cache_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.cache_cluster_id}-cache-engine-log-group"
  })
}