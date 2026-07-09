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

module "swarm_app" {
  source = "../.."

  enable              = true
  service_name        = "validate-app"
  app_image           = "example/app@sha256:0000000000000000000000000000000000000000000000000000000000000000"
  app_host            = "app.example.test"
  traefik_network_id  = "validate-only-traefik-id"
  internal_network_id = "validate-only-internal-id"

  env_clear = {
    PHX_HOST = "app.example.test"
  }
  env_secret = {
    SECRET_KEY_BASE = "validate-only"
  }

  healthcheck_test = ["CMD", "/app/bin/app", "rpc", ":ok"]
}
