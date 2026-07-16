locals {
  traefik_values = {
    certificatesResolvers = {
      cf = {
        acme = merge(
          {
            email   = var.acme_email
            storage = "/data/acme.json"
            dnsChallenge = {
              provider  = "cloudflare"
              resolvers = ["1.1.1.1:53", "8.8.8.8:53"]
            }
          },
          var.acme_use_staging ? { caServer = "https://acme-staging-v02.api.letsencrypt.org/directory" } : {},
        )
      }
    }
    env = [
      {
        name = "CF_DNS_API_TOKEN"
        valueFrom = {
          secretKeyRef = {
            name = "cloudflare-dns-token"
            key  = "token"
          }
        }
      }
    ]
    ports = {
      websecure = {
        tls = {
          certResolver = "cf"
          domains      = [for d in var.acme_domains : { main = d, sans = ["*.${d}"] }]
        }
      }
    }
    persistence = {
      enabled      = true
      storageClass = "local-path"
      accessMode   = "ReadWriteOnce"
      size         = var.acme_storage_size
      path         = "/data"
    }
    podSecurityContext = {
      fsGroup             = 65532
      fsGroupChangePolicy = "OnRootMismatch"
    }
  }
}

resource "kubernetes_namespace_v1" "platform" {
  count = var.enable ? 1 : 0

  metadata {
    name = var.platform_namespace
  }
}

resource "kubernetes_secret_v1" "cf_dns_token" {
  count = var.enable ? 1 : 0

  metadata {
    name      = "cloudflare-dns-token"
    namespace = "kube-system"
  }

  type = "Opaque"

  data = {
    token = var.cloudflare_dns_api_token
  }
}

resource "kubernetes_manifest" "traefik" {
  count = var.enable ? 1 : 0

  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"
    metadata = {
      name      = "traefik"
      namespace = "kube-system"
    }
    spec = {
      valuesContent = yamlencode(local.traefik_values)
    }
  }
}
