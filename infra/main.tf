module "vpc" {
  for_each = { for vpc in var.vpc_networks : vpc.cidr_block => vpc }

  source = "./modules/vpc"

  vpc_name                 = each.value.name
  cidr_block               = each.value.cidr_block
  public_subnets           = each.value.public_subnets
  private_subnets          = each.value.private_subnets
  enable_dns_hostnames     = each.value.enable_dns_hostnames
  enable_dns_support       = each.value.enable_dns_support
  enable_flow_logs         = each.value.enable_flow_logs
  flow_logs_retention_days = each.value.flow_logs_retention_days
  tags                     = each.value.tags
}

module "ec2_instance_connect_endpoint" {
  for_each = { for endpoint in var.ec2_instance_connect_endpoints : endpoint.vpc_cidr => endpoint }

  source = "./modules/ec2_instance_connect_endpoint"

  vpc_id           = module.vpc[each.key].vpc_id
  subnet_id        = module.vpc[each.key].subnets[each.value.subnet_cidr].id
  admin_public_ips = var.admin_public_ips
  tags             = each.value.tags
}

module "bastion" {
  for_each = { for ec2 in var.ec2_bastions : coalesce(ec2.tags["Name"], "noname") => ec2 }

  source = "./modules/ec2"

  ec2_instance_type                      = each.value.ec2_instance_type
  vpc_id                                 = module.vpc[each.value.vpc_cidr].vpc_id
  subnet_id                              = module.vpc[each.value.vpc_cidr].subnets[each.value.subnet_cidr].id
  associate_public_ip_address            = each.value.associate_public_ip_address
  volume_type                            = each.value.volume_type
  volume_size                            = each.value.volume_size
  delete_on_termination                  = each.value.delete_on_termination
  private_ssh_key_name                   = each.value.private_ssh_key_name
  admin_public_ssh_key_names             = each.value.admin_public_ssh_key_names
  admin_public_ips                       = var.admin_public_ips
  enable_ec2_instance_connect_endpoint   = each.value.enable_ec2_instance_connect_endpoint
  ec2_connect_endpoint_security_group_id = module.ec2_instance_connect_endpoint[each.value.vpc_cidr].security_group_id

  ami_id             = each.value.ami_id
  os                 = each.value.os
  os_product         = each.value.os_product
  os_architecture    = each.value.os_architecture
  os_version         = each.value.os_version
  os_releases        = each.value.os_releases
  ami_virtualization = each.value.ami_virtualization
  ami_architectures  = each.value.ami_architectures
  ami_owner_ids      = each.value.ami_owner_ids
  tags               = each.value.tags
}

module "appserver" {
  for_each = { for ec2 in var.ec2_appservers : coalesce(ec2.tags["Name"], "noname") => ec2 }

  source = "./modules/ec2"

  ec2_instance_type             = each.value.ec2_instance_type
  vpc_id                        = module.vpc[each.value.vpc_cidr].vpc_id
  subnet_id                     = module.vpc[each.value.vpc_cidr].subnets[each.value.subnet_cidr].id
  associate_public_ip_address   = each.value.associate_public_ip_address
  additional_security_group_ids = [aws_security_group.additional_sg_for_appserver[each.key].id]
  volume_type                   = each.value.volume_type
  volume_size                   = each.value.volume_size
  delete_on_termination         = each.value.delete_on_termination
  private_ssh_key_name          = each.value.private_ssh_key_name
  admin_public_ssh_key_names    = each.value.admin_public_ssh_key_names

  ami_id                = each.value.ami_id
  os                    = each.value.os
  os_product            = each.value.os_product
  os_architecture       = each.value.os_architecture
  os_version            = each.value.os_version
  os_releases           = each.value.os_releases
  ami_virtualization    = each.value.ami_virtualization
  ami_architectures     = each.value.ami_architectures
  ami_owner_ids         = each.value.ami_owner_ids
  iam_policy_statements = each.value.iam_policy_statements

