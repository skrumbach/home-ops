# PROJECT KNOWLEDGE BASE

Home-ops GitOps repo for a 3-node Talos Linux Kubernetes cluster managed by Flux v2. `CLAUDE.md` is a symlink to this file. Runbooks are in [`.agents/skills/incident-runbooks/`](.agents/skills/incident-runbooks/SKILL.md); operator detail in [`talos/AGENTS.md`](talos/AGENTS.md), [`bootstrap/AGENTS.md`](bootstrap/AGENTS.md) and [`kubernetes/apps/base/ai/AGENTS.md`](kubernetes/apps/base/ai/AGENTS.md) (chat model naming).

**Core stack**: Talos Linux + Flux v2 + Cilium (CNI, BGP LoadBalancer, kube-proxy replacement, no L2 announcements) + Rook-Ceph + External Secrets Operator/1Password + Cloudflare Tunnel + External-DNS (split: `network/cloudflare-dns` public, `network/unifi-dns` internal) + kopiur (the only backup engine; VolSync removed 2026-11-01, its retired repositories kept) + Gateway API (`envoy-internal`/`envoy-external` in `network`) + kube-prometheus-stack/Loki/Grafana/Gatus in `monitoring`.

## STRUCTURE

```
.
├── kubernetes/
│   ├── apps/base/<ns>/<app>/   # manifests (19 namespaces)
│   ├── apps/main/<ns>/         # overlay: one Flux Kustomization CR per app + kustomization.yaml
│   ├── clusters/main/          # Flux entry point: meta.yaml + apps.yaml (cluster-meta -> cluster-apps)
│   └── components/             # alerts, cnpg-database, common, dragonfly, keda, kopiur (+ kopiur/pvc)
├── talos/                      # minijinja templates, rendered by `just talos`, not Flux
├── bootstrap/                  # just bootstrap stages
├── .agents/skills/             # one skill, incident-runbooks (.claude/skills is a symlink)
├── .taskfiles/                 # task domains: flux, rook, network, actions-runner
├── terraform/                  # OpenTofu stacks outside Flux (Authentik, UniFi, TrueNAS)
└── .renovate/                  # Renovate presets
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add app | `kubernetes/apps/base/{ns}/{app}/` + overlay `kubernetes/apps/main/{ns}/{app}.yaml`, then `- ./{app}.yaml` in the overlay `kustomization.yaml` |
| Enable backups | include `components/kopiur` only (`/pvc` only replaces an existing PVC manifest whose claim already has snapshots); restores: `.agents/skills/incident-runbooks/references/restore.md` |
| Namespace-wide labels | `kubernetes/components/common/namespace.yaml` (one `Namespace` named `not-used`, renamed per overlay) |
| App secrets | `{app}/app/externalsecret.yaml`, ClusterSecretStore `onepassword` |
| Bootstrap secrets | `bootstrap/kustomize/apps/security/`, `vals` resolves `ref+op://Home-Lab/1password/*` |
| Helm/OCI repos | `kubernetes/apps/base/flux-system/meta/repos/` |
| Talos config | `talos/machineconfig.yaml.j2`, `talos/nodes/*.yaml.j2`, `talos/schematic.yaml.j2` |
| Tasks | `Taskfile.yaml` + `.taskfiles/` (`task --list-all`), `.justfile` + `*/mod.just` |
| CI, branch protection | `.github/workflows/`; ruleset on `main` is applied via `gh api`, not in Git |
| Renovate | `.renovaterc.json5` + `.renovate/`; in-cluster renovate-operator is the writer |
| Authentik SSO, UniFi network (UDM), TrueNAS NAS | `terraform/authentik/`, `terraform/unifi/`, `terraform/truenas/` |
| AI stack | `kubernetes/apps/{main,base}/ai/` |
| Gatus | `monitoring/gatus`; endpoints come from the `gatus.home-operations.com/endpoint` HTTPRoute annotation |
| konflate | `flux-system/konflate`, read-only PR-review UI, internal route only; its README owns the write-back-off invariant |
| Tool versions | `.mise.toml`; resolve CLIs with `mise which <cli>` / `mise exec -- <cli>` |

## CONVENTIONS

- Every manifest starts with a `# yaml-language-server: $schema=...` comment. Prefer `kubernetes-schemas.pages.dev`, fall back to `k8s-schemas.home-operations.com`, never `crd.movishell.pl` or `fluxcd-community`.
- Commits: `type(scope): description`, types feat/fix/chore/ci/docs/refactor/test, scope is a container, helm, github-action, mise, talos, flux, deps or an app/namespace (`.commitlintrc.yaml`).
- The parent Gateway's `external-dns.kubernetes.io/target` decides the DNS record, not a route annotation.
- Task runner split is deliberate: `just` owns Talos, bootstrap and `kube` recipes; `task` owns the Rook suite and network diagnostics. Do not port one to the other.
- Storage classes: `ceph-block` (RWO), `ceph-filesystem-rwx` (RWX), `openebs-hostpath` (local); leave new claims off `ceph-filesystem`.
- Nodes `talos-1|2|3` are `10.10.10.11/12/13`; never target the VIP `10.10.10.10`.

