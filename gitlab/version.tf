terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.1.1"
    }
  }
  required_version = "~> 1.12.0"
}