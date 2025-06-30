data "aws_region" "current" {}

# ------------------- User data for cloud-init --------------------------
data "cloudinit_config" "user_data_gitlab" {
  for_each = { for ec2 in var.ec2_appservers : coalesce(ec2.tags["Name"], "noname") => ec2 }

  base64_encode = true
  gzip          = true

  dynamic "part" {
    for_each = each.value.userdata_config != null ? [1] : []

    content {
      content_type = "text/cloud-config"
      content = yamlencode({
        "write_files" = [
          {
            "path"        = "/etc/gitlab/gitlab.rb.template"
            "permissions" = "0600"
            "owner"       = "root:root"
            "content" = templatefile("${path.root}/templates/gitlab/server/gitlab_rb.tftpl", {
              vpc_cidr                      = each.value.userdata_config.vpc_cidr,
              region                        = data.aws_region.current.name,
              domain_name                   = each.value.userdata_config.domain_name,
              external_loadbalancer_enabled = each.value.userdata_config.external_loadbalancer_enabled,
              external_postgres_enabled     = each.value.userdata_config.external_postgres_enabled,
              external_redis_enabled        = each.value.userdata_config.external_redis_enabled,
              registry_enabled              = each.value.userdata_config.registry_enabled,
              registry_s3_storage_enabled   = each.value.userdata_config.registry_s3_storage_enabled,
              registry_s3_bucket            = each.value.userdata_config.registry_s3_storage_enabled ? each.value.userdata_config.registry_s3_bucket : null,
              obj_store_s3_enabled          = each.value.userdata_config.obj_store_s3_enabled,
              obj_store_s3_bucket_prefix    = each.value.userdata_config.obj_store_s3_bucket_prefix,
              db_adapter                    = each.value.userdata_config.db_adapter,
              db_host                       = each.value.userdata_config.db_host,
              db_port                       = each.value.userdata_config.db_port,
              db_name                       = each.value.userdata_config.db_name,
              db_username                   = each.value.userdata_config.db_username,
              redis_host                    = each.value.userdata_config.redis_host,
              redis_port                    = each.value.userdata_config.redis_port
            })
          },
          {
            "path"        = "/tmp/install_gitlab.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.root}/templates/gitlab/server/install_gitlab_sh.tftpl", {
              region         = data.aws_region.current.name
              gitlab_version = each.value.userdata_config.gitlab_version
            })
          }
        ]
        }
      )
    }
  }

  dynamic "part" {
    for_each = each.value.userdata_config != null ? [1] : []

    content {
      content_type = "text/cloud-config"
      content = templatefile("${path.root}/templates/gitlab/userdata.tftpl", {
        install_gitlab        = can(each.value.userdata_config.install_gitlab) ? each.value.userdata_config.install_gitlab : false,
        install_gitlab_runner = can(each.value.userdata_config.install_gitlab_runner) ? each.value.userdata_config.install_gitlab_runner : false,
      })
    }
  }
}

# ------------------- User data for cloud-init --------------------------
data "cloudinit_config" "user_data_gitlab_runner" {
  for_each = { for ec2 in var.ec2_runners : coalesce(ec2.tags["Name"], "noname") => ec2 }

  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = each.value.userdata_config != null ? [1] : []

    content {
      content_type = "text/cloud-config"
      content = yamlencode({
        "write_files" = [
          {
            "path"        = "/tmp/install_docker.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.root}/templates/gitlab/runner/install_docker_sh.tftpl", {
              docker_version = each.value.userdata_config.docker_version
            })
          },
          {
            "path"        = "/tmp/add_gitlab_runner.sh"
            "permissions" = "0700"
            "owner"       = "root:root"
            "content" = templatefile("${path.root}/templates/gitlab/runner/add_gitlab_runner_sh.tftpl", {
              region                = data.aws_region.current.name,
              domain_name           = each.value.userdata_config.domain_name,
              gitlab_runner_version = each.value.userdata_config.gitlab_runner_version
              docker_image          = each.value.userdata_config.docker_image,
            })
          },
          {
            "path"        = "/etc/gitlab-runner/config.toml"
            "permissions" = "0600"
            "owner"       = "root:root"
            "content" = templatefile("${path.root}/templates/gitlab/runner/runner_config_toml.tftpl", {
              concurrent         = each.value.userdata_config.concurrent,
              check_interval     = each.value.userdata_config.check_interval,
              connection_max_age = each.value.userdata_config.connection_max_age
              shutdown_timeout   = each.value.userdata_config.shutdown_timeout,
              session_timeout    = each.value.userdata_config.session_timeout,
            })
          }
        ]
        }
      )
    }
  }

  dynamic "part" {
    for_each = each.value.userdata_config != null ? [1] : []

    content {
      content_type = "text/cloud-config"
      content = templatefile("${path.root}/templates/gitlab/userdata.tftpl", {
        install_gitlab        = can(each.value.userdata_config.install_gitlab) ? each.value.userdata_config.install_gitlab : false,
        install_gitlab_runner = can(each.value.userdata_config.install_gitlab_runner) ? each.value.userdata_config.install_gitlab_runner : false
      })
    }
  }
}