terraform {
  backend "s3" {
    bucket       = "lerkasan-gitlab-setup-terraform-state"
    key          = "infra/main.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}