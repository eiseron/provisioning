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

module "swarm_postgres" {
  source = "../.."

  enable              = true
  internal_network_id = "validate-only-network-id"
  postgres_password   = "validate-only-placeholder"
}
