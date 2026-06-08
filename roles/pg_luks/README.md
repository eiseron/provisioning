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

## Bootstrap recovery: `pg_luks_force_reformat`

`pg_luks_force_reformat` (default `false`) recovers an **interrupted bootstrap**:
a backing file that was `luksFormat`ted but failed at `clevis luks bind` (e.g.
formatted with a placeholder break-glass, then a thumbprint mismatch). It deletes
the backing file so the next run reformats it with the current break-glass.

It is **not** a universal safety net, and it is destructive by design. It only
removes a file that is LUKS, **has no Tang binding**, and whose mapper is
**closed**; if the mapper is open it fails loud rather than corrupting a live
volume. But a LUKS volume that holds data and merely lost its Tang binding (a
mid-rotation unbind, a manual `clevis luks unbind`) also matches "LUKS, no Tang
binding" — so enabling this flag on such a host **will delete that data**.

Therefore: enable it only for a known failed-bootstrap remnant you are sure holds
no data, run once, then **turn it off**. Do not leave it enabled.

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
