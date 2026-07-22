terraform {
  required_version = ">= 1.7.0"

  required_providers {
    hcloud = {
      source                = "hetznercloud/hcloud"
      version               = "~> 1.0"
      configuration_aliases = [hcloud.production, hcloud.keyserver]
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 18.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
