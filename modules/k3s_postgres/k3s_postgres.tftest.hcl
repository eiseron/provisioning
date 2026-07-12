mock_provider "kubernetes" {}
mock_provider "helm" {}

variables {
  enable             = true
  superuser_password = "test-only-placeholder"
}

run "seed_disabled_uses_initdb" {
  command = plan

  assert {
    condition     = can(kubernetes_manifest.cluster[0].manifest.spec.bootstrap.initdb)
    error_message = "Default cluster must bootstrap with initdb"
  }

  assert {
    condition     = !can(kubernetes_manifest.cluster[0].manifest.spec.replica)
    error_message = "Default cluster must not set spec.replica"
  }

  assert {
    condition     = !can(kubernetes_manifest.cluster[0].manifest.spec.externalClusters)
    error_message = "Default cluster must not set externalClusters"
  }

  assert {
    condition     = length(kubernetes_secret_v1.seed_source) == 0
    error_message = "Default cluster must not create the seed_source secret"
  }
}

run "seed_streaming_bootstraps_replica" {
  command = plan

  variables {
    seed = {
      enable            = true
      mode              = "streaming"
      host              = "app-external-db.internal"
      port              = 5432
      database          = "app"
      external_username = "app"
      external_password = "test-only-placeholder"
    }
  }

  assert {
    condition     = can(kubernetes_manifest.cluster[0].manifest.spec.bootstrap.pg_basebackup)
    error_message = "Streaming seed must bootstrap with pg_basebackup"
  }

  assert {
    condition     = kubernetes_manifest.cluster[0].manifest.spec.replica.enabled == true
    error_message = "Streaming seed must set replica.enabled = true"
  }

  assert {
    condition     = length(kubernetes_manifest.cluster[0].manifest.spec.externalClusters) == 1
    error_message = "Streaming seed must declare one externalClusters entry"
  }

  assert {
    condition     = length(kubernetes_secret_v1.seed_source) == 1
    error_message = "Streaming seed must create the seed_source secret"
  }
}

run "seed_recovery_bootstraps_from_backup" {
  command = plan

  variables {
    backup = {
      enabled           = true
      endpoint_url      = "https://acct.r2.cloudflarestorage.com"
      destination_path  = "s3://acme-backups/platform-db"
      access_key_id     = "test-only"
      secret_access_key = "test-only"
    }
    seed = {
      enable = true
      mode   = "recovery"
    }
  }

  assert {
    condition     = can(kubernetes_manifest.cluster[0].manifest.spec.bootstrap.recovery)
    error_message = "Recovery seed must bootstrap with recovery"
  }

  assert {
    condition     = !can(kubernetes_manifest.cluster[0].manifest.spec.replica)
    error_message = "Recovery seed must not set spec.replica"
  }

  assert {
    condition     = can(kubernetes_manifest.cluster[0].manifest.spec.externalClusters[0].barmanObjectStore)
    error_message = "Recovery seed externalClusters must carry the barmanObjectStore"
  }
}
