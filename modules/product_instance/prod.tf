locals {
  prod_enabled = nonsensitive(var.prod.enabled) && local._app_project_id != ""

  prod_app_vars_base = local.prod_enabled ? {
    PROD_DEPLOYER_TRIGGER_TOKEN = gitlab_pipeline_trigger.prod_deployer[0].token
    PROD_DEPLOYER_PROJECT       = var.ops_project_path
  } : {}

  prod_app_vars_r2 = local.prod_enabled && (local.assets_enabled || nonsensitive(var.prod.r2_access_key_id != "")) ? {
    AWS_ACCESS_KEY_ID     = local.assets_enabled ? cloudflare_api_token.assets_write[0].id : var.prod.r2_access_key_id
    AWS_SECRET_ACCESS_KEY = local.assets_enabled ? sha256(cloudflare_api_token.assets_write[0].value) : var.prod.r2_secret_access_key
  } : {}

  prod_otlp_endpoint = nonsensitive(var.prod.observability_otlp_endpoint)

  prod_app_vars_observability = local.prod_enabled && local.prod_otlp_endpoint != "" ? {
    OBSERVABILITY_OTLP_ENDPOINT = local.prod_otlp_endpoint
  } : {}

  prod_app_vars = merge(local.prod_app_vars_base, local.prod_app_vars_r2, local.prod_app_vars_observability)

  prod_ops_vars_base = local.prod_enabled ? {
    KAMAL_REGISTRY_USERNAME = gitlab_project_deploy_token.prod_registry[0].username
    KAMAL_REGISTRY_PASSWORD = gitlab_project_deploy_token.prod_registry[0].token
    SECRET_KEY_BASE         = random_password.secret_key_base[0].result
    PROD_APP_HOST           = var.runtime.app_host
    PROD_NAMESPACE          = local.k3s_namespace
    PROD_APP_IMAGE          = var.runtime.app_image
    PROD_APP_IMAGE_REPO     = var.runtime.app_image_repo
  } : {}

  prod_ops_global_vars = local.prod_enabled ? {
    PROD_CLOUDFLARE_ACCOUNT_ID = var.cloudflare_account_id
    PROD_SLUG                  = var.slug
    PROD_RELEASE_MODULE        = var.runtime.release_module
    PROD_PROJECT               = local._app_project_path
  } : {}

  prod_ops_vars_observability = local.prod_enabled && local.prod_otlp_endpoint != "" ? {
    OBSERVABILITY_OTLP_ENDPOINT = local.prod_otlp_endpoint
  } : {}

  prod_ops_vars = merge(local.prod_ops_vars_base, local.prod_ops_vars_observability)
}

resource "gitlab_pipeline_trigger" "prod_deployer" {
  count       = local.prod_enabled ? 1 : 0
  project     = var.ops_project_id
  description = "Production deployer triggered by the app CI pipeline"
}

resource "gitlab_project_deploy_token" "prod_registry" {
  count   = local.prod_enabled ? 1 : 0
  project = local._app_project_id
  name    = "prod-registry-pull"
  scopes  = ["read_registry"]
}

resource "random_password" "secret_key_base" {
  count   = local.prod_enabled ? 1 : 0
  length  = 64
  special = false
}

resource "gitlab_project_variable" "prod_app" {
  for_each          = local.prod_app_vars
  project           = local._app_project_id
  key               = each.key
  value             = each.value
  masked            = !contains(["PROD_DEPLOYER_PROJECT", "OBSERVABILITY_OTLP_ENDPOINT"], each.key)
  protected         = true
  environment_scope = "*"
}

resource "gitlab_project_variable" "prod_ops" {
  for_each          = local.prod_ops_vars
  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = !contains(["KAMAL_REGISTRY_USERNAME", "PROD_PROJECT", "OBSERVABILITY_OTLP_ENDPOINT", "PROD_APP_HOST", "PROD_NAMESPACE", "PROD_APP_IMAGE", "PROD_APP_IMAGE_REPO"], each.key)
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "prod_ops_global" {
  for_each          = local.prod_ops_global_vars
  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = false
  protected         = true
  environment_scope = "*"
}

moved {
  from = gitlab_project_variable.prod_cloudflare_account_id["PROD_CLOUDFLARE_ACCOUNT_ID"]
  to   = gitlab_project_variable.prod_ops_global["PROD_CLOUDFLARE_ACCOUNT_ID"]
}

moved {
  from = gitlab_project_variable.prod_ops["PROD_SLUG"]
  to   = gitlab_project_variable.prod_ops_global["PROD_SLUG"]
}

moved {
  from = gitlab_project_variable.prod_ops["PROD_RELEASE_MODULE"]
  to   = gitlab_project_variable.prod_ops_global["PROD_RELEASE_MODULE"]
}

moved {
  from = gitlab_project_variable.prod_ops["PROD_PROJECT"]
  to   = gitlab_project_variable.prod_ops_global["PROD_PROJECT"]
}
