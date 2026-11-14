#!/usr/bin/env python3
"""The kopiur components keep their fail-closed and keep-the-data settings.

Prevents: a restore that provisions an empty volume, a prune that deletes kopia data, Flux replacing a data claim.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
KOPIUR = "kubernetes/components/kopiur"
FLUX = "kustomize.toolkit.fluxcd.io/"
CHECKS = [  # (file, key path, required value)
    ("ceph/restore.yaml", ("spec", "policy", "onMissingSnapshot"), "Fail"),
    ("ceph/snapshotpolicy.yaml", ("spec", "deletion", "onPolicyDelete"), "Retain"),
    ("r2/snapshotpolicy.yaml", ("spec", "deletion", "onPolicyDelete"), "Retain"),
    ("ceph/snapshotschedule.yaml", ("spec", "deletion", "onScheduleDelete"), "Retain"),
    ("r2/snapshotschedule.yaml", ("spec", "deletion", "onScheduleDelete"), "Retain"),
    ("pvc/pvc.yaml", ("metadata", "labels", FLUX + "ssa"), "IfNotPresent"),
]

failures = []
for name, keys, want in CHECKS:
    node = yaml.safe_load((ROOT / KOPIUR / name).read_text())  # ${...} Flux variables load as plain strings
    for key in keys:
        node = node.get(key) if isinstance(node, dict) else None
    if node != want:
        failures.append(f"{KOPIUR}/{name}: {'.'.join(keys)} must be {want}, got {node!r}")
meta = yaml.safe_load((ROOT / KOPIUR / "pvc/pvc.yaml").read_text())["metadata"]
if any(FLUX + "force" in (meta.get(k) or {}) for k in ("labels", "annotations")):
    failures.append(f"{KOPIUR}/pvc/pvc.yaml: no {FLUX}force, or Flux deletes and recreates the data claim")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
