resource "gitlab_pipeline_schedule" "drift" {
  project       = var.project_id
  description   = var.description
  ref           = var.ref
  cron          = var.cron
  cron_timezone = var.cron_timezone
  active        = true
}

resource "gitlab_pipeline_schedule_variable" "drift_check" {
  project              = gitlab_pipeline_schedule.drift.project
  pipeline_schedule_id = gitlab_pipeline_schedule.drift.pipeline_schedule_id
  key                  = "DRIFT_CHECK"
  value                = "1"
}
