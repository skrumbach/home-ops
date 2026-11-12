# Planned power-down and power-up

Shut down while etcd and Ceph mon quorum still exist: once two nodes are off, `kubectl` and
`ceph` are unreliable, but `talosctl` still reaches each node's own API. Use node IPs, never the
VIP `10.10.10.10`. Never `just talos shutdown-node`: it runs `shutdown --force`, no cordon or drain.

## Before the first shutdown

1. `kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph -s` is `HEALTH_OK`, all OSDs up, 3 mons.
2. `task rook:check-osd-device-paths` passes.
3. `flux get ks -A` and `flux get hr -A` show nothing failing.
4. `kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd set noout` (enough for minutes;
   for hours also `norecover`, `nobackfill`, `norebalance`, `nodown`, `pause`, and scale the Ceph
   deployments to zero).
5. Wait until no backup is running (this prints nothing):
   `kubectl get snapshot.kopiur.home-operations.com -A -o json | jq -r '.items[] | select(.status.phase=="Running") | .metadata.namespace + "/" + .metadata.name'`
6. Stop new backups: `flux suspend hr kopiur -n system && kubectl -n system scale deploy/kopiur-controller --replicas=0`.
   If that does not hold, suspend each `SnapshotPolicy` (`spec.suspend: true`).
7. Long outage only: hibernate Postgres. It takes the database (and Authentik SSO) down for the
   whole window; a short cycle does not need it, since drains already switch the primary over.
   Set it only when `kubectl -n database get cluster postgres-18` is already healthy: the operator defers it otherwise.
   `kubectl -n database annotate cluster postgres-18 cnpg.io/hibernation=on --overwrite`, then check the reason:
   `kubectl -n database get cluster postgres-18 -o jsonpath='{.status.conditions[?(@.type=="cnpg.io/hibernation")].reason}'`

## Shutdown

Plain `talosctl shutdown` cordons and drains, and CNPG switches the primary away from a cordoned
node. Each call returns when that node is off. talos-3 goes last: nothing is left to fail over to,
so its pods just terminate, and WAL archiving is the safety net (hibernation closes this gap).

```bash
talosctl -n 10.10.10.11 shutdown
talosctl -n 10.10.10.12 shutdown
talosctl -n 10.10.10.13 shutdown
```

Cut power only after all three have returned.

## Power-up

1. Switch on the talos-3 B70 dock PSU first and wait 5-10 s for its fans and LED: a host that boots
   before the dock loses the GPU until a full power cycle.
2. Power talos-1 and talos-2 (quorum), then talos-3.
3. `kubectl get nodes` shows three `Ready`.
4. `ceph -s` is `HEALTH_OK` with all OSDs up; then `ceph osd unset noout` (and any other flag set).
5. `flux resume hr kopiur -n system`, then restore the replica count: resume alone may leave the
   controller at 0, and backups stop without an error.

   ```bash
   kubectl -n system scale deploy/kopiur-controller --replicas=2   # replicaCount in system/kopiur/app/helmrelease.yaml
   kubectl -n system get deploy kopiur-controller                  # 2/2
   ```

6. If hibernated: `kubectl -n database annotate cluster postgres-18 cnpg.io/hibernation=off --overwrite`,
   then wait for `kubectl -n database get cluster postgres-18` healthy, 3/3.
7. The B70 is back (99 on talos-3, 0 elsewhere):
   `kubectl get nodes -o custom-columns='NAME:.metadata.name,B70:.status.allocatable.devic\.es/b70'`
