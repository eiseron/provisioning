# pg_luks

Provides a **LUKS-encrypted data root** (`pg_luks_mount`, default
`/var/lib/crypt`) on a single-disk host, **network-unlocked at boot via
Clevis + Tang** — no key is stored on the host disk. This is where Kamal
accessory volumes (Postgres, backups) live so their data is encrypted at rest.

A backing file is formatted as LUKS with a **break-glass passphrase**
(`pg_luks_breakglass_passphrase`), then **Clevis-bound to a Tang
server** (`pg_luks_tang_url` + `pg_luks_tang_thumbprint`, see the `tang` role).
At boot, `crypttab` (`_netdev`) + `clevis-luks-askpass` fetch the key from Tang
(McCallum-Relyea — Tang never sees the key) and unlock automatically; the
break-glass passphrase is the fallback keyslot if Tang is unreachable.

The break-glass passphrase is only consumed at **bootstrap** (the initial
`luksFormat` and `clevis luks bind`); steady-state re-runs do not require it.
Inject it once for the first provision, then **remove it from CI and keep it
offline** — later runs converge without it.

The mount is `_netdev` (ordered after the network-unlocked device) and Docker
gets a `RequiresMountsFor` drop-in, so a Kamal accessory with `restart: always`
cannot start and write in clear under the mountpoint before the encrypted mount
is in place; an unlock failure fails loud instead of silently writing
unencrypted data.

Run the Tang server on a host in a **different provider/network** than this
host (e.g. the CI runner), so a disk leak here does not also expose the key.

## Kamal accessories must bind a host path under this mount

For the encryption to cover the data, a Kamal Postgres/backup accessory must
use a **host bind path under `pg_luks_mount`** (e.g.
`/var/lib/crypt/<product>/pgdata:/var/lib/postgresql/data`), **chowned to the
postgres uid** (a root:root host bind crash-loops postgres:18), **not** a
Kamal-managed named volume (which lives outside the encrypted mount).

## Why no molecule scenario

LUKS + Clevis + Tang need loop devices, kernel crypto and a reachable Tang
server — unavailable under molecule-in-docker. Validated on real hosts during
production provisioning.
