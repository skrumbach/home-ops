<!-- header: icon=camera -->
<!-- concept: From a snapshot request to a point-in-time copy | file-plus Request | camera Snapshot | hard-drive Volume | copy Copy -->
<p align="center"><img src="header.svg" width="100%" alt="snapshot-controller"></p>

> Runs the CSI snapshot controller and its CRDs, so Ceph volumes can be snapshotted and kopiur can back them up.

**Live facts:** <https://skrumbach.github.io/home-ops/apps/kube-system/snapshot-controller/> (workloads, routes, storage, backups, secrets and alerts, generated on every merge)

## What it does

- **Installs the snapshot CRDs** (`VolumeSnapshot`, `VolumeSnapshotContent`, `VolumeSnapshotClass`). The chart
  default `installCRDs` is `true` and the manifest does not change it.
- **Runs the controller** (Deployment `snapshot-controller`) that turns a `VolumeSnapshot` into a
  `VolumeSnapshotContent` through the CSI driver.
- **Feeds kopiur.** The `kopiur` Kustomization depends on it, because `copyMethod: Snapshot` backups take CSI
  VolumeSnapshots. The kopiur `SnapshotPolicy` objects name class `csi-ceph-blockpool` by default.

## How it works

<p align="center"><img src="concept.svg" width="100%" alt="How snapshot-controller works: 1 Request, 2 Snapshot, 3 Volume, 4 Copy."></p>

<details>
<summary><b>Resource graph</b>: every object involved, by name</summary>

```mermaid
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#0D102C','primaryTextColor':'#E9ECF7','primaryBorderColor':'#22D8F0','lineColor':'#8B55F5','secondaryColor':'#151941','tertiaryColor':'#090C22','edgeLabelBackground':'#151941'}}}%%
flowchart LR
  oci["OCIRepository<br/>snapshot-controller"] --> hr["HelmRelease<br/>snapshot-controller"]
  hr --> dep{{"Deployment<br/>snapshot-controller"}}
  hr -->|installs| crd["CRDs<br/>volumesnapshots and classes"]
  vsc["VolumeSnapshotClass<br/>csi-ceph-blockpool"] --> crd
  pol["SnapshotPolicy<br/>kopiur"] -->|creates| vs["VolumeSnapshot"]
  vs --> dep
  dep -->|CreateSnapshot| csi(["Ceph CSI driver"])
  rc["HelmRelease<br/>rook-ceph-cluster"] -.->|dependsOn| hr
  kp["Kustomization<br/>kopiur"] -.->|dependsOn| hr
  classDef accent fill:#0D102C,stroke:#D946E6,stroke-width:2px,color:#FFFFFF
  classDef ext fill:#090C22,stroke:#A57BFF,color:#CDD2E6
  class dep accent
  class csi ext
```

</details>

1. **Flux** applies the chart. The Kustomization health-checks Deployment `snapshot-controller`.
2. **Order.** HelmRelease `rook-ceph-cluster` and Kustomization `kopiur` both list `snapshot-controller` in
   `dependsOn`, so the CRDs exist before the `VolumeSnapshotClass` and before any backup.
3. **A snapshot.** kopiur creates a `VolumeSnapshot` of a claim. The controller asks the Ceph CSI driver for the
   snapshot and binds a `VolumeSnapshotContent`.

## Settings that matter

| Setting | Value | Why |
|---|---|---|
| `controller.resources` | request 25m CPU and 32Mi, limit 128Mi | Every limit has a request. |
| `controller.serviceMonitor.create` | `true` | Scrape metrics. |
| Kustomization `healthChecks` | Deployment `snapshot-controller` | Targets the workload, not the HelmRelease. `wait` stays unset. |

## Operate it

```bash
flux -n kube-system get ks snapshot-controller
kubectl -n kube-system get deploy snapshot-controller
kubectl get volumesnapshotclass
kubectl get volumesnapshot,volumesnapshotcontent -A
```

Upstream: [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter) •
[Piraeus chart](https://github.com/piraeusdatastore/helm-charts/tree/main/charts/snapshot-controller)
