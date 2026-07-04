terraform {
  required_version = ">= 1.7.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
}
