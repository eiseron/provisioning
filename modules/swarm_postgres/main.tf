resource "docker_secret" "postgres_password" {
  count = var.enable ? 1 : 0
  name  = "postgres-password-${substr(sha256(var.postgres_password), 0, 12)}"
  data  = base64encode(var.postgres_password)

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_service" "platform_db" {
  count = var.enable ? 1 : 0
  name  = var.service_name

  task_spec {
    container_spec {
      image = var.postgres_image

      env = {
        POSTGRES_DB            = "postgres"
        POSTGRES_USER          = var.pg_admin_user
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password"
        PGDATA                 = "/var/lib/postgresql/data/pgdata"
      }

      secrets {
        secret_id   = docker_secret.postgres_password[0].id
        secret_name = docker_secret.postgres_password[0].name
        file_name   = "/run/secrets/postgres_password"
      }

      mounts {
        target = "/var/lib/postgresql/data"
        source = var.data_path
        type   = "bind"
      }

      healthcheck {
        test         = ["CMD-SHELL", "pg_isready -U ${var.pg_admin_user} -d postgres || exit 1"]
        interval     = "10s"
        timeout      = "5s"
        retries      = 5
        start_period = "30s"
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
    delay   = "10s"
    timeout = "5m"
  }
}
