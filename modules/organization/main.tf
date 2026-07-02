locals {
  site_preview_enabled = var.site_preview.site_project_id != ""
}

module "site_preview" {
  count  = local.site_preview_enabled ? 1 : 0
  source = "../pages_preview"

  ops_project_id     = var.ops_project_id
  ops_project_path   = var.ops_project_path
  site_project_id    = var.site_preview.site_project_id
  site_project_path  = var.site_preview.site_project_path
  pages_project_name = var.site_preview.pages_project_name
}
