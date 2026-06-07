output "pipeline_schedule_id" {
  description = "ID of the created pipeline schedule."
  value       = gitlab_pipeline_schedule.drift.pipeline_schedule_id
}
