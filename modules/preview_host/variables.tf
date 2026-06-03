variable "name" {
  description = "Logical name for this preview host; used in the Hetzner resource names"
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx23"
}

variable "location" {
  description = "Hetzner Cloud datacenter location"
  type        = string
  default     = "fsn1"
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
