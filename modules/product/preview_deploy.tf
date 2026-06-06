locals {
  preview_app_deploy_vars = local.preview_enabled ? {
    PREVIEW_REGISTRY_USER          = { value = gitlab_project_deploy_token.preview_registry[0].username, masked = false }
    PREVIEW_REGISTRY_PASSWORD      = { value = gitlab_project_deploy_token.preview_registry[0].token, masked = true }
    PREVIEW_DEPLOYER_PROJECT       = { value = "${gitlab_group.this.full_path}/${local.ops_repo_key}", masked = false }
    PREVIEW_DEPLOYER_TRIGGER_TOKEN = { value = gitlab_pipeline_trigger.preview_deployer[0].token, masked = true }
  } : {}

  preview_ops_deploy_vars = local.preview_enabled ? {
    PREVIEW_IMAGE_PULL_USER  = { value = gitlab_project_deploy_token.preview_registry[0].username, masked = false }
    PREVIEW_IMAGE_PULL_TOKEN = { value = gitlab_project_deploy_token.preview_registry[0].token, masked = true }
    PREVIEW_SWEEP_TOKEN      = { value = gitlab_group_service_account_access_token.robot_readonly.token, masked = true }
    PREVIEW_SECRET_KEY_BASE  = { value = random_password.preview_secret_key_base[0].result, masked = true }
    PREVIEW_MIX_ENV          = { value = var.preview_mix_env, masked = false }
  } : {}
}

resource "gitlab_project_deploy_token" "preview_registry" {
  count = local.preview_enabled ? 1 : 0

  project = module.repository[var.slug].id
  name    = "preview-registry"
  scopes  = ["read_registry", "write_registry"]
}

resource "gitlab_pipeline_trigger" "preview_deployer" {
  count = local.preview_enabled ? 1 : 0

  project     = module.repository[local.ops_repo_key].id
  description = "Preview deployer triggered by the product app CI"
}

resource "random_password" "preview_secret_key_base" {
  count = local.preview_enabled ? 1 : 0

  length  = 64
  special = false
}

resource "gitlab_project_variable" "preview_app_deploy" {
  for_each = local.preview_app_deploy_vars

  project           = module.repository[var.slug].id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = false
  environment_scope = "*"
}

resource "gitlab_project_variable" "preview_ops_deploy" {
  for_each = local.preview_ops_deploy_vars

  project           = module.repository[local.ops_repo_key].id
  key               = each.key
  value             = each.value.value
  masked            = each.value.masked
  protected         = true
  environment_scope = "production"
}
