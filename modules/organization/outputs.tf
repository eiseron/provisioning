output "site_preview_trigger_token" {
  description = "Pipeline trigger token of the institutional-site preview deployer, if enabled"
  value       = local.site_preview_enabled ? module.site_preview[0].trigger_token : null
  sensitive   = true
}
