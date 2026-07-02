variable "ops_project_id" {
  description = "GitLab project ID of the ops repo that hosts the pages deployer pipeline and its trigger"
  type        = string
}

variable "ops_project_path" {
  description = "Full path of the ops deployer project; injected as PREVIEW_DEPLOYER_PROJECT on the site repo"
  type        = string
}

variable "site_project_id" {
  description = "GitLab project ID of the static site repo whose MRs trigger previews"
  type        = string
}

variable "site_project_path" {
  description = "Full path of the static site project; injected as PREVIEW_SITE_PROJECT on the ops repo"
  type        = string
}

variable "pages_project_name" {
  description = "Cloudflare Pages project name that receives the preview deployment"
  type        = string
}
