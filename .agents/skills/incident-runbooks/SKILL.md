---
name: incident-runbooks
description: "Read before restoring data from kopiur backups (the whole cluster from R2 after Ceph data loss, one lost or corrupt PVC, or a file from a retired VolSync restic repository), before a planned power-down or power-up of the Talos nodes, when a Ceph OSD pod will not start (stuck Init:0/5 or CrashLoopBackOff), or when EMQX cores crashloop and do not form a cluster after a power loss. Step-by-step recovery procedures."
---

# Incident runbooks

| Symptom or task | Runbook |
|---|---|
| Ceph data lost, cluster rebuilt or OSDs wiped: restore every volume from R2 | [restore.md](references/restore.md) section A |
| One PVC lost or corrupt, or its snapshots cannot be cloned | [restore.md](references/restore.md) section B |
| Read a retired VolSync restic repository | [restore.md](references/restore.md) section C |
| Planned power-down and power-up of all nodes | [power-down-up.md](references/power-down-up.md) |
| `rook-ceph-osd-N` stuck `Init:0/5` or in `CrashLoopBackOff` | [ceph-osd-recovery.md](references/ceph-osd-recovery.md) |
| Both EMQX cores crashloop after a power loss | [emqx-power-loss.md](references/emqx-power-loss.md) |

- These are attended procedures: the owner approves each destructive step, because most cannot be undone.
- Writes need the admin kubeconfig (`AGENTS.md`); the agent default is read-only, so a write fails with `Forbidden`.
- One node and one OSD at a time, with `ceph status` checked between steps: a second failure mid-recovery is how data is lost.
