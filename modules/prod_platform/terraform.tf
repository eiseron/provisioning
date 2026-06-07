terraform {
  required_version = ">= 1.14.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
      # Two separate Hetzner projects/tokens, injected by the caller:
      #   production = the prod host (isolated from the more-exposed default
      #               token that runs the runner/preview pipelines);
      #   keyserver  = the Tang host (so a leak of the prod token can snapshot
      #               the LUKS disk but cannot reach the key — two-credential
      #               at-rest encryption).
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
  }
}
