terraform {
  backend "s3" {
    bucket       = "lerkasan-gitlab-setup-terraform-state"
    key          = "gitlab/gitlab.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}