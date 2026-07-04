output "runner_ipv4" {
  description = "Public IPv4 address of the runner VPS; wire into Ansible inventory and CI variables."
  value       = hcloud_server.this.ipv4_address
}

output "runner_token" {
  description = "GitLab runner authentication token; write-once, handle as secret. The token is stored as plaintext in Terraform state — the caller root must enforce encrypted state (e.g. pbkdf2/AES-GCM backend)."
  value       = gitlab_user_runner.this.token
  sensitive   = true
}

output "ssh_key_id" {
  description = "Hetzner SSH key ID registered for this runner; useful for referencing from the caller if shared with other hosts."
  value       = hcloud_ssh_key.this.id
}
