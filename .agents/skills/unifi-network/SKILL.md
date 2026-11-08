---
name: unifi-network
description: "Read before touching terraform/unifi/ or the UDM Pro SE: UniFi networks, WiFi, zone firewall policies, switch ports and the Talos bonds, DHCP reservations, hand-made UDM DNS records, the ubiquiti-community/unifi provider, adopting a controller object with an import block, or planning a UniFi change. Covers what carries the cluster, what tofu must never own, and which deletes are real."
---

# UniFi network as OpenTofu

`terraform/unifi/` describes the UDM Pro SE (`https://unifi.sklab.dev`,
Network app 11.x) with the `ubiquiti-community/unifi` provider. Flux does not
reconcile it, and nothing in CI applies it. It was adopted read-only on
2026-11-07 with terrifi and moved to ubiquiti-community on 2026-11-08
(`migration.tofu`: terrifi objects forgotten, the same objects imported).

## Tripwires

1. **No apply without an explicit, current go-ahead, and never over WiFi.**
   A clean plan or a green PR is not approval. `secrets.vals.yaml` logs in as
   `tofu-read-only` (Network view only), so a stray apply through it fails
   closed. `secrets-apply.vals.yaml` logs in as `tofu-apply` (Network admin
   only); never copy that login into `UNIFI_USER`. Apply a saved plan, wired.
2. **Some objects carry the cluster.** `k8s-01` (VLAN 1010, untagged on the
   Talos bonds), `IoT [Devices]` (VLAN 3) and `VPN_Network` (VLAN 90), both
   tagged on the bonds (`talos/nodes/*.yaml.j2`), the `MS01-0x` reservations,
   the `k8s*` / `Allow-Pods-*` policies, the `k8s-01` zone and Pro Max 48
   port 49 (the uplink LAG). A plan line touching any of these needs a reason
   before anything else. Nothing is published from the WAN (no port
   forwards, no LAN IPv6), so an ALLOW from `external` is a finding.
3. **Deletes differ by resource.** Removing a `unifi_device_port` only stops
   managing the port. Removing a `unifi_network` deletes the network
   (cluster networks carry `prevent_destroy`), and removing a `unifi_client`
   makes the controller forget the client.
4. **Not in this stack, on purpose:** the Talos bonds, Aggregation 11 and
   15+16, the disabled ports, BGP (an uploaded FRR file, `home-ops`), policy
   order, client groups, built-in zones and policies, WANs, the One-Click
   VPN and NordVPN clients, the guest network, firewall groups, Protect, and
   the ~90 clients without a fixed IP. Adding one is its own reviewed PR.
5. **external-dns owns every app record.** `network/unifi-dns` writes A and
   CNAME records plus `k8s.main.*` TXT ownership records. `dns.tofu` holds
   only records nothing in the cluster owns. Declaring an app record makes
   two writers fight.
6. **WLAN passphrases are write-only.** The read-only role cannot read them;
   1Password owns them (`WLAN_U7_*_PASSPHRASE`) and they go in as
   `passphrase_wo`, sent on create or when `passphrase_wo_version` changes.
   Setting or bumping that version reprovisions every AP. Never use
   `passphrase`, which lands in state.
7. **Updates are a full PUT from config.** A policy or network attribute the
   provider does not model is erased by the next update. Before adopting a
   policy, check its `matching_target` is modelled (WEB is).
8. **Policy order is not managed** (`index` is read-only). Every multi-policy
   zone pair holds one action, so order changes nothing; a pair that mixes
   ALLOW and BLOCK needs its order set in the UI.
9. **Zone membership is declared on the zone** (`network_ids`), never with
   `firewall_zone_id` on a network: managing both sides loops.
10. **Logins and 1Password are rate limited.** Five or six UniFi logins in a
    row return `giving up after 5 attempt(s)`; wait a few minutes. Each vals
    run spends ~9 reads of the 1Password account's 1000-per-day service
    account quota; when it is spent, run tofu through `op run --env-file`
    with the owner's desktop login. `UNIFI_API_KEY` must stay unset: the
    provider prefers it, and the field of that name is a cloud key (401).
11. **The Network app is on Early Access with daily auto-update.** The
    provider drives the controller's internal API. Re-plan after every
    Network update before trusting a plan, and prefer the Official channel.

## Where things live

| What | Path |
|---|---|
| Provider, backend, inputs | `main.tofu`, `backend.tofu` (R2, encrypted), `variables.tofu` |
| Objects | `networks.tofu`, `wlans.tofu`, `firewall.tofu`, `ports.tofu`, `clients.tofu`, `dns.tofu` |
| Adoption | `imports.tofu` (kept, inert once in state), `migration.tofu` (one-time) |
| Plan / apply env | `secrets.vals.yaml`, `secrets-apply.vals.yaml` (`Automation/unifi-terraform`, `Automation/tofu-state-r2`) |
| Conventions | `terraform/tofu.md`, skill `authentik-terraform` `references/conventions.md` |

State is `unifi/terraform.tfstate` in the R2 bucket `home-ops-tfstate`,
outside the cluster, with S3-native locking. OpenTofu encrypts state and plan
files client-side (pbkdf2 + aes_gcm, `enforced`) with `TF_STATE_PASSPHRASE`;
losing that passphrase means a fresh state rebuilt from `imports.tofu`.
`AWS_ENDPOINT_URL_S3` must resolve, or the S3 backend dials real AWS. The
`Automation` vault is readable only through the token `mise exec` loads;
a token already exported in the shell may see only `Home-Lab` (`no vault
matched`), so unset it and run vals under `mise exec`.

## Plan

```bash
cd terraform/unifi
env -u OP_SERVICE_ACCOUNT_TOKEN mise exec -- vals exec -i -f secrets.vals.yaml -- tofu init
env -u OP_SERVICE_ACCOUNT_TOKEN mise exec -- vals exec -i -f secrets.vals.yaml -- tofu plan
```

## Apply (go-ahead only)

From a wired machine. The plan file is encrypted and gitignored (`*.tfplan`).

```bash
env -u OP_SERVICE_ACCOUNT_TOKEN mise exec -- vals exec -i -f secrets-apply.vals.yaml -- tofu plan -out=unifi.tfplan
# read it: only the changes that were approved, nothing on the objects in tripwire 2
env -u OP_SERVICE_ACCOUNT_TOKEN mise exec -- vals exec -i -f secrets-apply.vals.yaml -- tofu apply unifi.tfplan
rm unifi.tfplan
```

Afterwards the read-only plan shows `No changes`.

## Adopt another object

Write an import block (networks and WLANs as `name=<name>`, ports as
`<switch mac>/<index>`, clients by MAC, the rest by ID), then let OpenTofu
write the resource in a scratch copy of the stack, outside the repo:

```bash
tofu plan -generate-config-out=generated.tf
```

Drop `null` attributes, `site` and `timeouts`; replace raw IDs with
references (`unifi_network.<name>.id`, `local.builtin_zone_ids.<zone>`,
`local.unmanaged_ids.<name>`); omit an empty `domain_name` (the provider
rejects `""`); and iterate until the plan shows only imports.

## Verify

- `./scripts/ci/tofu-validate.sh` (schema, all stacks, no credentials).
- The plan above shows imports only, or `No changes` once adopted.
