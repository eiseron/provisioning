variable "project_id" {
  description = "Numeric ID of the GitLab project that runs the drift check."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "project_id must not be empty."
  }
}

variable "description" {
  description = "Schedule description shown in the GitLab UI."
  type        = string
  default     = "Terraform drift check against SOPS-managed secrets"
}

variable "ref" {
  description = "Git ref the scheduled pipeline runs on."
  type        = string
  default     = "refs/heads/main"
}

variable "cron" {
  description = "Cron expression for the schedule (UTC unless cron_timezone is set)."
  type        = string
  default     = "0 9 * * 1"
}

variable "cron_timezone" {
  description = "Timezone applied to the cron expression."
  type        = string
  default     = "UTC"
}