## TRIPWIRES

Each is a warning needed before deciding to touch the subsystem.

**Secrets and access**
- **NEVER put plaintext secrets in Git.** App secrets are ExternalSecret + 1Password; bootstrap/Talos secrets are `ref+op://Home-Lab/...` via `vals`. Never seed a Secret with client-side `kubectl apply`. There is no SOPS/age path. Do not store secrets in `**/resources/**` (Renovate ignores it).
- **`Home-Lab` (vals, mise's `OP_SERVICE_ACCOUNT_TOKEN`) and `Homelab` (Connect/ESO) are different vaults: Connect cannot see `Home-Lab`, `op read` of Homelab needs `env -u OP_SERVICE_ACCOUNT_TOKEN`, and `SecretSynced` does not mean non-empty.**
- **NEVER run `find $HOME` or any other unbounded home-directory search.** Tools are mise-managed; `kubeconfig` and `talosconfig` are absent in fresh worktrees and that is normal - report and continue.
- **`kubectl`/`talosctl` default to `.mise.toml`'s read-only `~/.kube/home-ops-agent` / `~/.talos/home-ops-agent`.** `Forbidden` on a write means the read-only default is in use; a missing file means the owner has not run `scripts/agent-credentials.sh`. For a write the owner has approved in the current session, prefix `KUBECONFIG=~/.kube/home-ops-admin` / `TALOSCONFIG=~/.talos/home-ops-admin` (a `HOME_OPS_*` prefix does nothing in an agent shell).
- **NEVER run `tofu apply` or `tofu destroy` in `terraform/authentik/`, `terraform/unifi/` or `terraform/truenas/` without an explicit, current go-ahead; a green PR is not approval, and the only apply is a saved plan from `secrets-apply.vals.yaml`.** A UniFi apply can cut the cluster's VLANs (never over WiFi), an Authentik apply can lock out SSO, and a TrueNAS `force_destroy`/`allow_*` opt-in is never set unasked.
- **NEVER commit without the pre-commit hooks** (`task setup-dev-env`).

**Flux and CI**
- **NEVER run `just bootstrap cluster` / `apps` against a healthy cluster** (DR and first-time only; `bootstrap/AGENTS.md`).
- **A literal `${...}` that is not a Flux variable (Grafana `${datasource}`, shell/env tokens) fails or silently blanks the whole Kustomization at reconcile and flate does not report it:** write `$${VAR}` or set `kustomize.toolkit.fluxcd.io/substitute: disabled` on a resource with no real variables (`kubernetes/apps/base/ai/opencode/app/kustomization.yaml`).
- **`healthChecks` target the workload, never the HelmRelease, and a Kustomization that owns a kopiur claim keeps `wait` false (dependency gates like CRDs, operators and secret stores set `wait: true`).** Suspend a Kustomization before a live HelmRelease edit.
- **Deleting a Kustomization deletes its resources whatever `prune` says** (`deletionPolicy: WaitForTermination`); the guard is `kustomize.toolkit.fluxcd.io/prune: disabled` on the HelmRelease or CR.
- **Never add a helm `postRenderer: bash`** (breaks on Helm 4).
- **A Renovate bump of `talosupgrade.yaml` or `kubernetesupgrade.yaml` is an unattended node upgrade.**

**Nodes and storage**
- **`talos/*.j2` changes are not applied by Flux.** `apply-node` restages only; kernel args and extensions need `just talos upgrade-node`. `machineconfig.yaml.j2`'s 6 version pins can drift from the live cluster (tuppr drives upgrades), so applying a stale template can downgrade a node: check `kubectl get nodes -o wide` first.
- **Before any node reboot: `ceph status` HEALTH_OK and `task rook:check-osd-device-paths` clean, one node at a time.** Never `just talos shutdown-node` for planned power work (`--force`, no drain); runbook `.agents/skills/incident-runbooks/references/power-down-up.md`. A talos-3 reboot can drop the B70: power the dock first.
- **CephX and Ceph config are GitOps-only: never `ceph auth` or `ceph config set` by hand, never `security.cephx.csi: aes256k`, `keyGeneration` only increases.**
- **`rgw_sigv4_insecure` stays explicitly `"false"`, and after a Ceph bump RGW PUTs can 403 with `HEALTH_OK`.**
- **The Ceph metadata backup (`ceph-backup-pvc`) is OpenEBS hostpath; a host wipe destroys it.** Emergency steps: `kubernetes/apps/base/rook-ceph/rook-ceph/backup/RECOVERY-PROCEDURES.md`.
- **talos-3 carries a `PreferNoSchedule` taint; a hard `NoSchedule` strands drains.** A container with `limits.memory` and no `requests.memory` reserves the whole limit, so audit the Git manifest.

**Backups (silent data loss)**
- **Deleting a kopiur Snapshot CR deletes the kopia snapshot.** The PVC component is `ssa: IfNotPresent` and never sets `force: enabled`. Measure mover identity from the files or the backup fails closed. One include covers one volume. Restore: `.agents/skills/incident-runbooks/references/restore.md`.
- **The 51 retired VolSync restic repositories outlive the operator: Flux Kustomization `system/volsync` keeps its name (the OBC stays in its inventory, `prune: disabled`). Their expiry is NOT IN FORCE; `paperless-ngx` is a string prefix of `paperless-ngx-media` (and `syncthing` of `syncthing-data`), so a bare prefix match selects the sibling repo.**
- **kopiur snapshots are crash-consistent unless a `beforeSnapshot` hook exports first (surrealdb does), so a database backup is only as durable as its fsync setting.** CNPG writes every ScheduledBackup of a Cluster to its one live barman store.

**Network**
- **NEVER add a `CiliumClusterwideNetworkPolicy` with a `nodeSelector` and ingress unless `enableDefaultDeny.ingress` is false, and the selector label must survive onto the host endpoint** (`kubernetes.io/os`, `kubernetes.io/hostname` are stripped).
- **A `CiliumNetworkPolicy`/`NetworkPolicy` ingress rule must admit every Service peer's replies with no `toPorts` (cilium/cilium#47913):** `port: 53` never admits a DNS reply, and a same-node Service reply is dropped after reverse NAT.

**AI and GPU**
- **NEVER rename a DRM device node with `generic-device-plugin`'s `mountPath`, and never ship a GPU change without the VA-API check:** `kubectl -n media exec deploy/tdarr-tdarr-node -c app -- vainfo --display drm --device /dev/dri/renderD129`. VA-API consumers use `devic.es/b70-vaapi`. No DRA migration, never `adminAccess: true`.
- **The B70 has two tenants: throttle the embedding endpoint by request rate. Both llama.cpp workloads pin `--cache-ram` (chat non-zero, embeddings `0`) and `vllm` sets `GGML_SYCL_FA_ONEDNN: "0"` or host RAM leaks with no OOM. An embedding endpoint can return pure NaN with green health.**
- **LiteLLM: a config fallback bypasses every key allow-list, and a `LiteLLMModel` with no `apiKey` bills the household-metered `ANTHROPIC_API_KEY`.**
- **NEVER set `sessions.vacuum_after_prune: true` on `ai/hermes`.** Any Hermes config byte restarts it uncleanly.

**Workloads**
- **An app can be Ready while it cannot write its PVC:** an app-template pod-options key the chart does not read (e.g. `selfhostedPodOptions`, see `kubernetes/apps/base/selfhosted/rsshub/playwright/helmrelease.yaml`) is silently discarded and ships `securityContext: {}`, and `fsGroup` re-owns volume content permanently.

## COMMANDS

```bash
task setup-dev-env                 # Install tools + pre-commit hooks
task reconcile                     # Force Flux sync from Git
task flux:test:all                 # Validate Flux manifests with flate
task rook:check-disks              # Check Ceph disk status
just talos render-config talos-1   # Render a node's machine config
just talos apply-node talos-1      # Apply config (node names, not IPs)
for t in scripts/ci/*-test.py; do python3 "$t"; done   # CI tests
```

Agents default to read-only credentials. Admin writes: `KUBECONFIG=~/.kube/home-ops-admin TALOSCONFIG=~/.talos/home-ops-admin <command>` (agent, with owner approval), or `HOME_OPS_KUBECONFIG=~/.kube/home-ops-admin HOME_OPS_TALOSCONFIG=~/.talos/home-ops-admin <command>` (owner shell via mise). Setup and renewal: `scripts/agent-credentials.sh` header.

Debugging: `flux get ks -A`, `flux get hr -A`, `kubectl -n {ns} get pods -o wide`, `kubectl get snapshotpolicy,restore -A`. `kubeconfig` and `talos/talosconfig` stay gitignored for DR bootstrap only; `.private/` is local-only.

## SKILL INDEX

Skills live in `.agents/skills/<name>/SKILL.md` (`.claude/skills` is a symlink). Harnesses that do not auto-load them: read the `SKILL.md` first.

| Skill | Load when |
|---|---|
| `incident-runbooks` | restoring from kopiur backups (whole cluster, one claim, a retired VolSync restic repo), planned node power-down/up, a Ceph OSD that will not start, EMQX not forming a cluster after power loss |

## Maintaining this file

This file is loaded into every session, so it holds only structure, conventions, commands and tripwires (silent data loss, a cluster-wide outage, an unrecoverable state). A new finding goes as a comment on the manifest line it is about; it earns a tripwire here only when an agent needs it before deciding to touch the subsystem. Do not recreate `CLAUDE.md` as a separate file.
