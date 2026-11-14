# Ceph OSD will not start

Mon, auth, RGW and whole-cluster loss: `kubernetes/apps/base/rook-ceph/rook-ceph/backup/RECOVERY-PROCEDURES.md`.
A bare `ceph ...` below runs as `kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph ...`.

## Triage: which failure is it?

```bash
kubectl -n rook-ceph get pods -l app=rook-ceph-osd -o wide
```

| Pod state | Log | Failure | Go to |
|---|---|---|---|
| `Init:0/5`, never Ready | `kubectl -n rook-ceph logs <pod> -c activate` loops `no disk found with OSD ID N` | device-path drift; the disk is fine | Case A / Case B (non-destructive) |
| `CrashLoopBackOff` / `Error`, `1/2` | `kubectl -n rook-ceph logs <pod> -c osd` shows RocksDB open, then `Caught signal (Aborted)` in `OSD::load_pgs` / `BlueStore::omap_iterate` | the OSD's local store is corrupt | Store corruption (destroys that OSD) |

Never restart all OSD pods at once, and never reboot another node while one OSD is down: a
degraded cluster is exactly when the drift fallback fails.

## Device-path drift (Rook #17224)

Rook stores the by-id disk's kernel name (`/dev/nvme0n1`) in the OSD deployment's
`ROOK_BLOCK_PATH`; NVMe names reshuffle across reboots. The activate fallback searches all disks,
which works on a healthy cluster and returns empty on a degraded one. No config change fixes it.

1. Audit drift and health (`STALE` but running is harmless until that OSD restarts):

   ```bash
   task rook:check-osd-device-paths
   ```

2. Find the disk that holds OSD N: the one whose BlueStore label `whoami` is N. Run it from a
   healthy OSD pod on the same node, for each NVMe device there:

   ```bash
   kubectl -n rook-ceph exec <healthy-osd-pod> -c osd -- ceph-bluestore-tool show-label --dev /dev/nvme0n1 | grep whoami
   ```

### Case A: one OSD stuck, the others up

1. Point the deployment at that device (strategic merge, so the container index does not matter):

   ```bash
   kubectl -n rook-ceph patch deploy rook-ceph-osd-N --type=strategic -p \
     '{"spec":{"template":{"spec":{"initContainers":[{"name":"activate","env":[{"name":"ROOK_BLOCK_PATH","value":"/dev/nvme0n1"}]}]}}}}'
   ```

2. OSD deployments use `Recreate`, so the new pod waits for the old one. If it hangs
   `Terminating`:

   ```bash
   kubectl -n rook-ceph delete pod <stuck-osd-pod> --grace-period=0 --force
   ```

3. `kubectl -n rook-ceph logs <new-pod> -c activate` prints
   `ceph-volume raw activate successful for osd ID: N`, and `ceph osd tree` shows it `up`. If the
   operator later reverts the path, that is fine: the pod has activated.

### Case B: every OSD on a node down after a reboot

Fix one OSD as in Case A and let it start; Rook usually re-detects its siblings. If not, repeat
Case A per OSD.

### PGs stuck peering, `ceph pg <pgid> query` hangs

The primary's PG state machine is wedged. `ceph osd down osd.X` (X = the primary) forces a re-peer
without a pod restart, so drift does not matter; the OSD re-asserts itself `up` within seconds.

### Verify

```bash
kubectl -n rook-ceph exec <healthy-osd-pod> -c osd -- ceph-volume raw list   # this node's OSDs, not empty
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree             # osd.N up/in
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status               # HEALTH_OK
```

## Store corruption

A pg_log/pg_info OMAP record in that OSD's RocksDB no longer decodes. The OSD must load every PG
to start, so no config flag gets it past the record and `ceph-bluestore-tool fsck/repair` cannot
fix it. The fix throws away this OSD's copy and backfills it from peers.

### Pre-flight

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status                    # only this OSD down; PGs active+clean
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph device ls                 # the disk's health
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd safe-to-destroy osd.N
```

Go on only if `safe-to-destroy` says safe without reducing durability. If this OSD holds the last
copy of any PG, stop: that is `ceph-objectstore-tool` surgery, not this runbook. A failing disk
means new hardware, not a rebuild in place. No node reboot here (it would add drift).

### Recovery

Find the disk: `ceph osd metadata N | grep device_ids`, then match it to the by-id path in
`TALOS_<n>_DISKS` in `.taskfiles/rook/Taskfile.yaml`.

1. Pause the operator so it does not fight the purge:

   ```bash
   kubectl -n rook-ceph scale deploy rook-ceph-operator --replicas=0
   ```

2. Remove the OSD:

   ```bash
   kubectl -n rook-ceph scale deploy rook-ceph-osd-N --replicas=0
   kubectl -n rook-ceph delete deploy rook-ceph-osd-N
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd purge N --yes-i-really-mean-it
   ```

3. Wipe only that disk, or the operator re-activates the corrupt store. Never
   `task rook:wipe-talos-X`: it wipes every OSD on the node. The skip-prompt flag is the global
   `task --yes`, and the wipe Job uses the cluster's own Ceph image (read from the HelmRelease).

   ```bash
   task --yes rook:reset-disk disk="/dev/disk/by-id/<disk>" node="talos-X"
   ```

4. Resume the operator; it prepares the blank disk and a new `rook-ceph-osd-N` joins:

   ```bash
   kubectl -n rook-ceph scale deploy rook-ceph-operator --replicas=1
   ```

5. Watch backfill. PGs should be `active+remapped+backfilling`, not `degraded`:

   ```bash
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
   kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg stat
   ```

   Do not throttle backfill with `ceph config set`: Ceph config is GitOps-only, and a hand key
   outlives every later Git change.

### Verify

```bash
kubectl -n rook-ceph get pods -l app=rook-ceph-osd -o wide                    # osd-N 2/2, 0 restarts
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status               # HEALTH_OK, all up+in
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph crash ls-new         # no new crash for osd.N
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph crash archive-all    # clears RECENT_CRASH
```

The same `omap_iterate` crash on any other OSD means the cause is shared, not one bad store: stop
and escalate. Keep these Rook settings off: `removeOSDsIfOutAndSafeToRemove` (purges a down+out OSD
before you can inspect it), `upgradeOSDRequiresHealthyPGs` (deadlocks with drift: the stuck OSD keeps
PGs unhealthy, which blocks the update that would fix it), `skipUpgradeChecks` and
`continueUpgradeAfterChecksEvenIfNotHealthy` (they let an upgrade restart OSDs on an unhealthy cluster).