  enable_bastion_access     = each.value.enable_bastion_access
  bastion_security_group_id = module.bastion[each.value.bastion_name].security_group_id

  enable_ec2_instance_connect_endpoint   = each.value.enable_ec2_instance_connect_endpoint
  ec2_connect_endpoint_security_group_id = module.ec2_instance_connect_endpoint[each.value.vpc_cidr].security_group_id

  additional_policy_arns = [module.rds["gitlab"].policy_arn_for_access_to_ssm_params_and_secrets]

  user_data       = data.cloudinit_config.user_data_gitlab[each.key].rendered
  userdata_config = each.value.userdata_config

  attach_to_target_group = true
  target_group_arns = {
    "gitlab-alb-http-target" = module.loadbalancer["gitlab-alb"].target_groups["gitlab-alb-http-target"].arn,
    "gitlab-nlb-ssh-target"  = module.loadbalancer["gitlab-nlb"].target_groups["gitlab-nlb-ssh-target"].arn
  }

  tags = each.value.tags

  # Dependencies ensure that user data scripts of EC2 instances can access the necessary RDS, Elasticache and other resources 
  depends_on = [
    module.loadbalancer,
    module.rds,
    module.elasticache
  ]
}

module "s3_bucket" {
  for_each = { for bucket in var.s3_buckets : bucket.name => bucket }

  source = "./modules/s3"

  bucket_name         = each.value.name
  enable_encryption   = each.value.enable_encryption
  bucket_key_enabled  = each.value.bucket_key_enabled
  enable_logging      = each.value.enable_logging
  logging_bucket_name = each.value.logging_bucket_name
  versioning_status   = each.value.versioning_status
  lifecycle_rule      = each.value.lifecycle_rule
}

module "loadbalancer" {
  for_each = { for lb in var.load_balancers : lb.lb_name => lb }

  source = "./modules/loadbalancer"

  lb_name     = each.value.lb_name
  lb_type     = each.value.lb_type
  lb_internal = each.value.lb_internal
  domain_name = each.value.domain_name
  subdomains  = each.value.subdomains

  target_groups              = each.value.target_groups
  listeners                  = each.value.listeners
  ssh_cidrs                  = each.value.ssh_cidrs
  lb_access_logs_bucket_name = each.value.lb_access_logs_bucket_name

  vpc_id     = module.vpc[each.value.vpc_cidr].vpc_id
  subnet_ids = each.value.lb_internal ? [for subnet in module.vpc[each.value.vpc_cidr].private_subnets : subnet.id] : [for subnet in module.vpc[each.value.vpc_cidr].public_subnets : subnet.id]

  add_security_rules_for_appserver = true
  appserver_sg_id                  = aws_security_group.additional_sg_for_appserver["GitLabServer"].id

  member_of_target_groups = each.value.member_of_target_groups

  tags = each.value.tags

  # Ensure the S3 bucket for access logs is created before the load balancer
  depends_on = [module.s3_bucket]
}

module "rds" {
  for_each = { for rds in var.rds_instances : rds.rds_name => rds }

  source = "./modules/rds"

  rds_name                         = each.value.rds_name
  database_instance_class          = each.value.db_instance_class
  database_engine                  = each.value.db_engine
  database_engine_version          = each.value.db_engine_version
  database_storage_type            = each.value.db_instance_storage_type
  database_allocated_storage       = each.value.db_allocated_storage
  database_max_allocated_storage   = each.value.db_max_allocated_storage
  database_backup_retention_period = each.value.db_backup_retention_period
  database_maintenance_window      = each.value.db_maintenance_window

  database_port     = each.value.db_port
  database_name     = each.value.db_name
  database_username = each.value.db_username

  vpc_id             = module.vpc[each.value.vpc_cidr].vpc_id
  private_subnet_ids = [for subnet in module.vpc[each.value.vpc_cidr].private_subnets : subnet.id]

