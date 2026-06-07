resource "hostinger_vps_ssh_key" "admin" {
  name = "${var.name}-admin"
  key  = var.ssh_public_key
}

resource "hostinger_vps" "this" {
  hostname       = var.name
  plan           = var.plan
  data_center_id = var.data_center_id
  template_id    = var.template_id
  ssh_key_ids    = [tonumber(hostinger_vps_ssh_key.admin.id)]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [template_id, ssh_key_ids]
  }
}
