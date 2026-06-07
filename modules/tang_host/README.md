# tang_host

A small, **dedicated** Hetzner Cloud host that runs a [Tang](../../roles/tang)
server for network-bound disk unlock (Clevis) of the production host's LUKS
volume.

Dedicated on purpose: running Tang on the CI runner couples the unlock key to
the runner's lifecycle (it gets rescaled/recreated, which changes its IP and
wipes Tang's keys, breaking boot unlock). A standalone box keeps the key server
stable, and on a **different provider/network** than the production host
(Hetzner vs Hostinger) so a production disk leak does not also expose the key.

Defaults to the cheapest Hetzner type (`cax11`, Ampere ARM) — Tang only serves a
tiny HTTP advertisement, so it needs almost nothing.

```hcl
module "tang_host" {
  source = "git::https://gitlab.com/eiseron/stack/provisioning.git//modules/tang_host?ref=v0.25.0"

  name           = "example-tang"
  ssh_public_key = tls_private_key.tang_bootstrap.public_key_openssh
}
```

Provision it with host-prep roles + the `tang` role (firewalled to the
production host IP). It is only worth running when at least one database opts
into at-rest encryption.
