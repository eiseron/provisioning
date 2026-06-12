resource "hcloud_ssh_key" "admin" {
  name       = "${var.name}-admin"
  public_key = var.ssh_public_key
}

data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

data "http" "cloudflare_ipv6" {
  url = "https://www.cloudflare.com/ips-v6"
}

locals {
  cloudflare_ip_ranges = concat(
    [for cidr in split("\n", trimspace(data.http.cloudflare_ipv4.response_body)) : cidr if trimspace(cidr) != ""],
    [for cidr in split("\n", trimspace(data.http.cloudflare_ipv6.response_body)) : cidr if trimspace(cidr) != ""],
  )
}

resource "hcloud_firewall" "this" {
  name = "${var.name}-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.ssh_source_ips
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = local.cloudflare_ip_ranges
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = local.cloudflare_ip_ranges
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "this" {
  name         = var.name
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.this.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ssh_keys, image]
  }
}
