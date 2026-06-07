variable "name" {
  description = "Logical name for the Tang host; used in the Hetzner resource names"
  type        = string
  default     = "tang"
}

variable "server_type" {
  description = "Hetzner Cloud server type. Tang only runs a tiny HTTP daemon, so the cheapest type (Ampere ARM cax11) is plenty."
  type        = string
  default     = "cax11"
}

variable "location" {
  description = "Hetzner Cloud datacenter location (must offer the chosen server type; cax* are in fsn1/nbg1/hel1)"
  type        = string
  default     = "nbg1"
}

variable "image" {
  description = "Hetzner Cloud image to provision (resolved per the server type's architecture)"
  type        = string
  default     = "debian-13"
}

variable "ssh_public_key" {
  description = "Bootstrap SSH public key registered with Hetzner; used by the provision job for direct root SSH"
  type        = string
}
