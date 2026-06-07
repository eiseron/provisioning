terraform {
  required_version = ">= 1.14.0"

  required_providers {
    hostinger = {
      source  = "hostinger/hostinger"
      version = "~> 0.1.0"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
