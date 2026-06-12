variable "name" {
  description = "Logical name / hostname for the production host; used in the Hetzner resource names"
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type for the production host"
  type        = string
  default     = "cpx21"
}

variable "location" {
  description = "Hetzner Cloud datacenter location; configurable per deployment (e.g. ash, fsn1)"
  type        = string
}

variable "image" {
  description = "Hetzner Cloud image to provision"
  type        = string
  default     = "debian-13"
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hetzner; used by the provision job for direct root SSH"
  type        = string
}

variable "ssh_source_ips" {
  description = "CIDRs allowed to reach SSH (22) through the Hetzner Cloud Firewall. Open by default; tightened separately via a Terraform-managed allowlist."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
