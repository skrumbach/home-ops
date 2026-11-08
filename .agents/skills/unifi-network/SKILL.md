---
name: unifi-network
description: "Read before touching terraform/unifi/ or the UDM Pro SE: UniFi networks, WiFi, zone firewall policies, DHCP reservations, hand-made UDM DNS records, the terrifi provider, adopting a controller object with an import block, or planning a UniFi change. Covers what carries the cluster, what tofu must never own, and why the plan needs ignore_changes."
---

# UniFi network as OpenTofu

`terraform/unifi/` describes the UDM Pro SE (`https://unifi.sklab.dev`,
Network app 11.x) with the `alexklibisz/terrifi` provider. Flux does not
reconcile it, and nothing in CI applies it. It was adopted read-only on
2026-11-07: 81 import blocks, plan `81 to import, 0 to change`.

## Tripwires

1. **No apply without an explicit, current go-ahead, and never over WiFi.**
   A clean plan or a green PR is not approval. `secrets.vals.yaml` logs in as
   `tofu-read-only` (Network view only), so a stray apply through it fails
   closed. `secrets-apply.vals.yaml` logs in as `tofu-apply` (Network admin
   only); never copy that login into `UNIFI_USER`. Apply a saved plan, wired.
2. **Some objects carry the cluster.** `k8s-01` (VLAN 1010, untagged on the
   Talos bonds), `IoT [Devices]` (VLAN 3) and `VPN_Network` (VLAN 90), both
   tagged on the bonds (`talos/nodes/*.yaml.j2`), the `MS01-0x` reservations,
   the `allow_bgp*` / `k8s*` / `Allow-Pods-*` policies and the `Server [Talos]`
   / `k8s-01` zones. A plan line touching any of these needs a reason before
   anything else.
3. **Not in this stack, on purpose:** switch ports and the 8 LACP groups
   (7 on the USW Pro Aggregation, the uplink on the Pro Max 48), BGP (an
   uploaded FRR file, enabled as `home-ops`), order of single-policy zone pairs, built-in zones
   and policies, WANs, the One-Click VPN and NordVPN clients, the guest
   network, firewall groups, Protect, and the ~90 clients without a fixed
   IP. Adding one is its own reviewed PR.
4. **external-dns owns every app record.** `network/unifi-dns` writes A and
   CNAME records plus `k8s.main.*` TXT ownership records. `dns.tofu` holds
   only records nothing in the cluster owns (`nas`, `media`, `pbs.server`,
   `mgnt.sklab.local`). Declaring an app record makes two writers fight.
5. **The read-only role cannot read WPA passphrases.** 1Password owns them
   (`WLAN_U7_*_PASSPHRASE`), and each wlan has `ignore_changes =
   [passphrase]`. Dropping that rewrites the passphrase and reprovisions
   every AP.
6. **Network 11 stores no `network_id` on a fixed-IP reservation; terrifi
   requires one.** `clients.tofu` derives it from the subnet and ignores
   it. A "known after apply" or empty `network_id` diff is this, not drift.
7. **terrifi does not read `policy_ids` back on import.** A freshly imported
   `terrifi_firewall_policy_order` plans `[] -> [ids]`, which rewrites the
   order. Check the list matches the UI order before applying it.
8. **An empty list is not null.** The controller keeps `ips = []` on
   `allow_bgp`; omitting it plans a write to the BGP policy. A generated
   block that plans an `[] -> null` change needs the empty list declared.
9. **Username/password logins are rate limited.** Five or six logins in a
   row return `giving up after 5 attempt(s)`; wait a couple of minutes.
   The `UNIFI_API_KEY` field in `Automation/unifi-terraform` is a Site
   Manager (cloud) key and returns 401 on the console.
10. **The Network app is on Early Access with daily auto-update.** terrifi
    drives the controller's internal API. Re-plan after every Network update
    before trusting a plan, and prefer the Official channel.

## Where things live

| What | Path |
|---|---|
| Provider, backend, inputs | `main.tofu`, `backend.tofu` (R2, encrypted), `variables.tofu` |
| Objects | `networks.tofu`, `wlans.tofu`, `firewall.tofu`, `firewall_order.tofu`, `clients.tofu`, `dns.tofu` |
| Adoption | `imports.tofu` (kept, inert once in state) |
| Plan / apply env | `secrets.vals.yaml`, `secrets-apply.vals.yaml` (`Automation/unifi-terraform`, `Automation/tofu-state-r2`) |
| Conventions | `terraform/tofu.md`, skill `authentik-terraform` `references/conventions.md` |

State is `unifi/terraform.tfstate` in the R2 bucket `home-ops-tfstate`,
outside the cluster, with S3-native locking. OpenTofu encrypts state and plan
files client-side (pbkdf2 + aes_gcm, `enforced`) with `TF_STATE_PASSPHRASE`;
losing that passphrase means a fresh state rebuilt from `imports.tofu`.
`AWS_ENDPOINT_URL_S3` must resolve, or the S3 backend dials real AWS. The
1Password items need `env -u OP_SERVICE_ACCOUNT_TOKEN` when a service-account
token is exported in the shell.

## Plan

```bash
cd terraform/unifi
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets.vals.yaml -- tofu init
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets.vals.yaml -- tofu plan
```

## Apply (go-ahead only)

From a wired machine. The plan file is encrypted and gitignored (`*.tfplan`).

```bash
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets-apply.vals.yaml -- tofu plan -out=unifi.tfplan
# read it: only the changes that were approved, nothing on the objects in tripwire 2
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets-apply.vals.yaml -- tofu apply unifi.tfplan
rm unifi.tfplan
```

Afterwards the read-only plan shows `No changes`.

## Adopt another object

The terrifi CLI (GitHub release `terrifi-cli_<version>`, checksum from the
provider's `SHA256SUMS`) reads the controller and prints `import` and
`resource` blocks. Run it outside the repo with the same `UNIFI_*`
variables plus `UNIFI_API` and `UNIFI_INSECURE=true`:

```bash
tofu show -json > /tmp/state.json   # never inside the repo
terrifi generate-imports <type> --exclude-state /tmp/state.json --exclude-default-zones
```

Replace raw controller IDs with references (`terrifi_network.<name>.id`,
`local.builtin_zone_ids.<zone>`), move secrets to variables, and iterate
until the plan shows only imports. Delete the state snapshot afterwards.

## Verify

- `./scripts/ci/tofu-validate.sh` (schema, both stacks, no credentials).
- The plan above shows imports only, or `No changes` once adopted.
