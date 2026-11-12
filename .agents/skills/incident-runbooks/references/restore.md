# Restore from kopiur backups

A: whole cluster from R2. B: one claim. C: a retired VolSync restic repository. Fields marked
UNVERIFIED and all `.status` paths are in no manifest here: check `kubectl explain restore.spec`.

## Rules for every restore

- **Cache** at least min(snapshot size, ~6.2 GiB UNVERIFIED plateau), or the restore fails for
  good. **Mover uid/gid** = the claim's file ownership, not the app's `runAsUser`, or it fails
  closed. Take both from the overlay (`KOPIUR_CACHE_CAPACITY`, `KOPIUR_PUID`/`KOPIUR_PGID`).
- **Standing Restores (`<APP>-kopiur-dst`) are `ssa: IfNotPresent`**: after a Git change delete
  and reconcile them (snippet below). A Restore owns no data; deleting one never touches a claim.
- **Never delete a kopiur `Snapshot` CR**: that deletes the kopia snapshot.
- **Delete every completed Restore**: while it exists, kopiur keeps a copy of the repository
  credentials in the app namespace and `KopiurProjectedCredentialsLeaking` pages ~13 h later.

Recreate every standing Restore from Git (used in A and B):

```bash
kubectl get restore -A -o json | jq -r '.items[] | select(.metadata.name | endswith("-kopiur-dst"))
  | [.metadata.namespace, .metadata.name, .metadata.labels["kustomize.toolkit.fluxcd.io/name"],
     .metadata.labels["kustomize.toolkit.fluxcd.io/namespace"]] | @tsv' |
while read -r ns name ks ksns; do kubectl -n "$ns" delete restore "$name"; flux reconcile ks "$ks" -n "$ksns"; done
```

Hand-written Restore (A steps 10-11, B steps 3 and 9). `<APP>` is the overlay's `APP`:

```yaml
apiVersion: kopiur.home-operations.com/v1alpha1
kind: Restore
metadata:   # the label only on a scratch restore: cleanup selects on it
  {name: <claim>-restore-<yyyymmdd>, namespace: <ns>, labels: {fm.homeops/restore-drill: <claim>}}
spec:
  repository: {kind: ClusterRepository, name: <ceph|r2>}   # must match the policy's repository
  credentialProjection: {enabled: true}   # without it the CR goes green and the mover fails
  source:   # asOf is UNVERIFIED; offset: 0 instead means the newest snapshot
    fromPolicy: {name: <APP>-<ceph|r2>, asOf: "<T_LOSS>"}
  target:
    pvcRef: {name: <claim>}     # UNVERIFIED. In place, app at 0
    # Scratch instead (UNVERIFIED; new claim, cannot touch a live one), and no options:
    # pvc: {name: <claim>-scratch, accessModes: ["ReadWriteOnce"], capacity: <live size>, storageClassName: ceph-block}
  options: {enableFileDeletion: true}   # UNVERIFIED. In place only: drops what a fresh app wrote
  policy: {onMissingSnapshot: Fail}   # Continue yields an empty volume that looks restored
  mover:
    podSecurityContext: {runAsUser: <uid>, runAsGroup: <gid>, fsGroup: <gid>}
    cache: {mode: Ephemeral, capacity: <KOPIUR_CACHE_CAPACITY>}
```

Wait: `kubectl -n <ns> wait --for=jsonpath='{.status.phase}'=Completed restore.kopiur.home-operations.com/<name> --timeout=60m`

## A. Whole cluster from R2

When Ceph's data is gone (section 3 of
`kubernetes/apps/base/rook-ceph/rook-ceph/backup/RECOVERY-PROCEDURES.md`). A
fresh Ceph gets an empty `ceph` repository, so every standing Restore fails closed
(`KopiurRestoreFailed`): fix it with the DR commit, not a retry. Claims without kopiur stay empty.

1. Stop the old cluster writing r2 (two clusters must never maintain one repository): power it
   off, or suspend `hr/kopiur` there and scale `deploy/kopiur-controller` in `system` to 0.
2. Record `T_LOSS` (UTC, RFC3339): the last moment the old cluster was healthy.
3. Check every field of 1Password `Homelab` items `kopiur-r2`, `kopiur-ceph` and `cluster` has a
   value: an empty field syncs as a healthy, empty Secret.
4. Optional: `kopia snapshot list --all` read-only against R2 bucket `kopiur`; note each
   identity's newest snapshot at or before `T_LOSS`.
