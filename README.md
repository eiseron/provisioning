# provisioning

Reusable Terraform modules and Ansible roles shared across Eiseron products.

This repository is **self-hostable**: with your own Hetzner Cloud and Cloudflare
credentials you can stand up a preview host identical to the one Eiseron runs.

## Layout

```
galaxy.yml                  Ansible collection metadata (eiseron.provisioning)
roles/                      Ansible roles (consumed as eiseron.provisioning.<role>)
roles/preview_server/       Bundle role that composes the full preview host
playbooks/preview-host.yml  Reference composition for a preview host
modules/preview_host/       Terraform module for the Hetzner Cloud host (domain-agnostic)
modules/preview_cloudflare/ Optional Cloudflare Zero Trust wiring (tunnel + Access service token)
modules/gitlab_repository/             Terraform module for a GitLab project (branch/tag protection)
modules/gitlab_repository_protected/   Same, with prevent_destroy on the project
modules/github_repository/             Terraform module for a GitHub repository (optional branch protection)
modules/github_repository_protected/   Same, with prevent_destroy on the repository
```

The Ansible roles ship as the collection **`eiseron.provisioning`**. The Terraform
module is consumed directly via a pinned `git::` source.

## Consuming the Ansible roles

Add to a consumer's `requirements.yml`, pinned to an immutable tag:

```yaml
collections:
  - name: git+https://gitlab.com/eiseron/stack/provisioning.git
    type: git
    version: v0.3.0
```

```sh
ansible-galaxy collection install -r requirements.yml
```

The fastest path is the **`preview_server`** bundle role, which stands up an
entire preview host in one include (base hardening, firewall, Docker, Traefik,
and the shared Postgres). A consumer playbook reduces to:

```yaml
- hosts: all
  become: true
  vars:
    pg_shared_user: "{{ lookup('env', 'SHARED_PG_USER') }}"
    pg_shared_password: "{{ lookup('env', 'SHARED_PG_PASSWORD') }}"
  roles:
    - eiseron.provisioning.preview_server
```

For finer control, reference the individual roles by their fully-qualified name,
e.g. `eiseron.provisioning.docker`. See `playbooks/preview-host.yml` for the full
composition that `preview_server` wraps.

## Consuming the Terraform module

```hcl
module "preview_host" {
  source = "git::https://gitlab.com/eiseron/stack/provisioning.git//modules/preview_host?ref=v0.3.0"
  # ...
}
```

## Roles

| Role | Purpose |
|------|---------|
| `preview_server` | Bundle role: composes every role below (hardening → Docker → Traefik → Postgres) to stand up a complete preview host in one include. |
| `common` | Baseline OS config; creates the unprivileged app runtime user; writes a first-boot marker. |
| `ssh` | Hardened `sshd`: key-only auth, root login disabled, restricted ciphers. |
| `hardening` | sysctl hardening, `AllowUsers`, unattended security upgrades, optional swap. |
| `ufw` | Default-deny firewall; inbound web ports limited to Cloudflare ranges. |
| `fail2ban` | SSH brute-force jail with a configurable allowlist. |
| `docker` | Docker engine + compose plugin + a periodic `docker system prune` timer. |
| `traefik` | Reverse proxy with a wildcard Let's Encrypt cert via Cloudflare DNS-01. |
| `postgres_shared` | A shared Postgres container on an internal docker network. |
| `cloudflared` | Cloudflare tunnel agent (optional ingress path). |
| `netdata` | Host metrics agent. |

## Consumer responsibilities

- **Secrets** (SSH keys, Cloudflare API token, registry credentials, Postgres
  passwords) are never stored here. Supply them at runtime via environment
  variables or SOPS-encrypted group vars in the consumer repo.
- **Application database roles** (e.g. per-tenant RLS roles) are the consumer's
  responsibility. `postgres_shared` provisions only the shared server; the
  consumer's deploy/seed step creates app-specific roles and databases.
- `traefik_acme_domains` (a non-empty list of apex domains, e.g.
  `["example.com", "example.net"]`) and `traefik_acme_email` have no defaults and
  are asserted at run time. One host can serve several zones; a single
  `traefik_acme_cf_dns_api_token` scoped to all of them issues a wildcard cert
  per zone.

