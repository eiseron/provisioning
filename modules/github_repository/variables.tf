variable "name" {
  description = "Repository name."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Short description of the repository."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "Repository visibility: 'public' or 'private'."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "visibility must be 'public', 'private', or 'internal'."
  }
}

variable "homepage_url" {
  description = "URL of the repository homepage."
  type        = string
  default     = ""
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "has_wiki" {
  type    = bool
  default = true
}

variable "has_projects" {
  type    = bool
  default = true
}

variable "delete_branch_on_merge" {
  type    = bool
  default = false
}

variable "vulnerability_alerts" {
  type    = bool
  default = false
}

variable "auto_init" {
  type    = bool
  default = false
}

variable "gitignore_template" {
  type     = string
  default  = null
  nullable = true
}

variable "license_template" {
  type     = string
  default  = null
  nullable = true
}

variable "allow_merge_commit" {
  type    = bool
  default = true
}

variable "allow_squash_merge" {
  type    = bool
  default = true
}

variable "allow_rebase_merge" {
  type    = bool
  default = true
}

variable "topics" {
  type    = list(string)
  default = []
}

variable "enable_branch_protection" {
  description = "Whether to create a branch protection rule for main."
  type        = bool
  default     = true
}

variable "enforce_admins" {
  type    = bool
  default = true
}

variable "required_linear_history" {
  type    = bool
  default = false
}

variable "allows_force_pushes" {
  type    = bool
  default = false
}

variable "allows_deletions" {
  type    = bool
  default = false
}
