terraform {
  required_version = ">= 1.14.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
      # keyserver = a separate Hetzner project/token for the Tang host, so a
      # leak of the prod token can snapshot the (LUKS) disk but not reach the
      # key server — the two-credential property of at-rest encryption.
      configuration_aliases = [hcloud.keyserver]
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
