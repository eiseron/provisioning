mock_provider "hcloud" {
  mock_resource "hcloud_firewall" {
    defaults = {
      id = "1"
    }
  }
  mock_resource "hcloud_ssh_key" {
    defaults = {
      id = "1"
    }
  }
  mock_resource "hcloud_volume" {
    defaults = {
      id = "100"
    }
  }
  mock_resource "hcloud_server" {
    defaults = {
      id = "200"
    }
  }
}
mock_provider "null" {}
mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "1.1.1.1/32"
    }
  }
}

variables {
  name                      = "acme-app-green"
  server_type               = "cpx21"
  location                  = "ash"
  ssh_public_key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVALIDATEonly admin@ci"
  ssh_private_key           = "validate-only-placeholder"
  deploy_ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVALIDATEonly deploy@ci"
  hcloud_token              = "validate-only-placeholder"
  k3s = {
    enable  = true
    version = "v1.30.5+k3s1"
    tls_san = ["acme-app-green.example.com"]
  }
}

run "k3s_data_dir_lands_on_encrypted_mount" {
  command = plan

  variables {
    luks = {
      mount = "/var/lib/crypt"
      tang = {
        url        = "http://10.0.0.10:6800"
        thumbprint = "VALIDATEonlyThumbprint"
      }
    }
  }

  assert {
    condition     = output.k3s_data_dir == "/var/lib/crypt/rancher/k3s"
    error_message = "k3s data-dir must be a subdir of the encrypted LUKS mount when LUKS and k3s are enabled"
  }

  assert {
    condition     = strcontains(output.butane_config, "data-dir: /var/lib/crypt/rancher/k3s")
    error_message = "The rendered k3s config.yaml must set data-dir onto the encrypted mount"
  }

  assert {
    condition     = strcontains(output.butane_config, "RequiresMountsFor=/var/lib/crypt")
    error_message = "k3s must require the encrypted mount before starting so it never writes before the volume is mounted"
  }

  assert {
    condition     = strcontains(output.butane_config, "After=var-lib-crypt.mount")
    error_message = "k3s must be ordered after the generated encrypted mount unit"
  }
}

run "k3s_uses_default_data_dir_without_luks" {
  command = plan

  assert {
    condition     = output.k3s_data_dir == ""
    error_message = "Without LUKS the module must leave the k3s data-dir at the default"
  }

  assert {
    condition     = !strcontains(output.butane_config, "data-dir:")
    error_message = "No data-dir override must be rendered when LUKS is disabled"
  }

  assert {
    condition     = !strcontains(output.butane_config, "RequiresMountsFor=")
    error_message = "No encrypted-mount dependency must be rendered when LUKS is disabled"
  }
}

run "k3s_version_url_is_systemd_escaped" {
  command = plan

  assert {
    condition     = strcontains(output.butane_config, "download/v1.30.5%%2Bk3s1/k3s")
    error_message = "The k3s release URL is embedded in a systemd ExecStart where % starts a unit specifier; the + must render as %%2B so systemd emits a literal %2B for curl instead of failing to load the unit"
  }
}

run "tang_keyserver_renders_tang_units_and_no_k3s" {
  command = plan

  variables {
    k3s         = { enable = false }
    data_volume = { enable = true }
    tang = {
      enable      = true
      allowed_ips = ["203.0.113.10/32"]
    }
  }

  assert {
    condition     = strcontains(output.butane_config, "rpm-ostree install --apply-live --allow-inactive --idempotent tang")
    error_message = "The keyserver must layer the tang package via rpm-ostree without a reboot"
  }

  assert {
    condition     = strcontains(output.butane_config, "restorecon -RF /var/db/tang")
    error_message = "The keys volume must be relabeled after keygen or SELinux blocks the confined tangd from reading the keys"
  }

  assert {
    condition     = !strcontains(output.butane_config, "tangd.socket.d")
    error_message = "tangd.socket must keep its stock port; SELinux denies tangd binds outside the shipped policy"
  }

  assert {
    condition     = strcontains(output.butane_config, "path: /var/db/tang")
    error_message = "The Tang signing keys must be mounted from the persistent volume so they survive reprovision"
  }

  assert {
    condition     = !strcontains(output.butane_config, "k3s server")
    error_message = "A keyserver must not run k3s"
  }
}

run "tang_firewall_opens_only_the_tang_port" {
  command = plan

  variables {
    k3s         = { enable = false }
    data_volume = { enable = true }
    tang = {
      enable      = true
      allowed_ips = ["203.0.113.10/32"]
    }
  }

  assert {
    condition     = length([for r in hcloud_firewall.this["acme-app-green-fw"].rule : r if r.port == "80" && tolist(r.source_ips) == tolist(["203.0.113.10/32"])]) == 1
    error_message = "The keyserver firewall must open the stock Tang port only to the allowlist"
  }

  assert {
    condition     = length([for r in hcloud_firewall.this["acme-app-green-fw"].rule : r if r.port == "443"]) == 0
    error_message = "A keyserver must not expose the k3s ingress ports"
  }
}

run "tang_requires_a_persistent_data_volume" {
  command = plan

  variables {
    k3s         = { enable = false }
    data_volume = { enable = false }
    tang        = { enable = true }
  }

  expect_failures = [var.tang]
}

run "install_fingerprint_drives_replacement" {
  command = plan

  assert {
    condition     = hcloud_server.this.user_data == "#install-fingerprint ${sha256(output.butane_config)}"
    error_message = "user_data must carry the butane fingerprint so any install-config change forces an ordered same-address replacement of the server"
  }
}

run "firewall_is_keyed_by_name_so_rename_replaces_it" {
  command = plan

  assert {
    condition     = hcloud_firewall.this["acme-app-green-fw"].name == "acme-app-green-fw"
    error_message = "The firewall must be keyed by its name so renaming the host replaces the firewall instead of updating it in place, which the provider mishandles for rule sets"
  }

  assert {
    condition     = output.firewall_id == "1"
    error_message = "firewall_id output must resolve through the name-keyed firewall"
  }
}
