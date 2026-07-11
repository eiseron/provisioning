variable "name" {
  description = "Logical name / hostname for the host; used in the Hetzner resource names and set as the FCOS hostname."
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type (chosen per role; no default so the caller is explicit)."
  type        = string
}

variable "location" {
  description = "Hetzner Cloud datacenter location (e.g. ash, fsn1, nbg1)."
  type        = string
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hetzner; used by the rescue install to log in as root."
  type        = string
}

variable "ssh_private_key" {
  description = "Private key matching ssh_public_key; used by the install provisioner to reach the rescue system. Injected in CI, never stored."
  type        = string
  sensitive   = true
}

variable "deploy_ssh_authorized_key" {
  description = "SSH public key authorized for the FCOS 'core' user after install (the deploy/operator key)."
  type        = string
}

variable "ssh_source_ips" {
  description = "CIDRs allowed to reach SSH (22) through the Hetzner Cloud Firewall. Open by default; tightened separately via a Terraform-managed allowlist."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "butane_image" {
  description = "Official Butane container used to transpile the config in rescue. Pin to a digest in prod (the :release tag floats)."
  type        = string
  default     = "quay.io/coreos/butane:release"
}

variable "coreos_installer_image" {
  description = "Official coreos-installer container used to write FCOS to disk in rescue. Pin to a digest in prod (the :release tag floats)."
  type        = string
  default     = "quay.io/coreos/coreos-installer:release"
}

variable "install_device" {
  description = "Target block device coreos-installer writes FCOS to."
  type        = string
  default     = "/dev/sda"
}

variable "platform" {
  description = "coreos-installer platform id (-p). Hetzner Cloud is KVM, so qemu."
  type        = string
  default     = "qemu"
}
