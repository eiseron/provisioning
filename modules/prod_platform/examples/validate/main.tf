# Validate-only fixture: prod_platform requires injected provider configs
# (hcloud + hcloud.keyserver via configuration_aliases), so it is not a valid
# root module on its own. This root supplies dummy providers so `terraform
# validate` can check the module's HCL in CI. The dummy tokens are only
# format-checked by the hcloud provider (hence 64 chars); no API is ever called.

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
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

provider "hcloud" {
  alias = "production"
  token = "0000000000000000000000000000000000000000000000000000000000000000"
}

provider "hcloud" {
  alias = "keyserver"
  token = "0000000000000000000000000000000000000000000000000000000000000000"
}

provider "gitlab" {
  token = "0000000000000000000000000000000000000000000000000000000000000000"
}

module "prod_platform" {
  source = "../.."

  providers = {
    hcloud.production = hcloud.production
    hcloud.keyserver  = hcloud.keyserver
  }

  ops_project_id = "0"
}
