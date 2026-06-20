variable "name" {
  description = "The name of the GitLab project."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Short description shown in the GitLab UI."
  type        = string
  default     = ""
}

variable "namespace_id" {
  description = "Numeric ID of the GitLab group that will own this project."
  type        = number

  validation {
    condition     = var.namespace_id > 0
    error_message = "namespace_id must be a positive integer."
  }
}

variable "visibility_level" {
  description = "Project visibility."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public", "internal"], var.visibility_level)
    error_message = "visibility_level must be 'private', 'public', or 'internal'."
  }
}

variable "topics" {
  description = "List of topic tags for the project."
  type        = list(string)
  default     = []
}

variable "avatar_path" {
  description = "Optional path to a project avatar image (for example a PNG under the consumer's assets directory). Null sets no avatar."
  type        = string
  default     = null
  nullable    = true
}

variable "issues_access_level" {
  description = "Access level for the Issues feature."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled", "private"], var.issues_access_level)
    error_message = "issues_access_level must be 'enabled', 'disabled', or 'private'."
  }
}

variable "wiki_access_level" {
  description = "Access level for the Wiki feature."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled", "private"], var.wiki_access_level)
    error_message = "wiki_access_level must be 'enabled', 'disabled', or 'private'."
  }
}

variable "push_access_level" {
  description = "Who may push directly to the main branch."
  type        = string
  default     = "no one"

  validation {
    condition     = contains(["no one", "developer", "maintainer", "admin"], var.push_access_level)
    error_message = "push_access_level must be one of: 'no one', 'developer', 'maintainer', 'admin'."
  }
}

variable "allowed_to_push_user_ids" {
  description = "Extra user IDs allowed to push directly to protected branches (main and release/*). GitLab makes user allowlists and push_access_level mutually exclusive, so passing a non-empty list silently disables push_access_level (the broader rule is replaced by the per-user allowlist). Useful for granting a CI service account write access without opening the branch to its whole role. Defaults to empty (use push_access_level alone)."
  type        = list(number)
  default     = []
  nullable    = false
}

variable "only_allow_merge_if_pipeline_succeeds" {
  description = "Require a successful pipeline before MRs can be merged. Set to false for repos with no CI (e.g. planning/docs)."
  type        = bool
  default     = true
}

variable "tag_create_access_level" {
  description = "Who may create tags matching '*'. Defaults to 'maintainer' so the release service account (a Maintainer) creates release tags and runs their pipelines directly. 'no one' has no automated path to create a tag, so it breaks the release-tag flow — set it only on a repo that must never be tagged."
  type        = string
  default     = "maintainer"

  validation {
    condition     = contains(["no one", "developer", "maintainer", "admin"], var.tag_create_access_level)
    error_message = "tag_create_access_level must be one of: 'no one', 'developer', 'maintainer', 'admin'."
  }
}

variable "protect_release_branches" {
  description = "When true, protect 'release/*' branches like main (no direct push, merge via MR). Enables maintenance/hotfix releases on long-lived release branches."
  type        = bool
  default     = true
}

variable "build_timeout" {
  description = "Maximum job duration in seconds before GitLab cancels a job. Defaults to 3600 (1 hour)."
  type        = number
  default     = 3600

  validation {
    condition     = var.build_timeout >= 60 && var.build_timeout <= 86400
    error_message = "build_timeout must be between 60 and 86400 seconds (GitLab limits)."
  }
}

variable "ci_separated_caches" {
  description = "When true, GitLab uses separate runner caches for protected and unprotected refs. Prevents compile-time artifacts from a protected pipeline being pulled by an unprotected MR pipeline."
  type        = bool
  default     = true
}

variable "initialize_with_readme" {
  description = "Whether to create an initial README commit on project creation. Paired with an ignore_changes lifecycle so toggling it after creation is a no-op."
  type        = bool
  default     = true
}

variable "ci_pipeline_variables_minimum_override_role" {
  description = "Minimum role allowed to override CI/CD variables at pipeline run time. Defaults to 'maintainer'. Set to null to leave it unmanaged at the GitLab default."
  type        = string
  default     = "maintainer"
  nullable    = true
}

variable "shared_runners_enabled" {
  description = "Whether instance shared runners may run jobs for this project. Set false to route everything to group/project runners. Null leaves it unmanaged at the GitLab default."
  type        = bool
  default     = null
  nullable    = true
}

variable "container_registry_access_level" {
  description = "Container Registry visibility: 'enabled' inherits project visibility, 'private' restricts to members, 'disabled' turns it off. Null leaves it unmanaged at the GitLab default."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.container_registry_access_level == null ? true : contains(["enabled", "private", "disabled"], var.container_registry_access_level)
    error_message = "container_registry_access_level must be 'enabled', 'private', 'disabled', or null."
  }
}

variable "container_expiration_policy" {
  description = "Optional registry tag cleanup policy. Null disables it. cadence values: 1d 7d 14d 1month 3month. older_than values: 7d 14d 30d 90d."
  type = object({
    cadence           = string
    keep_n            = optional(number)
    older_than        = string
    name_regex_delete = string
  })
  default = null
}
