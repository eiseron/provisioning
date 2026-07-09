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

module "swarm_observability" {
  source = "../.."

  enable              = true
  observability_image = "registry.example.test/platform/observability@sha256:0000000000000000000000000000000000000000000000000000000000000000"
  internal_network_id = "validate-only-internal"
  traefik_network_id  = "validate-only-traefik"
  dashboard_host      = "observe.example.test"

  env_clear = {
    ZO_ROOT_USER_EMAIL = "root@example.test"
    ZO_S3_SERVER_URL   = "https://r2.example.test"
    ZO_S3_BUCKET_NAME  = "observability"
  }

  env_secret = {
    ZO_ROOT_USER_PASSWORD = "validate-only-placeholder"
    ZO_S3_ACCESS_KEY      = "validate-only-placeholder"
    ZO_S3_SECRET_KEY      = "validate-only-placeholder"
  }

  otlp_auth                  = "validate-only-placeholder"
  postgres_exporter_password = "validate-only-placeholder"
}