5. Land the DR-mode commit on `main` BEFORE bootstrap or reconcile (Flux creates Restores from
   whatever `main` says first):
   ```diff
   # kubernetes/components/kopiur/ceph/restore.yaml
   -    name: ceph
   +    name: r2
   -      name: "${APP}-ceph"
   +      name: "${APP}-r2"
   # kubernetes/apps/base/system/kopiur/repository/clusterrepository.yaml, r2 block
   -  mode: ReadWrite
   +  mode: ReadOnly        # no backups or maintenance on the last good copy
   # kubernetes/components/kopiur/r2/snapshotpolicy.yaml, under spec
   +  suspend: true         # UNVERIFIED field: no r2 backups or retention until verified
   ```
   Same commit: Postgres, per the comment above `bootstrap:` in
   `kubernetes/apps/base/database/cloudnative-pg/cluster-18/cluster-18.yaml`.
   If the NAS is lost too, the only Postgres copy is the R2 mirror (`cloudnative-pg/offsite-mirror/README.md`).
6. Bootstrap case: `just bootstrap cluster`, wait for Ceph `HEALTH_OK`, then Kustomizations
   `kopiur` and `kopiur-repository` in `system`. In-place case (Kubernetes survived): once the DR
   commit has reconciled, run the recreate snippet (old Restores may still read `ceph`, or say
   `Continue`), then rebuild each claim with B steps 6-10. UNVERIFIED: never drilled.
7. Gate: `kubectl get clusterrepository r2 -o jsonpath='{.status.phase} {.status.uniqueId}'` is
   `Ready` and the old uniqueId (UNVERIFIED: `caccc0cb2ab28d2d60e684eefc22ba4143ba3888ca78cb7d7f724460e6af6ae4`).
   `RepositoryNotInitialized`: fix the 1Password item, never set `create.enabled: true` on r2.
   Another uniqueId: stop, wrong repository. (`ceph` gets a new one; expected.)
8. Watch the populator claims (the largest takes 30-40 min):
   ```bash
   kubectl get restore -A -o 'custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase,REASON:.status.conditions[?(@.type=="Resolved")].reason,SNAP:.status.resolved.kopiaSnapshotID'
   ```
   Pass: every claimed `*-kopiur-dst` is `Completed` / `RestoreSucceeded` with the expected `SNAP`.
   `Pending` while r2 is not `Ready`: fix the repository. `Failed`: fix cache or identity, delete
   the Restore and the Pending PVC, reconcile; Flux recreates both and the claim starts over.
9. When all pass, run the recreate snippet (credential copies).
10. Any `NoSnapshotContinue`: that app got an empty volume, which the next r2 backup would make
    the newest snapshot. Make sure step 5 is live (r2 `ReadOnly`, policies suspended), then hand-restore that claim as in step 11.
11. Hand-restore the claims with no populator (they start empty): `database/surrealdb`,
    `selfhosted/paperless-ngx-media`, `selfhosted/syncthing-data`, `media/wizarr`,
    `ai/cliproxyapi`. Per claim: `flux suspend ks` and `flux suspend hr`
    the app that mounts it and scale it to 0; apply the hand-written Restore (`r2`, `<APP>-r2`,
    `asOf: "<T_LOSS>"` never `offset: 0`, `pvcRef`, `enableFileDeletion: true`, overlay
    uid/gid/cache); wait, check `.status.resolved.kopiaSnapshotID`, delete it, resume both.
12. Verify each claim: expected snapshot ID, the app shows its data, `.status.stats` matches what
    it should hold. `kubectl -n database get cluster postgres-18` healthy, `ContinuousArchiving=True`.
13. Exit DR mode after step 12: revert the step 5 kopiur lines (keep Postgres), wait for one ceph
    backup per claim (`KopiurBackupStaleCeph` quiet), run the recreate snippet so standing
    Restores read `ceph` again, and check each r2 policy's `status.adoption` covers its history.

## B. One claim

A lost or corrupt claim, or one whose snapshots cannot be cloned (movers stuck `Init`, fsck
`UNEXPECTED INCONSISTENCY` on `/dev/rbdNN`). This replaces the volume: never fsck live storage.

1. The owner confirms the data is disposable or the snapshot an acceptable recovery point. Check
   the newest `Succeeded` snapshot's age and stats (near-empty is not a backup):
   `kubectl -n <ns> get snapshot.kopiur.home-operations.com -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,STATS:.status.stats`
2. Inventory the live claim from the app pod; keep it out of Git and never print a credential:
   ```bash
   kubectl -n <ns> exec <pod> -c app -- sh -c 'cd <mount> && find . -xdev -type f -print0 | sort -z | xargs -0 sha256sum' > live.txt
   kubectl -n <ns> exec <pod> -c app -- sh -c 'cd <mount> && find . -xdev -type f | wc -l'   # equals wc -l live.txt
   ```
3. Prove the restore first: scratch Restore (`ceph`, `<APP>-ceph`, `offset: 0`), mount it in a
   throwaway pod `readOnly: true` on the volume source (else the fsGroup walk rewrites modes), diff
   against `live.txt`, record the snapshot ID. Scratch fails to mount too: stop, cause is upstream.
