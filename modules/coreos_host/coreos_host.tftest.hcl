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
