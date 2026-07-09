locals {
  traefik_config = templatefile("${path.module}/templates/traefik.yml.tftpl", {
    log_level            = var.log_level
    acme_email           = var.acme_email
    acme_domains         = var.acme_domains
    acme_use_staging     = var.acme_use_staging
    traefik_network_name = var.traefik_network_name
  })
}

resource "docker_network" "traefik" {
  count      = var.enable ? 1 : 0
  name       = var.traefik_network_name
  driver     = "overlay"
  attachable = true
}

resource "docker_network" "internal" {
  count      = var.enable ? 1 : 0
  name       = var.internal_network_name
  driver     = "overlay"
  attachable = true
}

resource "docker_volume" "traefik_acme" {
  count = var.enable ? 1 : 0
  name  = var.acme_volume_name
}

resource "docker_config" "traefik" {
  count = var.enable ? 1 : 0
  name  = "traefik-${substr(sha256(local.traefik_config), 0, 12)}"
  data  = base64encode(local.traefik_config)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_secret" "cf_dns_api_token" {
  count = var.enable ? 1 : 0
  name  = "cf-dns-api-token-${substr(sha256(var.acme_cf_dns_api_token), 0, 12)}"
  data  = base64encode(var.acme_cf_dns_api_token)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_service" "traefik" {
  count = var.enable ? 1 : 0
  name  = "traefik"

  task_spec {
    container_spec {
      image = var.traefik_image
      args  = ["--configfile=/etc/traefik/traefik.yml"]

      env = {
        CF_DNS_API_TOKEN_FILE = "/run/secrets/cf_dns_api_token"
      }

      configs {
        config_id   = docker_config.traefik[0].id
        config_name = docker_config.traefik[0].name
        file_name   = "/etc/traefik/traefik.yml"
      }

      secrets {
        secret_id   = docker_secret.cf_dns_api_token[0].id
        secret_name = docker_secret.cf_dns_api_token[0].name
        file_name   = "/run/secrets/cf_dns_api_token"
      }

      mounts {
        target    = "/var/run/docker.sock"
        source    = "/var/run/docker.sock"
        type      = "bind"
        read_only = true
      }

      mounts {
        target = "/acme"
        source = docker_volume.traefik_acme[0].name
        type   = "volume"
      }
    }

    networks_advanced {
      name = docker_network.traefik[0].id
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
      replicas = 1
    }
  }

  update_config {
    order          = "stop-first"
    failure_action = "rollback"
    monitor        = "10s"
    delay          = "5s"
  }

  rollback_config {
    order = "stop-first"
  }

  endpoint_spec {
    ports {
      target_port    = 80
      published_port = 80
      publish_mode   = "host"
    }

    ports {
      target_port    = 443
      published_port = 443
      publish_mode   = "host"
    }
  }

  converge_config {
    delay   = "7s"
    timeout = "5m"
  }
}
