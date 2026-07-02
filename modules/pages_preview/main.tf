resource "gitlab_pipeline_trigger" "this" {
  project     = var.ops_project_id
  description = "${var.pages_project_name} MR preview → pages deployer"
}

locals {
  ops_vars = {
    PREVIEW_PAGES_PROJECT = var.pages_project_name
    PREVIEW_SITE_PROJECT  = var.site_project_path
  }

  site_vars = {
    PREVIEW_DEPLOYER_PROJECT       = { value = var.ops_project_path, masked = false }
    PREVIEW_DEPLOYER_TRIGGER_TOKEN = { value = gitlab_pipeline_trigger.this.token, masked = true }
  }
}

resource "gitlab_project_variable" "ops" {
  for_each = local.ops_vars

  project           = var.ops_project_id
  key               = each.key
  value             = each.value
  masked            = false
  protected         = true
  environment_scope = "production"
}

resource "gitlab_project_variable" "site" {
  for_each = local.site_vars

  project   = var.site_project_id
  key       = each.key
  value     = each.value.value
  masked    = each.value.masked
  protected = false
}

resource "gitlab_project_job_token_scope" "site_allows_ops" {
  project           = var.site_project_id
  target_project_id = var.ops_project_id
}
