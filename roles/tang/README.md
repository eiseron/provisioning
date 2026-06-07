# tang

Runs a [Tang](https://github.com/latchset/tang) server for network-bound disk
unlock (Clevis). Deployed on the **CI runner host** (a different provider/
network than the production hosts) so a production disk leak does not also
expose the unlock key — Tang never sees the LUKS key (McCallum-Relyea).

Listens on `tang_port`, firewalled to `tang_allowed_ips` (the production host
IPs) only. `tang_allowed_ips` is **required** (the role asserts it is
non-empty): an empty allowlist would leave tangd reachable from the internet,
which would let anyone who leaks a production disk also unlock it. Keys are
generated on first start under `/var/db/tang`; the production host binds its
LUKS to this Tang via Clevis (see `pg_luks`).