4. Pick the path. An overlay with `components/kopiur/pvc` refills the claim from the newest ceph
   snapshot through `<APP>-kopiur-dst`, unless the damage is logical (bad data already backed
   up): then, and for every other claim, use the in-place path with `asOf`.
5. Populator path: this must print `Pending` and a big enough cache, else delete the Restore:
   `kubectl -n <ns> get restore <APP>-kopiur-dst -o jsonpath='{.status.phase} {.spec.mover.cache.capacity}{"\n"}'`
6. `flux suspend ks <app> -n <ns>` and `flux suspend hr <app> -n <ns>`; scale the workload to 0
   and wait for the pod to go.
7. Delete the wedged mover Jobs, then staged clone PVCs, then the claim's VolumeSnapshots, all
   before the PVC (or ceph-csi leaves the image in the RBD trash). A kopiur `Snapshot` stuck
   `Running` blocks later backups; it goes `Failed` once its staging PVC is gone.
8. Delete the PVC. `ceph-block` reclaimPolicy is `Delete`: the image really goes.
9. `flux resume ks <app> -n <ns>` only. Populator path: wait for `<APP>-kopiur-dst` `Completed`
   with the step 3 snapshot or newer. In-place path: with the HelmRelease still suspended, apply
   the hand-written Restore (`ceph`, `<APP>-ceph`, `pvcRef`) to the empty claim and wait.
10. `flux resume hr <app> -n <ns>`; do not scale by hand.
11. Verify: re-run step 2 and diff (caches, logs, SQLite and `lost+found` may differ); the next
    ceph backup has non-zero stats; in the fsck case a clone of that snapshot mounts;
    `KopiurBackupStaleCeph` clears.
12. Clean up: delete the hand Restore or recreate the standing one; drill objects pod first,
    then Restore, then PVC (else the PVC sticks `Terminating`). Both must print nothing:
    ```bash
    kubectl get restore.kopiur.home-operations.com,pvc,pod,job -A -l fm.homeops/restore-drill
    flux get ks -A --status-selector ready=false
    ```
## C. Read a retired VolSync restic repository

51 frozen repositories in three `volsync` buckets (ceph RGW, NAS MinIO, R2), named in
`scripts/volsync-retired-expiry/ledger.yaml`.

- Read only, `restic --no-lock` `snapshots`/`ls`/`dump`/`restore`, into scratch only: some hold
  the only copy. Repository = exact segment `<name>/` (`paperless-ngx` is not `paperless-ngx-media`).
- Restore by snapshot ID, never `latest`: the 2025-05 R2 `paperless-ngx/` snapshots (UNVERIFIED IDs
  `96e0f6fc`, `e937408e`) fed the 2026-11-08 Paperless re-import and stay the fallback; later ones hold none.

1. Credentials: item `volsync-template`, vault `Homelab` (never delete or rotate it: the only
   restic passwords; never print a value). Unset `OP_SERVICE_ACCOUNT_TOKEN`: it cannot read `Homelab`.
2. Fields and URL: `git show 4b30a47e^:kubernetes/components/volsync/<ceph|minio|r2>/externalsecret.yaml`.
   From a workstation, ceph is `s3:https://s3.sklab.dev/...` (the endpoint field is in-cluster).
3. Workstation read, r2:
   ```sh
   op_field() { env -u OP_SERVICE_ACCOUNT_TOKEN op read "op://Homelab/volsync-template/$1"; }
   export AWS_ACCESS_KEY_ID="$(op_field R2_HOME_OPS_ACCESS_KEY)"
   export AWS_SECRET_ACCESS_KEY="$(op_field R2_HOME_OPS_SECRET_KEY)"
   export RESTIC_PASSWORD="$(op_field R2_VOLSYNC_RESTIC_PASSWORD)"
   export RESTIC_REPOSITORY="s3:$(op_field R2_HOME_OPS_ENDPOINT_URL)/$(op_field R2_VOLSYNC_RESTIC_REPOSITORY)/<name>"
   restic --no-lock snapshots
   restic --no-lock restore <snapshot-id> --target "$TMPDIR/restic-<name>"
   unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_PASSWORD RESTIC_REPOSITORY
   ```
4. Too large for a workstation (owner go-ahead, all labelled `fm.homeops/restore-drill`, deleted
   after): a scratch ExternalSecret extracting `volsync-template` with that template, `${APP}` and
   `${SECRET_DOMAIN}` (`sklab.dev`) replaced by hand; a `ceph-block` scratch PVC; a `restic/restic` pod with
   `envFrom` that Secret running `restic --no-lock restore <snapshot-id> --target /restore`.
5. Compare by sha256, not modes: VolSync widened group bits (`600` to `660`), so re-tighten
   credential files before use. restic restores ownership only as root.