  add_security_rules_for_appserver = true
  appserver_sg_id                  = aws_security_group.additional_sg_for_appserver["GitLabServer"].id

  tags = each.value.tags
}

module "elasticache" {
  for_each = { for cache in var.cache_instances : cache.cache_cluster_id => cache }

  source = "./modules/elasticache_cluster"

  cache_cluster_id               = each.value.cache_cluster_id
  cache_parameter_group_name     = each.value.cache_parameter_group_name
  cache_parameter_group_family   = each.value.cache_parameter_group_family
  cache_engine                   = each.value.cache_engine
  cache_engine_version           = each.value.cache_engine_version
  cache_node_type                = each.value.cache_node_type
  cache_num_nodes                = each.value.cache_num_nodes
  cache_port                     = each.value.cache_port
  cache_maintenance_window       = each.value.cache_maintenance_window
  cache_snapshot_window          = each.value.cache_snapshot_window
  cache_snapshot_retention_limit = each.value.cache_snapshot_retention_limit
  cache_log_group_name           = each.value.cache_log_group_name
  cache_log_retention_in_days    = each.value.cache_log_retention_in_days

  vpc_id             = module.vpc[each.value.vpc_cidr].vpc_id
  private_subnet_ids = [for subnet in module.vpc[each.value.vpc_cidr].private_subnets : subnet.id]

  add_security_rules_for_appserver = true
  appserver_sg_id                  = aws_security_group.additional_sg_for_appserver["GitLabServer"].id

  tags = each.value.tags
}

module "runner" {
  for_each = { for ec2 in var.ec2_runners : coalesce(ec2.tags["Name"], "noname") => ec2 }

  source = "./modules/ec2"

  ec2_instance_type           = each.value.ec2_instance_type
  vpc_id                      = module.vpc[each.value.vpc_cidr].vpc_id                             #
  subnet_id                   = module.vpc[each.value.vpc_cidr].subnets[each.value.subnet_cidr].id #
  associate_public_ip_address = each.value.associate_public_ip_address
  volume_type                 = each.value.volume_type
  volume_size                 = each.value.volume_size
  delete_on_termination       = each.value.delete_on_termination
  private_ssh_key_name        = each.value.private_ssh_key_name
  admin_public_ssh_key_names  = each.value.admin_public_ssh_key_names

  ami_id                = each.value.ami_id
  os                    = each.value.os
  os_product            = each.value.os_product
  os_architecture       = each.value.os_architecture
  os_version            = each.value.os_version
  os_releases           = each.value.os_releases
  ami_virtualization    = each.value.ami_virtualization
  ami_architectures     = each.value.ami_architectures
  ami_owner_ids         = each.value.ami_owner_ids
  iam_policy_statements = each.value.iam_policy_statements

  enable_bastion_access     = each.value.enable_bastion_access
  bastion_security_group_id = module.bastion[each.value.bastion_name].security_group_id

  enable_ec2_instance_connect_endpoint   = each.value.enable_ec2_instance_connect_endpoint
  ec2_connect_endpoint_security_group_id = module.ec2_instance_connect_endpoint[each.value.vpc_cidr].security_group_id

  user_data       = data.cloudinit_config.user_data_gitlab_runner[each.key].rendered
  userdata_config = each.value.userdata_config

  attach_to_target_group = false

  tags = each.value.tags

  # Dependencies ensure that user data scripts of EC2 instances can access appserver to send requests to GitLab API  
  depends_on = [
    module.appserver
  ]
}

# Attach the ALB to the NLB target group
resource "aws_lb_target_group_attachment" "this" {
  for_each = module.loadbalancer["gitlab-alb"].member_of_target_groups

  target_group_arn = module.loadbalancer["gitlab-nlb"].target_groups[each.value].arn
  target_id        = module.loadbalancer["gitlab-alb"].arn

  depends_on = [
    module.loadbalancer["gitlab-nlb"],
    module.loadbalancer["gitlab-alb"]
  ]
} 