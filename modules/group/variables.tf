variable "name" {
  description = "Display name of the subgroup"
  type        = string
}

variable "slug" {
  description = "Path slug of the subgroup"
  type        = string
}

variable "parent_group_id" {
  description = "Numeric ID of the parent GitLab group"
  type        = string
}

variable "description" {
  description = "Description of the subgroup"
  type        = string
  default     = ""
}

variable "visibility_level" {
  description = "Visibility of the subgroup"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["private", "internal", "public"], var.visibility_level)
    error_message = "visibility_level must be 'private', 'internal', or 'public'."
  }
}

variable "avatar_path" {
  description = "Avatar applied to the subgroup and to every repo in var.repos. Null sets no avatar."
  type        = string
  default     = null
}

variable "repos" {
  description = "Repos to provision inside this subgroup. Map key is the repo slug."
  type = map(object({
    description          = string
    visibility_level     = optional(string, "private")
    topics               = optional(list(string), [])
    issues_access_level  = optional(string, "disabled")
    wiki_access_level    = optional(string, "disabled")
    publish_github_token = optional(bool, true)
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
}

variable "github_token" {
  description = "GitHub PAT published as GITHUB_TOKEN on every repo in var.repos that has publish_github_token = true. Empty string skips the CI variable for all of them."
  type        = string
  sensitive   = true
  default     = ""
}
