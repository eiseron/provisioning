# coreos_host

Provisions a Fedora CoreOS host on Hetzner Cloud and installs it via the rescue
system, baking a per-host Ignition config to disk. The host can take the k3s
role (a single-node Kubernetes server with optional Tang-bound LUKS data volume)
or the Tang keyserver role.

## Why the install runs from the rescue system

Hetzner Cloud offers no Fedora CoreOS image, no custom-ISO upload, and no way to
deliver a per-server Ignition config to a snapshot. The supported path is
`coreos-installer`, which writes the raw FCOS image to the boot disk and embeds
the host's Ignition. That cannot run against the disk the OS booted from, so the
module boots Hetzner's rescue system (`rescue = "linux64"`), which runs entirely
from RAM and leaves `/dev/sda` free to overwrite.

The rescue system is a Debian live environment, so the install steps are shell
run over SSH (`remote-exec`) plus one out-of-band API call to leave rescue.

## Install pipeline (remote-exec, as root in rescue)

1. Switch iptables/ip6tables to legacy (the rescue kernel path Docker expects).
2. `apt-get install docker.io`.
3. Extract `butane` from its image with `docker create` + `docker cp` and run it
   natively to transpile `config.yaml` to `config.ign`.
4. Extract the `coreos-installer` root filesystem with `docker export` and run it
   under `chroot` to write FCOS to `install_device` with the embedded Ignition.

### Why binaries are extracted instead of `docker run`

The rescue kernel lacks the cgroup BPF device controller, so `runc` fails
`bpf_prog_query(BPF_CGROUP_DEVICE)` with `ENOSYS` when a container *starts* -
every runc version, and `--privileged` does not help because it is a kernel gap,
not a permission one. Containers therefore cannot be started in rescue, so the
module never starts one: it only `create`/`export`s images and runs the payload
binaries directly.

`butane` is a static Go binary and runs as-is. `coreos-installer` needs a newer
glibc than the Debian rescue provides (`GLIBC_2.39`), so it runs inside a chroot
of its own exported image rootfs, with `/dev`, `/proc`, `/sys`, `/run`
rbind-mounted in and `/etc/resolv.conf` copied in for name resolution.

## Why boot uses the Hetzner API, not an in-guest reboot

Hetzner keeps the rescue system active until it is explicitly disabled, so an
in-guest `reboot` netboots rescue *again* instead of the freshly installed disk.
The boot step calls the API to `disable_rescue`, **waits for that action to reach
`success`** (disable and reset are async; resetting first races back into rescue),
then `reset`s the server so it boots CoreOS from disk. This needs `hcloud_token`
for the same project as the module's `hcloud` provider.

## systemd `%` escaping in Ignition units

Any literal `%` in a Butane/systemd unit `ExecStart` must be doubled to `%%`, or
systemd reads it as a unit specifier and refuses to load the unit. The k3s
release URL encodes the `+` in the version tag as `%2B` for GitHub, so the module
renders it as `%%2B`; systemd then emits a literal `%2B` for `curl`. A single `%`
there fails the unit with `Failed to resolve unit specifiers ... Invalid slot`
and the k3s binary never downloads.

## Tang keyserver role

With `tang.enable`, the host serves the Network-Bound Disk Encryption
advertisement that lets encrypted k3s hosts unlock their LUKS volumes at boot.
The Butane layers the first-party Fedora `tang` package with
`rpm-ostree install --apply-live` (no reboot, the same mechanism the k3s role
uses for `k3s-selinux`), generates keys into `tang.keys_mount` on first boot,
and starts the stock `tangd.socket`.

Two SELinux constraints shape this role (FCOS runs enforcing):

- **The port is not configurable.** The policy only allows `tangd` to bind the
  port the stock socket unit ships; a custom port fails
  `Failed to create listening socket: Permission denied` and would need
  `semanage port` labeling, meaning layering `policycoreutils-python-utils`
  onto a host meant to stay minimal. The security controls are the Clevis
  thumbprint pin and the firewall allowlist, not the port number.
- **The keys volume is relabeled.** The keys live on a fresh ext4 volume
  mounted at `tang.keys_mount`; without `restorecon -RF` after keygen, the
  confined `tangd` cannot read files carrying the unlabeled filesystem
  defaults.

The signing keys must persist, or a keyserver reprovision would regenerate them
and lock every bound host out at boot, so `tang.enable` requires
`data_volume.enable`: the keys live on the persistent volume and are reused
across reprovision. A keyserver runs neither k3s nor LUKS itself (it is the root
of trust and cannot Tang-unlock against its own advertisement), so `tang.enable`
and `k3s.enable` are mutually exclusive. The firewall opens only the Tang port,
to `tang.allowed_ips` (the consumer host IPs), never the k3s ingress ports.

## Data persistence

With `data_volume.enable`, a separate Hetzner volume is attached and the LUKS
device points at its stable `/dev/disk/by-id` path. `coreos-installer` only writes
the boot disk, so the data volume survives host reprovision, which is what makes
rolling reprovision and rollback between servers possible without data loss.
