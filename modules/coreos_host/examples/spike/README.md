# coreos_host spike

Live throwaway-server validation of the `coreos_host` module (the rescue +
coreos-installer flow, LUKS/Tang unlock and k3s cannot be validated by
`tofu validate` alone). Run it manually against a Hetzner Cloud project with a
real token; it creates a disposable host, and you tear it down after checking.

## Run

```sh
export HCLOUD_TOKEN=<a hetzner cloud token for a THROWAWAY project>
export TF_VAR_ssh_public_key="$(cat ~/.ssh/spike.pub)"
export TF_VAR_ssh_private_key="$(cat ~/.ssh/spike)"
export TF_VAR_deploy_ssh_authorized_key="$(cat ~/.ssh/spike.pub)"

tofu init
tofu apply         # boots rescue, installs FCOS, reboots into it
```

By default k3s is on and LUKS is off (proves the core install + k3s). To also
prove disk encryption, stand up a throwaway Tang (the `tang_host` module) and
pass its address:

```sh
export TF_VAR_luks='{ tang = { url = "http://<tang-ip>:6800", thumbprint = "<thp>" } }'
```

Attach a second volume as `/dev/sdb` on the server for the LUKS device, or set
`luks.device` to a spare device.

## Validate (after apply + a couple minutes for reboot/k3s)

```sh
IP=$(tofu output -raw ipv4)
ssh core@$IP 'rpm-ostree status'                 # FCOS booted, immutable
ssh core@$IP 'sudo systemctl is-active k3s'      # active
ssh core@$IP 'sudo k3s kubectl get nodes'        # node Ready
# with LUKS:
ssh core@$IP 'findmnt /var/lib/crypt && lsblk -f | grep crypto_LUKS'
```

## Tear down

```sh
tofu destroy
```

## As a CI gate

Wire this as a MANUAL pipeline job in a scope that holds a throwaway
`HCLOUD_TOKEN` (protected variable), running `apply -> validate -> destroy`.
Never point it at the production Hetzner project or the production Tang.
