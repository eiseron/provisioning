terraform {
  required_version = ">= 1.6"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 18.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }
}
