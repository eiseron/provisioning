locals {
  otel_config = file("${path.module}/config/otel-collector.yaml")

  openobserve_static_env = {
    ZO_HTTP_PORT                   = tostring(var.http_port)
    ZO_LOCAL_MODE                  = "true"
    ZO_LOCAL_MODE_STORAGE          = "s3"
    ZO_S3_PROVIDER                 = "s3"
    ZO_S3_REGION_NAME              = "auto"
    ZO_S3_FEATURE_FORCE_PATH_STYLE = "true"
    ZO_TELEMETRY                   = "false"
    ZO_DATA_DIR                    = "/data"
  }

  openobserve_env = merge(local.openobserve_static_env, var.env_clear, var.env_secret)

  collector_env = {
    OBSERVABILITY_OTLP_ENDPOINT   = "http://${var.service_name}:${var.http_port}/api/${var.otlp_org}"
    OBSERVABILITY_OTLP_ORG        = var.otlp_org
    OBSERVABILITY_NODE_TARGET     = "${var.node_exporter_service_name}:9100"
    OBSERVABILITY_CADVISOR_TARGET = "${var.cadvisor_service_name}:8080"
    OBSERVABILITY_POSTGRES_TARGET = "${var.postgres_exporter_service_name}:9187"
  }

  dashboard_labels = {
    "traefik.enable"        = "true"
    "traefik.swarm.network" = var.traefik_network_name

    "traefik.http.routers.${var.service_name}.rule"        = "Host(`${var.dashboard_host}`)"
    "traefik.http.routers.${var.service_name}.entrypoints" = var.entrypoint
    "traefik.http.routers.${var.service_name}.tls"         = "true"

    "traefik.http.services.${var.service_name}.loadbalancer.server.port"          = tostring(var.http_port)
    "traefik.http.services.${var.service_name}.loadbalancer.healthcheck.path"     = var.healthcheck_path
    "traefik.http.services.${var.service_name}.loadbalancer.healthcheck.interval" = var.healthcheck_interval
  }
}

resource "docker_config" "otel_collector" {
  count = var.enable ? 1 : 0
  name  = "otel-collector-${substr(sha256(local.otel_config), 0, 12)}"
  data  = base64encode(local.otel_config)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_secret" "otlp_auth" {
  count = var.enable ? 1 : 0
  name  = "otlp-auth-${substr(sha256(var.otlp_auth), 0, 12)}"
  data  = base64encode(var.otlp_auth)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_secret" "postgres_exporter_pass" {
  count = var.enable ? 1 : 0
  name  = "postgres-exporter-pass-${substr(sha256(var.postgres_exporter_password), 0, 12)}"
  data  = base64encode(var.postgres_exporter_password)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_service" "openobserve" {
  count = var.enable ? 1 : 0
  name  = var.service_name

  task_spec {
    container_spec {
      image = var.observability_image
      env   = local.openobserve_env

      mounts {
        target = "/data"
        source = var.data_path
        type   = "bind"
      }
    }

    networks_advanced {
      name = var.internal_network_id
    }

    networks_advanced {
      name = var.traefik_network_id
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

  dynamic "labels" {
    for_each = local.dashboard_labels
    content {
      label = labels.key
      value = labels.value
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

  converge_config {
    delay   = "7s"
    timeout = "5m"
  }
}

resource "docker_service" "collector" {
  count = var.enable ? 1 : 0
  name  = var.collector_service_name

  task_spec {
    container_spec {
      image = var.collector_image
      args  = ["--config=/etc/otelcol-contrib/config.yaml"]
      env   = local.collector_env

      configs {
        config_id   = docker_config.otel_collector[0].id
        config_name = docker_config.otel_collector[0].name
        file_name   = "/etc/otelcol-contrib/config.yaml"
      }

      secrets {
        secret_id   = docker_secret.otlp_auth[0].id
        secret_name = docker_secret.otlp_auth[0].name
        file_name   = "/run/secrets/otlp_auth"
      }
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

  converge_config {
    delay   = "7s"
    timeout = "5m"
  }
}

resource "docker_service" "node_exporter" {
  count = var.enable ? 1 : 0
  name  = var.node_exporter_service_name

  task_spec {
    container_spec {
      image = var.node_exporter_image
      args = [
        "--path.procfs=/host/proc",
        "--path.sysfs=/host/sys",
        "--path.rootfs=/host/root",
        "--collector.filesystem.mount-points-exclude=^/host",
      ]

      mounts {
        target    = "/host/proc"
        source    = "/proc"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/host/sys"
        source    = "/sys"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/host/root"
        source    = "/"
        type      = "bind"
        read_only = true

        bind_options {
          propagation = "rslave"
        }
      }
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
    global = true
  }

  update_config {
    order          = "stop-first"
    failure_action = "pause"
    monitor        = "10s"
    delay          = "5s"
  }
}

resource "docker_service" "cadvisor" {
  count = var.enable ? 1 : 0
  name  = var.cadvisor_service_name

  task_spec {
    container_spec {
      image   = var.cadvisor_image
      cap_add = ["SYS_PTRACE"]

      mounts {
        target    = "/rootfs"
        source    = "/"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/var/run"
        source    = "/var/run"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/sys"
        source    = "/sys"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/var/lib/docker"
        source    = "/var/lib/docker"
        type      = "bind"
        read_only = true
      }

      mounts {
        target    = "/dev/disk"
        source    = "/dev/disk"
        type      = "bind"
        read_only = true
      }
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
    global = true
  }

  update_config {
    order          = "stop-first"
    failure_action = "pause"
    monitor        = "10s"
    delay          = "5s"
  }
}

resource "docker_service" "postgres_exporter" {
  count = var.enable ? 1 : 0
  name  = var.postgres_exporter_service_name

  task_spec {
    container_spec {
      image = var.postgres_exporter_image

      env = {
        DATA_SOURCE_URI       = var.postgres_exporter_uri
        DATA_SOURCE_USER      = var.postgres_exporter_user
        DATA_SOURCE_PASS_FILE = "/run/secrets/postgres_exporter_pass"
      }

      secrets {
        secret_id   = docker_secret.postgres_exporter_pass[0].id
        secret_name = docker_secret.postgres_exporter_pass[0].name
        file_name   = "/run/secrets/postgres_exporter_pass"
      }
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

  converge_config {
    delay   = "7s"
    timeout = "5m"
  }
}
