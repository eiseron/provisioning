provider "kubernetes" {
  host                   = var.runtime.cluster_host != "" ? var.runtime.cluster_host : "https://localhost:6443"
  token                  = var.cluster_token
  cluster_ca_certificate = var.runtime.cluster_ca_cert != "" ? base64decode(var.runtime.cluster_ca_cert) : ""
}

locals {
  k3s_enabled = var.runtime.enable && local.prod_enabled

  k3s_namespace = var.runtime.namespace != "" ? var.runtime.namespace : var.slug

  k3s_database_url = "ecto://${var.slug}:${urlencode(var.db_tenant_password)}@platform-db-rw.platform/${var.slug}_prod"

  k3s_env_clear = merge(
    {
      PHX_HOST                    = var.runtime.app_host
      PORT                        = "4000"
      PHX_SERVER                  = "true"
      POOL_SIZE                   = "10"
      OBSERVABILITY_OTLP_ENDPOINT = var.runtime.observability_otlp_endpoint
    },
    var.runtime.admin_access_issuer == "" ? {} : { ADMIN_ACCESS_ISSUER = var.runtime.admin_access_issuer },
    var.runtime.admin_access_certs_url == "" ? {} : { ADMIN_ACCESS_CERTS_URL = var.runtime.admin_access_certs_url },
  )

  k3s_env_secret = merge(
    {
      SECRET_KEY_BASE = local.prod_enabled ? random_password.secret_key_base[0].result : ""
      DATABASE_URL    = local.k3s_database_url
    },
    var.runtime.admin_access_audiences == "" ? {} : { ADMIN_ACCESS_AUDIENCES = var.runtime.admin_access_audiences },
  )
}

module "k3s_app" {
  source = "../k3s_app"

  providers = {
    kubernetes = kubernetes
  }

  enable           = local.k3s_enabled
  name             = var.slug
  namespace        = local.k3s_namespace
  manage_namespace = var.runtime.manage_namespace
  image            = var.runtime.app_image
  app_host         = var.runtime.app_host

  env_clear  = local.k3s_env_clear
  env_secret = local.k3s_env_secret

  node_selector = var.runtime.node_selector
}
