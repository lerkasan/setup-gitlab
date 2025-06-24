module "vpc" {
  for_each = { for vpc in var.vpcs : vpc.cidr_block => vpc }

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
  os                                     = each.value.os
  os_product                             = each.value.os_product
  os_architecture                        = each.value.os_architecture
  os_version                             = each.value.os_version
  os_releases                            = each.value.os_releases
  ami_virtualization                     = each.value.ami_virtualization
  ami_architectures                      = each.value.ami_architectures
  ami_owner_ids                          = each.value.ami_owner_ids
  tags                                   = each.value.tags
}

module "appserver" {
  for_each = { for ec2 in var.ec2_appservers : coalesce(ec2.tags["Name"], "noname") => ec2 }

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
  enable_bastion_access                  = each.value.enable_bastion_access
  bastion_security_group_id              = module.bastion[each.value.bastion_name].security_group_id
  enable_ec2_instance_connect_endpoint   = each.value.enable_ec2_instance_connect_endpoint
  ec2_connect_endpoint_security_group_id = module.ec2_instance_connect_endpoint[each.value.vpc_cidr].security_group_id
  os                                     = each.value.os
  os_product                             = each.value.os_product
  os_architecture                        = each.value.os_architecture
  os_version                             = each.value.os_version
  os_releases                            = each.value.os_releases
  ami_virtualization                     = each.value.ami_virtualization
  ami_architectures                      = each.value.ami_architectures
  ami_owner_ids                          = each.value.ami_owner_ids
  tags                                   = each.value.tags
}

module "s3_bucket" {
  for_each = { for bucket in var.s3_buckets : bucket.name => bucket }

  source = "./modules/s3"

  bucket_name         = each.value.name
  enable_encryption   = each.value.enable_encryption
  enable_logging      = each.value.enable_logging
  logging_bucket_name = each.value.logging_bucket_name
  versioning_status   = each.value.versioning_status
  lifecycle_rule      = each.value.lifecycle_rule
}

module "loadbalancer" {
  for_each = { for lb in var.load_balancers : lb.lb_name => lb }

  source = "./modules/loadbalancer"

  lb_name           = each.value.lb_name
  lb_type           = each.value.lb_type
  lb_internal       = each.value.lb_internal
  domain_name       = each.value.domain_name
  vpc_id            = module.vpc[each.value.vpc_cidr].vpc_id
  public_subnet_ids = [for subnet in module.vpc[each.value.vpc_cidr].public_subnets : subnet.id]
  # public_subnet_ids          = module.vpc[each.value.vpc_cidr].public_subnets[*].id  
  target_groups              = each.value.target_groups
  listeners                  = each.value.listeners
  lb_access_logs_bucket_name = each.value.lb_access_logs_bucket_name

  tags = each.value.tags

  # Ensure the S3 bucket for access logs is created before the load balancer
  depends_on = [module.s3_bucket]
}



