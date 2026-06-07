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
  template_id     = var.prod_template_id
  tang_thumbprint = var.prod_luks_tang_thp
}
```

Per-product seat resources (app DNS, CDN bucket, deploy key handoff) consume the
outputs (`vps_ipv4`, `deploy_private_key`) and live with the product, not here.

## Design notes

- **Dormant until ready** (`enable = false`): nothing hits Hostinger; a
  cross-variable `validation` on `enable` fails the *plan* (not a half-applied
  apply) if `enable` is flipped without `hostinger_token` / `plan` /
  `data_center_id` / `template_id`.
- **`PROD_HOST_IP` scope `*`**: the IP is not secret (protection is
  `protected = true`); a job without `environment: production` (e.g. the runner's
  Tang provisioner consuming it as the allowlist) must still see it.
- **Break-glass never in state**: `PROD_LUKS_BREAKGLASS` is a placeholder with
  `ignore_changes`; the operator sets the real value out of band for bootstrap
  and removes it after (a TF-generated value would persist in the state backend,
  defeating a break-glass key meant to survive an online compromise).
- **Tang thumbprint** is a runtime artifact (not secret); supply it via
  `tang_thumbprint` once the Tang server is up.
