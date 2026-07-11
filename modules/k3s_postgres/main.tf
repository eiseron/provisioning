locals {
  backup_enabled = var.enable && var.backup.enabled

  cluster_backup = local.backup_enabled ? {
    barmanObjectStore = {
      destinationPath = var.backup.destination_path
      endpointURL     = var.backup.endpoint_url
      s3Credentials = {
        accessKeyId = {
          name = "${var.cluster_name}-backup-r2"
          key  = "ACCESS_KEY_ID"
        }
        secretAccessKey = {
          name = "${var.cluster_name}-backup-r2"
          key  = "SECRET_ACCESS_KEY"
        }
      }
      wal = {
        compression = "gzip"
      }
    }
  } : null

  cluster_spec = {
    instances = var.instances
    imageName = var.postgres_image

    storage = {
      size         = var.storage_size
      storageClass = var.storage_class
    }

    bootstrap = {
      initdb = {
        database = "postgres"
        owner    = var.superuser_username
      }
    }

    superuserSecret = {
      name = "${var.cluster_name}-superuser"
    }

    enableSuperuserAccess = true

    backup = local.cluster_backup
  }
}

resource "helm_release" "cnpg_operator" {
  count = var.enable ? 1 : 0

  name             = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = var.operator_chart_version
  namespace        = var.operator_namespace
  create_namespace = true
  atomic           = true
}

resource "kubernetes_secret_v1" "superuser" {
  count = var.enable ? 1 : 0

  metadata {
    name      = "${var.cluster_name}-superuser"
    namespace = var.namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.superuser_username
    password = var.superuser_password
  }
}

resource "kubernetes_secret_v1" "backup_r2" {
  count = local.backup_enabled ? 1 : 0

  metadata {
    name      = "${var.cluster_name}-backup-r2"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    ACCESS_KEY_ID     = var.backup.access_key_id
    SECRET_ACCESS_KEY = var.backup.secret_access_key
  }
}

resource "kubernetes_manifest" "cluster" {
  count = var.enable ? 1 : 0

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.cluster_name
      namespace = var.namespace
    }
    spec = local.cluster_spec
  }

  depends_on = [helm_release.cnpg_operator]
}
