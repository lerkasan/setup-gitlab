resource "aws_ssm_parameter" "cache_host" {
  # checkov:skip=CKV_AWS_337: "Ensure SSM parameters are using KMS CMK"
  name        = join("_", [var.cache_cluster_id, "cache_host"])
  description = "Cache host"
  type        = "SecureString"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address

  tags = merge(var.tags, {
    Name = "${var.cache_cluster_id}-cache-host"
  })
}
