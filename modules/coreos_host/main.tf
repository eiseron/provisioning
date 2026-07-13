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

  luks_enabled = var.luks.tang.url != ""

  encrypted_k3s = local.luks_enabled && var.k3s.enable

  k3s_data_dir = local.encrypted_k3s ? "${var.luks.mount}/rancher/k3s" : ""

  luks_mount_unit = "${replace(trim(var.luks.mount, "/"), "/", "-")}.mount"

  butane = templatefile("${path.module}/butane/base.bu.tftpl", {
    deploy_ssh_authorized_key = var.deploy_ssh_authorized_key
    hostname                  = var.name
    luks_enabled              = local.luks_enabled
    luks_name                 = var.luks.name
    luks_device               = var.data_volume.enable ? "/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data[0].id}" : var.luks.device
    luks_mount                = var.luks.mount
    luks_mount_unit           = local.luks_mount_unit
    luks_wipe                 = var.data_volume.enable ? false : var.luks.wipe
    tang_url                  = var.luks.tang.url
    tang_thumbprint           = var.luks.tang.thumbprint
    k3s_enabled               = var.k3s.enable
    k3s_data_dir              = local.k3s_data_dir
    k3s_version_url           = replace(var.k3s.version, "+", "%2B")
    k3s_tls_san               = var.k3s.tls_san
  })
}

resource "hcloud_firewall" "this" {
  for_each = toset(["${var.name}-fw"])

  name = each.value

  lifecycle {
    create_before_destroy = true
  }

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

resource "hcloud_volume" "data" {
  count             = var.data_volume.enable ? 1 : 0
  name              = "${var.name}-data"
  size              = var.data_volume.size
  location          = var.location
  delete_protection = var.data_volume.delete_protection
}

resource "hcloud_server" "this" {
  name         = var.name
  server_type  = var.server_type
  location     = var.location
  image        = "debian-13"
  rescue       = "linux64"
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [for f in hcloud_firewall.this : f.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  connection {
    host        = self.ipv4_address
    user        = "root"
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "file" {
    content     = local.butane
    destination = "/root/config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eux",
      "update-alternatives --set iptables /usr/sbin/iptables-legacy",
      "update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy",
      "apt-get update -y",
      "apt-get install -y docker.io",
      "docker run --rm -i ${var.butane_image} --strict < /root/config.yaml > /root/config.ign",
      "docker run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v /root:/data -w /data ${var.coreos_installer_image} install ${var.install_device} -p ${var.platform} -i config.ign",
      "sync",
    ]
  }

  lifecycle {
    ignore_changes = [rescue, image, ssh_keys]
  }
}

resource "hcloud_volume_attachment" "data" {
  count     = var.data_volume.enable ? 1 : 0
  volume_id = hcloud_volume.data[0].id
  server_id = hcloud_server.this.id
  automount = false
}

resource "null_resource" "boot" {
  triggers = {
    server = hcloud_server.this.id
  }

  depends_on = [
    hcloud_server.this,
    hcloud_volume_attachment.data,
  ]

  connection {
    host        = hcloud_server.this.ipv4_address
    user        = "root"
    private_key = var.ssh_private_key
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = ["nohup sh -c 'sleep 2 && reboot' >/dev/null 2>&1 &"]
  }
}
