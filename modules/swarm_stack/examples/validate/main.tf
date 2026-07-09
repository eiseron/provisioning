terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

module "swarm_stack" {
  source = "../.."

  enable                = true
  acme_email            = "ops@example.test"
  acme_domains          = ["example.test"]
  acme_cf_dns_api_token = "validate-only-placeholder"
}
