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
  description = "Encrypted data volume, unlocked at boot via network-bound Tang. When tang.url is set, the module emits a storage.luks device bound to Tang via Clevis plus an ext4 filesystem at mount; empty tang.url leaves the host unencrypted. Fields: device is the block device to encrypt (a dedicated fresh volume on the Green host); name is the /dev/mapper name; mount is the filesystem path the k3s data-dir is set onto (so k3s state and local-path PVCs, including the CNPG Postgres volumes, live encrypted at rest and survive reprovision); wipe formats the device fresh (safe ONLY on a new device, never against data to preserve). The mapping enables discard/TRIM (needed for cloud SSD wear; leaks coarse used-block info, an accepted tradeoff). tang.url is the existing Tang keyserver (http://<ip>:6800) and tang.thumbprint is the Clevis-pinned advertised-key thumbprint (PROD_LUKS_TANG_THP)."
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

variable "data_volume" {
  description = "Persistent Hetzner Cloud block-storage volume for the encrypted data, decoupled from the immutable boot disk. When enable is true the module provisions a separate hcloud_volume, attaches it unformatted, and points the LUKS device at its stable /dev/disk/by-id path instead of luks.device; the volume survives host reprovision (coreos-installer only writes install_device, the boot disk), which is what makes rolling reprovision and rollback between servers possible without data loss. With a data volume the LUKS wipe is forced off so a reattached volume is unlocked in place rather than reformatted. Fields: size is the volume size in GB (min 10, grow-only in Hetzner); delete_protection guards the volume against accidental destroy (keep on for prod data)."
  type = object({
    enable            = optional(bool, false)
    size              = optional(number, 10)
    delete_protection = optional(bool, true)
  })
  default = {}

  validation {
    condition     = !var.data_volume.enable || var.data_volume.size >= 10
    error_message = "data_volume.size must be at least 10 GB (the Hetzner Cloud volume minimum)."
  }
}

variable "k3s" {
  description = "k3s server on this host. When enable is true, the Butane lays down the k3s config (Traefik kept bundled), layers the k3s-selinux policy via rpm-ostree, installs the pinned k3s binary from GitHub releases, and runs k3s server. Fields: version is the pinned release tag (e.g. v1.30.5+k3s1); tls_san lists extra SANs for the API server cert (the public host/IP so the extracted kubeconfig works remotely)."
  type = object({
    enable  = optional(bool, false)
    version = optional(string, "")
    tls_san = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = !var.k3s.enable || can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+\\+k3s[0-9]+$", var.k3s.version))
    error_message = "k3s.version must be a pinned release tag matching v<x>.<y>.<z>+k3s<n> (e.g. v1.30.5+k3s1); it is interpolated into a boot-time shell command, so the format is enforced to prevent injection."
  }
}
