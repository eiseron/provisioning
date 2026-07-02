locals {
  site_preview_enabled = var.site_preview.site_project_id != ""

  site_preview_ops_vars = local.site_preview_enabled ? {
    PREVIEW_PAGES_PROJECT = var.site_preview.pages_project_name
    PREVIEW_SITE_PROJECT  = var.site_preview.site_project_path
  } : {}

  site_preview_site_vars = local.site_preview_enabled ? {
    PREVIEW_DEPLOYER_PROJECT       = { value = var.site_preview.ops_project_path, masked = false }
    PREVIEW_DEPLOYER_TRIGGER_TOKEN = { value = gitlab_pipeline_trigger.site_preview[0].token, masked = true }
  } : {}
}

resource "gitlab_pipeline_trigger" "site_preview" {
  count = local.site_preview_enabled ? 1 : 0

  project     = var.ops_project_id
  description = "${var.site_preview.pages_project_name} MR preview → pages deployer"
}

resource "gitlab_project_variable" "site_preview_ops" {
  for_each = local.site_preview_ops_vars

  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = false
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "site_preview_site" {
  for_each = local.site_preview_site_vars

  project   = var.site_preview.site_project_id
  key       = each.key
  value     = each.value.value
  masked    = each.value.masked
  protected = false
}

resource "gitlab_project_job_token_scope" "site_allows_ops" {
  count = local.site_preview_enabled ? 1 : 0

  project           = var.site_preview.site_project_id
  target_project_id = var.ops_project_id
}
