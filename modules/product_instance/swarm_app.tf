data "docker_network" "traefik" {
  count = local.swarm_enabled ? 1 : 0
  name  = "traefik"
}

data "docker_network" "internal" {
  count = local.swarm_enabled ? 1 : 0
  name  = "internal"
}

locals {
  swarm_enabled = var.runtime.enable && local.prod_enabled

  swarm_database_url = "ecto://${var.slug}:${urlencode(var.db_tenant_password)}@platform-db/${var.slug}_prod"

  swarm_env_clear = merge(
    {
      PHX_HOST                    = var.runtime.app_host
      PORT                        = "4000"
      PHX_SERVER                  = "true"
      POOL_SIZE                   = "10"
      OBSERVABILITY_OTLP_ENDPOINT = var.runtime.observability_otlp_endpoint
    },
    var.runtime.admin_access_issuer == "" ? {} : { ADMIN_ACCESS_ISSUER = var.runtime.admin_access_issuer },
    var.runtime.admin_access_certs_url == "" ? {} : { ADMIN_ACCESS_CERTS_URL = var.runtime.admin_access_certs_url },
  )

  swarm_env_secret = merge(
    {
      SECRET_KEY_BASE = local.prod_enabled ? random_password.secret_key_base[0].result : ""
      DATABASE_URL    = local.swarm_database_url
    },
    var.runtime.admin_access_audiences == "" ? {} : { ADMIN_ACCESS_AUDIENCES = var.runtime.admin_access_audiences },
  )
}

module "swarm_app" {
  source = "../swarm_app"

  providers = {
    docker = docker
  }

  enable       = local.swarm_enabled
  service_name = var.slug
  app_image    = var.runtime.app_image
  app_host     = var.runtime.app_host

  traefik_network_id  = local.swarm_enabled ? data.docker_network.traefik[0].id : ""
  internal_network_id = local.swarm_enabled ? data.docker_network.internal[0].id : ""

  env_clear  = local.swarm_env_clear
  env_secret = local.swarm_env_secret

  placement_constraints = var.runtime.placement_constraints
}
