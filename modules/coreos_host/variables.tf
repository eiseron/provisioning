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

variable "luks" {
  description = "Encrypted data volume, unlocked at boot via network-bound Tang. When tang.url is set, the module emits a storage.luks device bound to Tang via Clevis plus an ext4 filesystem at mount; empty tang.url leaves the host unencrypted. Fields: device is the block device to encrypt (a dedicated fresh volume on the Green host); name is the /dev/mapper name; mount is the filesystem path (reused by the k3s local-path storage); wipe formats the device fresh (safe ONLY on a new device, never against data to preserve). The mapping enables discard/TRIM (needed for cloud SSD wear; leaks coarse used-block info, an accepted tradeoff). tang.url is the existing Tang keyserver (http://<ip>:6800) and tang.thumbprint is the Clevis-pinned advertised-key thumbprint (PROD_LUKS_TANG_THP)."
  type = object({
    device = optional(string, "/dev/sdb")
    name   = optional(string, "crypt")
    mount  = optional(string, "/var/lib/crypt")
    wipe   = optional(bool, true)
    tang = optional(object({
      url        = optional(string, "")
      thumbprint = optional(string, "")
    }), {})
  })
  default = {}

  validation {
    condition     = var.luks.tang.url == "" || var.luks.tang.thumbprint != ""
    error_message = "luks.tang.thumbprint is required when luks.tang.url is set (an empty thumbprint skips Tang key verification and opens a boot-time MITM window)."
  }
}
