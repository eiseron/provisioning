locals {
  backup_enabled = var.enable && var.backup.enabled

  seed_streaming = var.enable && var.seed.enable && var.seed.mode == "streaming"
  seed_recovery  = var.enable && var.seed.enable && var.seed.mode == "recovery"

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

  cluster_bootstrap = merge(
    local.seed_streaming ? {
      pg_basebackup = {
        source = var.seed.source_name
      }
    } : {},
    local.seed_recovery ? {
      recovery = {
        source = var.seed.source_name
      }
    } : {},
    (local.seed_streaming || local.seed_recovery) ? {} : {
      initdb = {
        database = "postgres"
        owner    = var.superuser_username
      }
    },
  )

  cluster_external_streaming = local.seed_streaming ? [
    {
      name = var.seed.source_name
      connectionParameters = {
        host   = var.seed.host
        port   = tostring(var.seed.port)
        dbname = var.seed.database
        user   = var.seed.external_username
      }
      password = {
        name = "${var.cluster_name}-seed-source"
        key  = "password"
      }
    }
  ] : null

  cluster_external_recovery = local.seed_recovery ? [
    {
      name              = var.seed.source_name
      barmanObjectStore = local.cluster_backup.barmanObjectStore
    }
  ] : null

  cluster_external_spec = merge(
    local.cluster_external_streaming == null ? {} : { externalClusters = local.cluster_external_streaming },
    local.cluster_external_recovery == null ? {} : { externalClusters = local.cluster_external_recovery },
  )

  cluster_replica = local.seed_streaming ? {
    enabled = true
    source  = var.seed.source_name
  } : null

  cluster_spec = merge(
    {
      instances = var.instances
      imageName = var.postgres_image

      storage = {
        size         = var.storage_size
        storageClass = var.storage_class
      }

      bootstrap = local.cluster_bootstrap

      superuserSecret = {
        name = "${var.cluster_name}-superuser"
      }

      enableSuperuserAccess = true

      backup = local.cluster_backup
    },
    local.cluster_external_spec,
    local.cluster_replica == null ? {} : { replica = local.cluster_replica },
  )
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

resource "kubernetes_secret_v1" "seed_source" {
  count = local.seed_streaming ? 1 : 0

  metadata {
    name      = "${var.cluster_name}-seed-source"
    namespace = var.namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.seed.external_username
    password = sensitive(var.seed.external_password)
  }
}

resource "kubectl_manifest" "cluster" {
  count = var.enable ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.cluster_name
      namespace = var.namespace
    }
    spec = local.cluster_spec
  })

  depends_on = [helm_release.cnpg_operator]
}
