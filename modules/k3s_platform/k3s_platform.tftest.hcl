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

run "traefik_acme_resolver_targets_the_domain_wildcard" {
  command = plan

  assert {
    condition     = yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).ports.websecure.tls.certResolver == "cf"
    error_message = "websecure must resolve certificates through the cf ACME resolver"
  }

  assert {
    condition     = contains(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).ports.websecure.tls.domains[0].sans, "*.example.test")
    error_message = "The entrypoint certificate must cover the domain wildcard"
  }

  assert {
    condition     = !can(yamldecode(kubernetes_manifest.traefik[0].manifest.spec.valuesContent).certificatesResolvers.cf.acme.caServer)
    error_message = "Production ACME must not point at the staging CA by default"
  }
}
