# kopiur component

Per-claim backup objects: `SnapshotPolicy`, `SnapshotSchedule`, the standing
ceph `Restore`, and (for a VolSync retirement) the PVC takeover. The operator
and repositories are `kubernetes/apps/base/system/kopiur/`.

## Invariants

- One include protects one volume. A second PVC is a second Flux Kustomization
  with `APP` set to the claim name and `path` at `components/kopiur/backup`
  (`selfhosted/syncthing.yaml` `syncthing-data-kopiur`).
- `pvc/` carries `ssa: IfNotPresent` and must never carry `force: enabled`.
  `force` deletes the volume.
- `pvc/` is not for a brand-new claim: its `Restore` is fail-closed
  (`onMissingSnapshot: Fail`), so a claim with no snapshot stays unbound for
  good. A new app starts with this component alone and a chart-owned claim with
  app-template `retain: true`, then moves to `pvc/` once it has snapshots.
- `KOPIUR_PUID` / `KOPIUR_PGID` default to 1000. Measure file ownership. A
  mismatch fails the backup closed.
- Deleting a `Snapshot` CR deletes kopia data. `onScheduleDelete: Retain`
  keeps the data, not the CRs.
- The standing `Restore` stays `Ready=False` for its whole life on a bound
  claim. Do not put this component in a Kustomization with `wait: true`.

## Moving a chart-owned claim to `pvc/`

Before: the live claim shows `helm.sh/resource-policy: keep` (`retain: true`
reconciled) and both policies have a `Succeeded` snapshot. Then, in one commit,
the persistence entry becomes `existingClaim: <claim>` (no `type`, `size`,
`storageClass`, `retain`) and the overlay adds `components/kopiur/pvc` with
`KOPIUR_CAPACITY` (and access mode, class) equal to the live claim. Helm skips
deleting a `keep` object it no longer renders; Flux skips the existing claim
(`IfNotPresent`) and, since it never labelled it, never prunes it.

Restores (whole cluster, one claim, scratch proof): `.agents/skills/incident-runbooks/references/restore.md`.
