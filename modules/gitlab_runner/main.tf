resource "hcloud_ssh_key" "this" {
  count = var.decommission ? 0 : 1

  name       = "${var.name}-admin"
  public_key = var.ssh_public_key

  lifecycle {
    ignore_changes = [name, public_key]
  }
}

resource "hcloud_server" "this" {
  count = var.decommission ? 0 : 1

  name        = var.name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.this[0].id]

  lifecycle {
    ignore_changes = [ssh_keys, image]
  }
}

resource "gitlab_user_runner" "this" {
  count = var.decommission ? 0 : 1

  runner_type = "group_type"
  group_id    = var.group_id

  tag_list        = var.tag_list
  untagged        = var.untagged
  maximum_timeout = var.maximum_timeout

  lifecycle {
    ignore_changes = [group_id]
  }
}
