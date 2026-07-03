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

variable "name" {
  description = "Display name of the organization; used as the top-level GitLab group name"
  type        = string
}

variable "slug" {
  description = "Slug of the organization; used as the top-level GitLab group path"
  type        = string
}

variable "avatar_path" {
  description = "Optional path to the organization avatar image (for example a PNG under the consumer's assets directory). Null sets no avatar."
  type        = string
  default     = null
}

variable "group" {
  description = "Top-level GitLab group settings for the organization. description and visibility_level must match the live group so an import/moved plan stays a no-op (omitting visibility would let the provider default to private and downgrade a public root group)."
  type = object({
    description      = string
    visibility_level = string
  })

  validation {
    condition     = contains(["private", "internal", "public"], var.group.visibility_level)
    error_message = "group.visibility_level must be one of private, internal or public."
  }
}
