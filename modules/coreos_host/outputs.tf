output "vps_ipv4" {
  description = "Public IPv4 address of the host."
  value       = hcloud_server.this.ipv4_address
}

output "vps_ipv6" {
  description = "Public IPv6 address of the host."
  value       = hcloud_server.this.ipv6_address
}

output "firewall_id" {
  description = "ID of the Hetzner Cloud Firewall attached to the host."
  value       = hcloud_firewall.this.id
}

output "data_volume_id" {
  description = "ID of the persistent Hetzner Cloud data volume, or null when data_volume is disabled. Used by the rollback runbook to reattach the same encrypted volume to a replacement host."
  value       = var.data_volume.enable ? hcloud_volume.data[0].id : null
}

output "k3s_data_dir" {
  description = "Filesystem path k3s stores its state and local-path PVCs in. On the encrypted LUKS mount when both LUKS and k3s are enabled, so persistent data (including CNPG Postgres PVCs under <data-dir>/storage) lands on the encrypted volume and survives reprovision; empty means the k3s default (/var/lib/rancher/k3s on the boot disk)."
  value       = local.k3s_data_dir
}

output "butane_config" {
  description = "Rendered Butane (Ignition source) config for the host."
  value       = local.butane
}
