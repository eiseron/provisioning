locals {
  router_hosts = concat([var.app_host], var.extra_hosts)
  router_rule  = join(" || ", [for host in local.router_hosts : "Host(`${host}`)"])

  labels = {
    "traefik.enable"        = "true"
    "traefik.swarm.network" = var.traefik_network_name

    "traefik.http.routers.${var.service_name}.rule"        = local.router_rule
    "traefik.http.routers.${var.service_name}.entrypoints" = var.entrypoint
    "traefik.http.routers.${var.service_name}.tls"         = "true"

    "traefik.http.services.${var.service_name}.loadbalancer.server.port"          = tostring(var.app_port)
    "traefik.http.services.${var.service_name}.loadbalancer.healthcheck.path"     = var.healthcheck_path
    "traefik.http.services.${var.service_name}.loadbalancer.healthcheck.interval" = var.healthcheck_interval
  }

  env = merge(var.env_clear, var.env_secret)
}

resource "docker_service" "app" {
  count = var.enable ? 1 : 0
  name  = var.service_name

  task_spec {
    container_spec {
      image = var.app_image
      env   = local.env

      dynamic "healthcheck" {
        for_each = length(var.healthcheck_test) > 0 ? [1] : []
        content {
          test         = var.healthcheck_test
          interval     = var.healthcheck_interval
          timeout      = var.healthcheck_timeout
          retries      = var.healthcheck_retries
          start_period = var.healthcheck_start_period
        }
      }
    }

    networks_advanced {
      name = var.traefik_network_id
    }

    networks_advanced {
      name = var.internal_network_id
    }

    placement {
      constraints = var.placement_constraints

      platforms {
        architecture = "amd64"
        os           = "linux"
      }
    }
  }

  mode {
    replicated {
      replicas = var.replicas
    }
  }

  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  update_config {
    order          = "start-first"
    parallelism    = 1
    failure_action = "rollback"
    monitor        = "15s"
    delay          = "5s"
  }

  rollback_config {
    order       = "start-first"
    parallelism = 1
  }

  converge_config {
    delay   = "7s"
    timeout = "10m"
  }
}
