output "trigger_token" {
  description = "Pipeline trigger token minted on the ops deployer; injected as PREVIEW_DEPLOYER_TRIGGER_TOKEN on the site repo"
  value       = gitlab_pipeline_trigger.this.token
  sensitive   = true
}
