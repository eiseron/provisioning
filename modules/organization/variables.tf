variable "ops_project_id" {
  description = "GitLab project ID of the organization ops repo, which acts as the pages preview deployer"
  type        = string
}

variable "ops_project_path" {
  description = "Full path of the organization ops repo; injected as PREVIEW_DEPLOYER_PROJECT on the site repo"
  type        = string
}

variable "site_preview" {
  description = "Institutional-site MR preview config (Cloudflare Pages, dispatch pattern). When site_project_id is set the org composes the shared pages_preview module to provision the deployer trigger, dispatch variables, deployer variables and job-token allowlist. The Cloudflare token stays out of this module (account-scoped, injected on the ops repo). Defaults skip resource creation. Fields: site_project_id + site_project_path identify the static site repo; pages_project_name is the Cloudflare Pages project."
  type = object({
    site_project_id    = optional(string, "")
    site_project_path  = optional(string, "")
    pages_project_name = optional(string, "")
  })
  default = {}
}
