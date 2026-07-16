mock_provider "kubernetes" {}
mock_provider "kubectl" {}

variables {
  enable    = true
  name      = "app"
  namespace = "acme-app"
  image     = "registry.example.test/acme/app/prod:v1.0.0"
  app_host  = "app.example.test"

  env_secret = {
    SECRET_KEY_BASE = "validate-only"
    DATABASE_URL    = "ecto://app:pw@platform-db-rw.platform/app_prod"
  }
}

run "manages_namespace_by_default" {
  command = plan

  assert {
    condition     = length(kubernetes_namespace_v1.app) == 1
    error_message = "The module must create the namespace by default"
  }

  assert {
    condition     = kubernetes_namespace_v1.app[0].metadata[0].name == var.namespace
    error_message = "The created namespace must be named var.namespace"
  }

  assert {
    condition     = kubernetes_deployment_v1.app[0].metadata[0].namespace == var.namespace
    error_message = "The Deployment must target var.namespace"
  }

  assert {
    condition     = kubernetes_service_v1.app[0].metadata[0].namespace == var.namespace
    error_message = "The Service must target var.namespace"
  }
}

run "skips_namespace_when_unmanaged" {
  command = plan

  variables {
    manage_namespace = false
  }

  assert {
    condition     = length(kubernetes_namespace_v1.app) == 0
    error_message = "No namespace must be created when manage_namespace is false"
  }

  assert {
    condition     = kubernetes_deployment_v1.app[0].metadata[0].namespace == var.namespace
    error_message = "The Deployment must still target var.namespace when the namespace is unmanaged"
  }

  assert {
    condition     = kubernetes_service_v1.app[0].metadata[0].namespace == var.namespace
    error_message = "The Service must still target var.namespace when the namespace is unmanaged"
  }

  assert {
    condition     = kubernetes_secret_v1.env[0].metadata[0].namespace == var.namespace
    error_message = "The Secret must still target var.namespace when the namespace is unmanaged"
  }

  assert {
    condition     = kubernetes_network_policy_v1.app[0].metadata[0].namespace == var.namespace
    error_message = "The NetworkPolicy must still target var.namespace when the namespace is unmanaged"
  }
}

run "ingressroute_is_a_traefik_route_via_kubectl_manifest" {
  command = plan

  assert {
    condition     = yamldecode(kubectl_manifest.ingressroute[0].yaml_body).kind == "IngressRoute"
    error_message = "The IngressRoute manifest must be kind IngressRoute"
  }

  assert {
    condition     = yamldecode(kubectl_manifest.ingressroute[0].yaml_body).apiVersion == "traefik.io/v1alpha1"
    error_message = "The IngressRoute manifest must target traefik.io/v1alpha1"
  }

  assert {
    condition     = yamldecode(kubectl_manifest.ingressroute[0].yaml_body).metadata.namespace == var.namespace
    error_message = "The IngressRoute must target var.namespace"
  }

  assert {
    condition     = yamldecode(kubectl_manifest.ingressroute[0].yaml_body).spec.routes[0].services[0].name == var.name
    error_message = "The IngressRoute must route to the app's own Service"
  }
}
