<!-- header: icon=hard-drive -->
<!-- concept: From two claims to a shared download pipeline | database Claims | folder-sync Share | zap Assemble | hard-drive-download Import -->
<p align="center"><img src="header.svg" width="100%" alt="pvc"></p>

> The two storage claims of the download pipeline: a shared CephFS volume and SABnzbd's block scratch.

**Live facts:** <https://skrumbach.github.io/home-ops/apps/downloads/pvc/> (workloads, routes, storage, backups, secrets and alerts, generated on every merge)

## What it does

- **Provides `shared-downloads`** (RWX CephFS). Bazarr, Lidarr, Radarr, SABnzbd, Shelfmark, Sonarr and the
  `downloads-janitor` CronJob mount it.
- **Provides `sabnzbd-incomplete`** (RWO block). Only SABnzbd mounts it, for article assembly.
- **Has no backup.** The overlay includes no `kopiur` component; the scratch claim is disposable by design.

## How it works

<p align="center"><img src="concept.svg" width="100%" alt="How pvc works: 1 Claims, 2 Share, 3 Assemble, 4 Import."></p>

1. Flux applies Kustomization `downloads-pvc` after `rook-ceph-cluster`. Every app that mounts a claim lists
   `downloads-pvc` in `dependsOn`.
2. SABnzbd assembles on `sabnzbd-incomplete` and moves finished downloads to `complete` on `shared-downloads`, where
   the arrs import them.

## Settings that matter

| Claim | Class, access, size | Why |
|---|---|---|
| `shared-downloads` | `ceph-filesystem-rwx`, RWX, `2Ti` | The default `csi` subvolume group is broken by Ceph Tentacle v20.2.1 subvolume corruption. The manifest says to repoint to `ceph-filesystem` once a fixed Ceph release lands. |
| `sabnzbd-incomplete` | `ceph-block`, RWO, `1500Gi` | Assembly writes thousands of tiny `SABnzbd_article_*` files that storm the CephFS MDS journal and can stall the filesystem; block keeps that churn inside the RBD. 500Gi filled during large UHD batches and paused downloads; the reservation only consumes space when used. |

## Operate it

```bash
flux -n downloads get ks downloads-pvc
kubectl -n downloads get pvc shared-downloads sabnzbd-incomplete
```
