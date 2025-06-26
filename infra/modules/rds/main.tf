resource "aws_db_instance" "primary" {
  storage_type            = var.database_storage_type
  allocated_storage       = var.database_allocated_storage
  max_allocated_storage   = var.database_max_allocated_storage
  backup_retention_period = var.database_backup_retention_period
  #   deletion_protection     = true
  identifier     = var.rds_name
  engine         = var.database_engine
  engine_version = var.database_engine_version
  instance_class = var.database_instance_class
  port           = var.database_port
  db_name        = var.database_name
  username       = var.database_username

  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.sm_secret_encrypt_key.key_id

  # multi_az                        = true      # creating multi-AZ RDS instance will take about 30 minutes instead of 10 minutes
  availability_zone               = local.availability_zones[0]
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  publicly_accessible             = false
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.database_encrypt_key.arn
  auto_minor_version_upgrade      = true
  maintenance_window              = var.database_maintenance_window
  enabled_cloudwatch_logs_exports = ["postgresql"] # audit, error, general, slowquery - mysql; /    postgresql, upgrade - postgres
  skip_final_snapshot             = true           # For testing purposes only

  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = join("_", [var.rds_name, "db-subnet-group"])
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.rds_name}-db-subnet-group"
  })
}

# # Read replica - it adds additional 30 minutes to create multi-AZ read replica
# resource "aws_db_instance" "read_replica" {
#   identifier                      = "${var.rds_name}-read-replica"
#   replicate_source_db             = aws_db_instance.primary.identifier
#   kms_key_id                      = aws_kms_key.database_encrypt_key.arn
#   instance_class                  = var.database_instance_class
#   storage_type                    = var.database_storage_type
#   max_allocated_storage           = var.database_allocated_storage
#   backup_retention_period         = var.database_backup_retention_period
#   apply_immediately               = false
#   publicly_accessible             = false
#   multi_az                        = true
# #   db_subnet_group_name            = aws_db_subnet_group.this.name
#   vpc_security_group_ids          = [ aws_security_group.database.id ]
#   enabled_cloudwatch_logs_exports = [ "error", "slowquery" ]
#   skip_final_snapshot             = true

# tags = merge(var.tags, {
#   Name = "${var.rds_name}-read-replica"
# })
# }