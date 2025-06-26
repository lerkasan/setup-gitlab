resource "aws_ssm_parameter" "cache_host" {
  name        = join("_", [var.cache_replication_group_name, "cache_host"])
  description = "Cache host"
  type        = "SecureString"
  value = split(":", aws_elasticache_replication_group.this.primary_endpoint_address)[0]
  # If cluster mode is enabled for ElastiCache than use cluster will have only configuration_endpoint_address
  #   value       = split(":", aws_elasticache_replication_group.this.configuration_endpoint_address)[0] 

  tags = merge(var.tags, {
    Name = "${var.cache_replication_group_name}-cache-host"
  })
}

resource "aws_ssm_parameter" "cache_port" {
  name        = join("_", [var.cache_replication_group_name, "cache_port"])
  description = "Cache port"
  type        = "SecureString"
  value = var.cache_port
  # If cluster mode is enabled for ElastiCache than use cluster will have only configuration_endpoint_address
  #   value       = split(":", aws_elasticache_replication_group.this.configuration_endpoint_address)[1]

  tags = merge(var.tags, {
    Name = "${var.cache_replication_group_name}-cache-port"
  })
}

resource "aws_ssm_parameter" "cache_db" {
  name        = join("_", [var.cache_replication_group_name, "cache_db"])
  description = "Cache db"
  type        = "SecureString"
  value = var.cache_db

  tags = merge(var.tags, {
    Name = "${var.cache_replication_group_name}-cache-db"
  })
}

resource "aws_ssm_parameter" "cache_password" {
  name        = join("_", [var.cache_replication_group_name, "cache_password"])
  description = "Cache password"
  type        = "SecureString"
  value = random_password.cache.result

  tags = merge(var.tags, {
    Name = "${var.cache_replication_group_name}-cache-password"
  })
}

resource "random_password" "cache" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}