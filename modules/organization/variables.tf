variable "repos" {
  description = "Extra org-level repositories to add to (or override from) the standard set. Merged with the module's built-in defaults (eiseron-ops, eiseron-site, eiseron-planning) before provisioning. Defaults to empty — most callers need only add non-standard repos here."
  type = map(object({
    description                           = optional(string, "")
    visibility_level                      = optional(string, "private")
    topics                                = optional(list(string), [])
    issues_access_level                   = optional(string, "disabled")
    wiki_access_level                     = optional(string, "disabled")
    squash_option                         = optional(string, "always")
    only_allow_merge_if_pipeline_succeeds = optional(bool, true)
    deploy_promotion                      = optional(bool, false)
    protect_release_branch                = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.repos : contains(["private", "internal", "public"], v.visibility_level)
    ])
    error_message = "repos[*].visibility_level must be 'private', 'internal', or 'public'."
  }

  validation {
    condition = alltrue([
      for k, v in var.repos : contains(["enabled", "disabled", "private"], v.issues_access_level)
    ])
    error_message = "repos[*].issues_access_level must be 'enabled', 'disabled', or 'private'."
  }

  validation {
    condition = alltrue([
      for k, v in var.repos : contains(["enabled", "disabled", "private"], v.wiki_access_level)
    ])
    error_message = "repos[*].wiki_access_level must be 'enabled', 'disabled', or 'private'."
  }

  validation {
    condition = alltrue([
      for k, v in var.repos : contains(["never", "always", "default_on", "default_off"], v.squash_option)
    ])
    error_message = "repos[*].squash_option must be 'never', 'always', 'default_on', or 'default_off'."
  }
}

variable "skip_repos" {
  description = "Set of repo slugs to exclude from provisioning. Use to opt out of a default repo that this organization does not need."
  type        = set(string)
  default     = []
}

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

variable "robot_user_id" {
  description = "GitLab user ID to add as developer to the org group (e.g. the automation bot account). Null disables the membership."
  type        = number
  default     = null

  validation {
    condition     = var.robot_user_id == null || var.robot_user_id > 0
    error_message = "robot_user_id must be a positive integer (a valid GitLab user ID)."
  }
}

variable "service_account" {
  description = "Org-level CI service account to create inside the group. When set, the module creates the service account and its group membership (developer). Null skips both resources."
  type = object({
    name     = string
    username = string
  })
  default = null

  validation {
    condition     = var.service_account == null || (length(trimspace(var.service_account.name)) > 0 && length(trimspace(var.service_account.username)) > 0)
    error_message = "service_account.name and service_account.username must be non-empty strings."
  }
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

variable "cloudflare_account_id" {
  description = "Cloudflare account ID used to manage the institutional site Pages project and its custom domains. Null disables all Cloudflare Pages resources in this module."
  type        = string
  default     = null

  validation {
    condition     = var.cloudflare_account_id == null || length(trimspace(var.cloudflare_account_id)) > 0
    error_message = "cloudflare_account_id must be null or a non-empty, non-blank string."
  }
}

variable "site_domains" {
  description = "Custom domains to attach to the institutional site Cloudflare Pages project (e.g. [\"eiseron.com\", \"www.eiseron.com\"]). Requires cloudflare_account_id and site_preview.pages_project_name to be set."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for d in var.site_domains : length(trimspace(d)) > 0])
    error_message = "site_domains must not contain empty or blank strings."
  }
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
