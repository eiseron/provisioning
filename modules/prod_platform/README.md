# prod_platform

Facade for an organization's **production platform**: one shared Hostinger host
plus the org-level CI variables a `*-ops` pipeline needs to provision and deploy
onto it. Wraps [`prod_host`](../prod_host) and pairs with the `pg_luks` / `tang`
Ansible roles (network-bound LUKS unlock) and the `prod-host` playbook.

It creates:
- a bootstrap SSH keypair (direct root SSH for the provision job),
- a deploy SSH keypair (Kamal authenticates as the deploy user),
- the Hostinger host (behind `enable`, so the wiring lands dormant),
- the org CI variables on `ops_project_id`: `PROD_HOST_IP`, `PROD_ANSIBLE_SSH_PRIVATE_KEY`, `DEPLOY_SSH_PUBLIC_KEY`, `PROD_LUKS_BREAKGLASS` (placeholder), `PROD_LUKS_TANG_THP`.

## Usage

```hcl
provider "hostinger" {
  api_token = var.hostinger_token
}

module "prod_platform" {
  source = "git::https://gitlab.com/eiseron/stack/provisioning.git//modules/prod_platform?ref=v0.24.0"

  name           = "example-prod"
  ops_project_id = module.ops.id
  enable         = var.enable_prod_host

  hostinger_token = var.hostinger_token
  plan            = var.prod_plan
  data_center_id  = var.prod_data_center_id
  # template_id is optional — defaults to the newest Debian template
  key_server_thumbprint = var.prod_luks_tang_thp
}
```

Per-product seat resources (app DNS, CDN bucket, deploy key handoff) consume the
outputs (`vps_ipv4`, `deploy_private_key`) and live with the product, not here.

## Design notes

- **Dormant until ready** (`enable = false`): nothing hits Hostinger; a
  cross-variable `validation` on `enable` fails the *plan* (not a half-applied
  apply) if `enable` is flipped without `hostinger_token` / `plan` /
  `data_center_id` (`template_id` defaults to the newest Debian template).
- **`PROD_HOST_IP` scope `*`**: the IP is not secret (protection is
  `protected = true`); a job without `environment: production` (e.g. the runner's
  Tang provisioner consuming it as the allowlist) must still see it.
- **Break-glass never in state**: `PROD_LUKS_BREAKGLASS` is a placeholder with
  `ignore_changes`; the operator sets the real value out of band for bootstrap
  and removes it after (a TF-generated value would persist in the state backend,
  defeating a break-glass key meant to survive an online compromise).
- **Tang thumbprint** is a runtime artifact (not secret); supply it via
  `key_server_thumbprint` once the Tang server is up.

## At-rest encryption (Tang host)

Encryption is opt-in per seat. The consumer collects a per-seat `encrypt`
flag, aggregates it (`encrypt_at_rest = anytrue(seats)`), and passes the result
to both `encrypt_db` (this module) and the `ENCRYPT_AT_REST` env of the
`prod-host` playbook — they turn on together:

- `encrypt_db = true` composes [`tang_host`](../tang_host) (a cheap, dedicated
  Hetzner box, stable unlike the CI runner) and publishes `TANG_HOST_IP` +
  `TANG_ANSIBLE_SSH_PRIVATE_KEY`;
- `ENCRYPT_AT_REST = true` makes the playbook run `pg_luks` (LUKS data root,
  Clevis-bound to that Tang host).

The key server host is created only when there is a prod host to unlock
(`enable = true`) **and** encryption is on (`encrypt_db = true`) — so the
dormant default (`enable = false`) never leaves an orphan key server, and no
seat encrypting ⇒ no key server (no cost), no LUKS.

**The caller must configure the `hcloud` provider even when `encrypt_db =
false`** (the module declares it as a requirement).

**Disabling is one-way once a host is encrypted.** Setting `encrypt_db = false`
destroys the Tang host (its keys die with it), but the prod host keeps its
`crypttab` / `_netdev` mount / docker `RequiresMountsFor` / LUKS volume — so the
next reboot hangs unlocking against a Tang that no longer exists. Only disable
**before any host is encrypted**; afterwards follow the decommission procedure
(eiseron-planning#45). The `prod-host` playbook has a tripwire that fails the
provision if `ENCRYPT_AT_REST=false` while the crypttab still has the mapper.
