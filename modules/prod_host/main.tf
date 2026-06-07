resource "hcloud_ssh_key" "admin" {
  name       = "${var.name}-admin"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.admin.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ssh_keys, image]
  }
}
