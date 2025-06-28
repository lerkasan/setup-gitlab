resource "gitlab_user" "admin_account" {
  name             = var.admin_name
  email            = var.admin_email
  username         = var.admin_username
  password         = var.admin_password
#   force_random_password = true
#   reset_password   = true

  is_admin         = true
  can_create_group = true
  is_external      = false
  projects_limit   = 1000
}

resource "gitlab_project" "first" {
  name = "first"
  description = "My internal test project in GitLab EE"
  visibility_level = "internal"

  tags = [
    "terraform",
    "gitlab",
    "infrastructure",
    "test"
  ]
}
