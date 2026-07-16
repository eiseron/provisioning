locals {
  labels       = { "app.kubernetes.io/name" = var.name }
  router_hosts = concat([var.app_host], var.extra_hosts)
  router_rule  = join(" || ", [for h in local.router_hosts : "Host(`${h}`)"])
}

resource "kubernetes_namespace_v1" "app" {
  count = var.enable && var.manage_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "env" {
  count = var.enable ? 1 : 0

  metadata {
    name      = "${var.name}-env"
    namespace = var.namespace
  }

  type = "Opaque"
  data = var.env_secret
}

resource "kubernetes_deployment_v1" "app" {
  count = var.enable ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.labels
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "0"
        max_surge       = "1"
      }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        node_selector = var.node_selector

        container {
          name  = var.name
          image = var.image

          port {
            container_port = var.app_port
          }

          dynamic "env" {
            for_each = var.env_clear
            content {
              name  = env.key
              value = env.value
            }
          }

          env_from {
            secret_ref {
              name = "${var.name}-env"
            }
          }

          readiness_probe {
            http_get {
              path = var.healthcheck_path
              port = var.app_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].container[0].image]
  }
}

resource "kubernetes_service_v1" "app" {
  count = var.enable ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = local.labels

    port {
      port        = var.app_port
      target_port = var.app_port
    }

    type = "ClusterIP"
  }
}

resource "kubectl_manifest" "ingressroute" {
  count = var.enable ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      entryPoints = [var.entrypoint]
      routes = [
        {
          match = local.router_rule
          kind  = "Rule"
          services = [
            {
              name = var.name
              port = var.app_port
            }
          ]
        }
      ]
      tls = {
        certResolver = var.cert_resolver
      }
    }
  })
}

resource "kubernetes_network_policy_v1" "app" {
  count = var.enable ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = local.labels
    }

    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = var.app_port
        protocol = "TCP"
      }
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
    }
  }
}
