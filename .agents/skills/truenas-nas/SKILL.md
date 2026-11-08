---
name: truenas-nas
description: "Read before touching terraform/truenas/ or the TrueNAS NAS: datasets, SMB/NFS shares, local users and groups, snapshot/scrub/cron tasks, the official truenas/truenas provider, adopting a NAS object, its API keys and read-only access, or upgrading TrueNAS. Covers what the cluster depends on and the data-destroying opt-ins."
---

# TrueNAS as OpenTofu

`terraform/truenas/` describes the TrueNAS SCALE NAS (`nas.sklab.dev`,
25.10 Goldeye) with the official iXsystems provider `truenas/truenas` over the
versioned JSON-RPC API (`wss://nas.sklab.dev/api/current`, valid Let's Encrypt
certificate). Flux does not reconcile it, nothing in CI applies it. Adopted
read-only on 2026-11-08: 103 import blocks, plan `103 to import, 0 to change`.

## Tripwires

1. **No apply without an explicit, current go-ahead.** A clean plan or a green
   PR is not approval. There is no apply credential yet: `secrets.vals.yaml`
   uses the `tofu-read-only` key, so a stray apply fails closed.
2. **Never set `force_destroy`, `allow_rename_in_use` or `allow_recreate`
   without an explicit go-ahead naming the object.** They are the provider's
   only data-destroying opt-ins (its Data Safety guide). Removing a dataset from
   the code plans a destroy, which the guard refuses while it holds data.
3. **The cluster depends on the NAS.** NFS exports on 10.10.10.0/24
   (`Home-Ops`, `Volsync`, the document auto-import inbox); the `minio` app on
   `pool_ssd/MiniIO` holds the postgres-18 barman archive. Changing these
   shares or datasets is a cluster change: check `ContinuousArchiving` on
   `database/postgres-18` afterwards.
4. **Secrets and personal data stay out of Git.** Passwords and dataset
   encryption keys are write-only and never read back. Users carry
   `ignore_changes = [email, full_name, password]`; `full_name` is a
   placeholder (the provider requires it).
5. **Not in this stack, on purpose:** the pools, apps (minio, minio-console,
   restic-server, netbootxyz, tailscale), services, network, keychain SSH
   keys, API keys, the `admin` user and group, `tofu-read-only`, and built-in
   accounts.
6. **Read-only access is a group, not a role you create.** A user in the
   built-in `truenas_readonly_administrators` group gets `READONLY_ADMIN`. API
   keys belong to a user (`api_key.query` shows the owner); a key created
   while logged in as `admin` is full admin whatever its name.
7. **Generated config needs two fixes.** `-generate-config-out` writes
   LEGACY_SHARE attributes (`acl`, `durablehandle`, `guestok`, `home`,
   `hostsallow`, `hostsdeny`, `recyclebin`, `streams`, `timemachine`,
   `timemachine_quota`) on `DEFAULT_SHARE` shares, and `encryption` /
   `encryption_algorithm` on datasets with `inherit_encryption = true`. Drop
   both, or validation fails.
8. **Re-plan after every TrueNAS upgrade.** The provider is fully tested on
   25.10 and 26.0; on 26.0+ it can authenticate the key owner via SCRAM
   (`username`).

## Where things live

| What | Path |
|---|---|
| Provider, backend, inputs | `main.tofu`, `backend.tofu` (R2 key `truenas/`, encrypted), `variables.tofu` |
| Objects | `datasets.tofu`, `shares.tofu`, `accounts.tofu`, `tasks.tofu` |
| Adoption | `imports.tofu` (dataset path or numeric id; kept, inert once in state) |
| Plan env | `secrets.vals.yaml` (`Automation/truenas-terraform`, `Automation/tofu-state-r2`) |
| Conventions | `terraform/tofu.md`, skill `authentik-terraform` `references/conventions.md` |

State shares the R2 bucket `home-ops-tfstate` with the UniFi stack (skill
`unifi-network`) under its own key and its own `TF_STATE_PASSPHRASE`.

## Plan

```bash
cd terraform/truenas
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets.vals.yaml -- tofu init
env -u OP_SERVICE_ACCOUNT_TOKEN vals exec -i -f secrets.vals.yaml -- tofu plan
```

## Adopt another object

Find its id over JSON-RPC (the REST `/api/v2.0` endpoints are deprecated), add
an `import` block, and let OpenTofu write the resource outside the repo:

```bash
tofu plan -generate-config-out=/tmp/generated.tf
```

Apply the fixes from tripwire 7, keep secrets and personal data out, move the
block into the subject file, and iterate until the plan shows imports only.

## Verify

- `./scripts/ci/tofu-validate.sh` (schema, all stacks, no credentials).
- The plan above shows imports only, or `No changes` once adopted.
