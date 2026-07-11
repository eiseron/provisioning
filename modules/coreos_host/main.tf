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

  butane = templatefile("${path.module}/butane/base.bu.tftpl", {
    deploy_ssh_authorized_key = var.deploy_ssh_authorized_key
    hostname                  = var.name
  })
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
  location     = var.location
  image        = "debian-13"
  rescue       = "linux64"
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.this.id]

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
      "set -euxo pipefail",
      "update-alternatives --set iptables /usr/sbin/iptables-legacy",
      "update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy",
      "apt-get update -y",
      "apt-get install -y docker.io",
      "docker run --rm -i ${var.butane_image} --strict < /root/config.yaml > /root/config.ign",
      "docker run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v /root:/data -w /data ${var.coreos_installer_image} install ${var.install_device} -p ${var.platform} -i config.ign",
      "sync",
    ]
  }

  provisioner "remote-exec" {
    inline = ["nohup sh -c 'sleep 2 && reboot' >/dev/null 2>&1 &"]
  }

  lifecycle {
    ignore_changes = [rescue, image, ssh_keys]
  }
}