## Design and security rationale

Rationale that previously lived as source comments is consolidated here.

### SSH and access
- Root SSH login is disabled; access is via an unprivileged `deploy` user
  (passwordless sudo, docker group). `sshd` is key-only (`PasswordAuthentication
  no`), Ed25519-only, `MaxAuthTries 3`.
- `AllowUsers` is restricted to `deploy`. The app runtime user (`app`, UID 1000)
  has a `nologin` shell and no SSH — it exists only to own container processes.
- When a CI runner reaches the host as `root` over SSH (e.g. preview deploys),
  set `ssh_permit_root_login: prohibit-password` and add `root` to
  `hardening_allowed_users`, otherwise the first provision locks the runner out
  of every subsequent run.

### TLS / ACME
- Traefik issues a wildcard `*.<domain>` Let's Encrypt cert per entry in
  `traefik_acme_domains` via the **DNS-01** challenge. HTTP-01 / TLS-ALPN-01
  cannot validate here because inbound is restricted to Cloudflare ranges and the
  proxy mediates requests; one wildcard emission per zone covers every preview
  slug, so a single host can serve multiple product zones.
- The `websecure` entrypoint pre-populates the cert `domains` so the cert is
  issued at startup (warm) rather than on first request. `acme.json` lives in a
  `0700` dir (lego refuses insecure ACME storage). A staging toggle
  (`traefik_acme_use_staging`) avoids the production wildcard rate limit while
  debugging.
- `traefik_acme_cf_dns_api_token` is required; an empty value is rejected so the
  host fails fast instead of half-configuring.

### Network exposure
- Traefik binds `:80`/`:443`, reached by Cloudflare's proxied A record; UFW
  limits those ports to Cloudflare IP ranges.
- Postgres listens only on the internal `postgres` docker network and publishes
  no host ports.

### Host resources
- A modest swapfile (default 2 GiB, `vm.swappiness=10`) is an OOM safety net for
  small hosts where a deploy spike (concurrent image pulls + migrations + asset
  compile) could OOM-kill live containers before host load registers. Skipped
  under containerized molecule runs.
- A systemd `docker system prune` timer (`Persistent=true` to backfill misses)
  keeps the small SSD from filling with stale images and orphaned volumes —
  disk is the tightest bound on the default `cx23`.
- sysctl: SYN cookies, `rp_filter`, no ICMP redirects, `kernel.dmesg_restrict`.
  `net.ipv4.ip_forward=1` is intentional (Docker requires it).
- Postgres data lives on a Docker-managed named volume (`postgres-shared-data`),
  not a host bind mount. The `postgres:18` image declares `VOLUME
  /var/lib/postgresql` and its entrypoint owns the data dir; a root-owned host
  bind mount makes the postgres user fail to write its data dir at startup
  (crash loop). A named volume inherits the image's ownership, so the entrypoint
  initialises it correctly with no host-permission assumptions.

### Terraform module notes
- Shrinking `server_type` to a smaller-disk type cannot be done in place
  (Hetzner rejects the change); use a one-shot
  `terraform apply -replace=module.preview_host.hcloud_server.this`. Per-MR data
  lives on docker volumes recreated by CD, so a rebuild is safe — but the host
  IPv4 changes and the consumer must update their inventory.
- The bootstrap `hcloud_ssh_key` deliberately does not ignore `public_key`
  changes, so rotating the key propagates end-to-end instead of desyncing.
- `preview_host` is domain-agnostic: it provisions only the Hetzner host. DNS,
  Cloudflare Access, and the per-zone wildcard cert are wired by the consumer
  (the eiseron-ops host owner aggregates `traefik_acme_domains`; each product's
  ops repo points its `*-preview.<zone>` record at the host IP).
- The optional `preview_cloudflare` module keeps the Cloudflare Zero Trust path
  available decoupled from the host: a cloudflared tunnel (SSH + `*.<base>` →
  traefik) and a CI Access service token. Consume it where that edge path is
  wanted; it is not required for the direct-DNS routing the host uses by default.
