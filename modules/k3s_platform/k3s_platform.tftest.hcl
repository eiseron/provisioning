mock_provider "kubernetes" {}

variables {
  enable                   = true
  acme_email               = "ops@example.test"
  acme_domains             = ["example.test"]
  cloudflare_dns_api_token = "validate-only"
}

run "traefik_acme_storage_is_writable_by_the_pod" {
  command = plan

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).podSecurityContext.fsGroup == 65532
    error_message = "The traefik values must set fsGroup 65532 so the persisted /data volume is writable and acme.json can be created"
  }

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).persistence.enabled == true
    error_message = "ACME storage persistence must stay enabled"
  }
}

run "traefik_acme_resolver_uses_the_chart_certResolvers_key" {
  command = plan

  assert {
    condition     = can(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf)
    error_message = "The resolver must live under the chart's certResolvers key (not the raw certificatesResolvers static-config key, which the helm chart ignores)"
  }

  assert {
    condition     = !can(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf.acme)
    error_message = "The resolver fields must sit directly under the resolver name; the chart adds the acme level itself"
  }

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf.dnsChallenge.provider == "cloudflare"
    error_message = "The cf resolver must use the cloudflare DNS-01 challenge"
  }

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf.storage == "/data/acme.json"
    error_message = "The resolver must persist acme.json on the mounted data volume"
  }

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).ports.websecure.tls.certResolver == "cf"
    error_message = "websecure must resolve certificates through the cf ACME resolver"
  }

  assert {
    condition     = contains(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).ports.websecure.tls.domains[0].sans, "*.example.test")
    error_message = "The entrypoint certificate must cover the domain wildcard"
  }

  assert {
    condition     = !can(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf.caServer)
    error_message = "Production ACME must not point at the staging CA by default"
  }
}

run "staging_flag_points_the_resolver_at_the_staging_ca" {
  command = plan

  variables {
    acme_use_staging = true
  }

  assert {
    condition     = strcontains(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certResolvers.cf.caServer, "acme-staging")
    error_message = "acme_use_staging must render the staging CA server on the resolver"
  }
}
