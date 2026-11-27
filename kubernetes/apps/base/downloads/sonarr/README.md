<!-- header: icon=tv -->
<!-- concept: From a wanted episode to a file on the NAS | search Wanted | send Hand off | hard-drive-download Download | folder-input Import | tv Library -->
<p align="center"><img src="header.svg" width="100%" alt="sonarr"></p>

> The TV series manager: it tracks shows, hands releases to the download client and imports finished episodes.

**Live facts:** <https://skrumbach.github.io/home-ops/apps/downloads/sonarr/> (workloads, routes, storage, backups, secrets and alerts, generated on every merge)

## What it does

- **Manages TV series** for the household. The Homepage annotation describes it as "TV shows".
- **Imports into the library** on the NAS: it mounts `shared-downloads` at `/data/downloads` and the NAS export
  `/mnt/storage/Media` on `nas.sklab.dev` at `/data/nas-media`.
- **Keeps its data in PostgreSQL**, not SQLite: role and database `sonarr` on `postgres-18-rw` in `database`,
  created by Kustomization `sonarr-db`.
- **Serves the UI** at `sonarr.sklab.dev` on `envoy-internal` only. Two sign-ins in a row: the Envoy SecurityPolicy
  `sonarr-auth` (Pocket ID client `sonarr`) gates the UI, then Sonarr's own Pocket ID login (client `sonarr-app`).
  `/api`, `/feed` and `/ping` skip the Envoy gate; Sonarr checks the API key itself.
- **Answers other apps** on Service `sonarr:8989`: `recyclarr`, `queue-watchdog` and the `ai/litellm` MCP server `arr-mcp`.

## Why it is built this way

| Choice | Why |
|---|---|
| **Database on the shared CNPG cluster** | The `sonarr-db` Kustomization creates a role and database on the shared `postgres-18` cluster. Its overlay comment: retain, so removing it never drops data. |
| **KEDA owns the replica count** | `replicas: null` keeps Helm off the Deployment. The `keda/nfs-scaler` component scales it to 0 while the NAS NFS export is unreachable and back to 1 when it returns. |
| **Auth method `Oidc`, canary for the other *arr apps** | Sonarr v5.0.0.2997 has a native OIDC login. The one allowed user is the owner's verified e-mail (`SONARR__AUTH__OIDCUSERIDENTIFIER`, from 1Password item `pocket-id`, so it is not in Git). The Envoy gate stays in front as the fallback. Back out: set `SONARR__AUTH__METHOD` to `External`. |
| **`REQUIRED: Enabled`, `TRUSTEDNETWORKS: 10.42.0.0/16`** | Trusting forwarded headers from the pod network gives Sonarr the `https` scheme for its redirect URI, but it then reads the client address from `X-Forwarded-For`, so `DisabledForLocalAddresses` would skip the login for LAN clients. API consumers use `X-Api-Key` and are unaffected. |

## How it works

<p align="center"><img src="concept.svg" width="100%" alt="How sonarr works: 1 Wanted, 2 Hand off, 3 Download, 4 Import, 5 Library."></p>

<details>
<summary><b>Resource graph</b>: every object involved, by name</summary>

```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#0D102C','primaryTextColor':'#E9ECF7','primaryBorderColor':'#22D8F0','lineColor':'#8B55F5','secondaryColor':'#151941','tertiaryColor':'#090C22','edgeLabelBackground':'#151941'}}}%%
flowchart LR
  op[("1Password<br/>items sonarr, pocket-id")] -->|ExternalSecret| sec["Secret<br/>sonarr-secret"]
  sec -->|envFrom| app{{"Deployment sonarr"}}
  db["Kustomization<br/>sonarr-db"] -->|role + database| pg[("postgres-18-rw<br/>database sonarr")]
  app --> pg
  cfg["PVC sonarr-config"] -->|kopiur Restore| app
  dl["PVC shared-downloads"] --> app
  nas[("NAS export<br/>/mnt/storage/Media")] --> app
  keda["ScaledObject<br/>sonarr-nfs"] -->|0 or 1 replicas| app
  gw["Gateway envoy-internal"] -->|sonarr.sklab.dev| app
  classDef accent fill:#0D102C,stroke:#D946E6,stroke-width:2px,color:#FFFFFF
  classDef ext fill:#090C22,stroke:#A57BFF,color:#CDD2E6
  class app accent
  class op,nas ext
```

</details>

1. Flux applies Kustomization `sonarr` after `sonarr-db`, `downloads-pvc`, `onepassword-store`, `kopiur-repository`
   and `keda`. The `kopiur/pvc` component owns PVC `sonarr-config`, so a recreated claim is filled from the newest
   backup. The HelmRelease waits for `rook-ceph-cluster`.
2. ExternalSecret `sonarr` reads 1Password item `sonarr` and builds Secret `sonarr-secret`: the `SONARR__POSTGRES__*`
   settings and `SONARR__AUTH__APIKEY`. It also reads `OWNER_EMAIL` from item `pocket-id` as
   `SONARR__AUTH__OIDCUSERIDENTIFIER`. The pocket-id operator writes Secret `sonarr-app-oidc-credentials` for client
   `sonarr-app`; the pod reads `client-id` and `client-secret` from it and reloader restarts the pod when it changes.
3. The pod runs as uid and gid `2000`, which is also the kopiur mover identity (`KOPIUR_PUID`, `KOPIUR_PGID`).
4. Series, download client and indexer settings live in the Sonarr database and UI. Git does not hold them.

## Settings that matter

All values are in [`app/helmrelease.yaml`](app/helmrelease.yaml) unless noted.

| Setting | Value | Why |
|---|---|---|
| `SONARR__AUTH__OIDCSCOPES` | `openid email` | Sonarr matches the user on the e-mail and takes it only with `email_verified=true`, which Pocket ID releases with the `email` scope. |
| `SONARR__LOG__DBENABLED` | `"False"` | The manifest records no reason. |
| `SONARR__UPDATE__BRANCH` | `develop` | The manifest records no reason. |
| Probes | `GET /ping :8989`; startup allows 30 failures at 5s | The manifest records no reason. |
| `resources` | request 20m CPU, 384Mi; limit 2Gi memory | The manifest records no reason. |
| `topologySpreadConstraints` | `maxSkew: 2`, `ScheduleAnyway`, `nodeTaintsPolicy: Honor` | The manifest comment: `Honor` filters only `NoSchedule` and `NoExecute` taints, so talos-3 stays in the spread domains and its `PreferNoSchedule` taint's score penalty keeps the pod off it. |
| `securityContext` | read-only root, all capabilities dropped; `tmp` and `add-ons` are emptyDirs | The manifest records no reason. |
| `KOPIUR_SCHEDULE_R2` (overlay) | `H 11 * * *` | Offsite copy daily in hour 11. The manifest records no reason. |

## Operate it

```bash
flux -n downloads get ks sonarr sonarr-db
flux -n downloads get hr sonarr
kubectl -n downloads get pods -l app.kubernetes.io/name=sonarr -o wide
kubectl -n downloads get scaledobject sonarr-nfs
kubectl -n downloads get snapshotpolicy,restore,pvc | grep sonarr
kubectl -n database get database,databaserole sonarr
```

Restores: [`restore.md`](../../../../../.agents/skills/incident-runbooks/references/restore.md).

Upstream: [Sonarr docs](https://wiki.servarr.com/sonarr)
