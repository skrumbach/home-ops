#!/usr/bin/env python3
"""The postgres-18 off-site mirror copies the archive the Cluster writes: SERVER_NAME equals the archiver serverName.

Prevents: a rebuild that bumps serverName while the mirror keeps copying the old, frozen path and still succeeds.
"""

import sys
from pathlib import Path

import yaml

REL = "kubernetes/apps/base/database/cloudnative-pg"
CNPG = Path(__file__).resolve().parents[2] / REL
cluster = yaml.safe_load((CNPG / "cluster-18/cluster-18.yaml").read_text())
(archiver,) = [p["parameters"]["serverName"] for p in cluster["spec"]["plugins"] if p.get("isWALArchiver")]
cronjob = yaml.safe_load((CNPG / "offsite-mirror/cronjob.yaml").read_text())
(container,) = cronjob["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"]
mirror = {e["name"]: e.get("value") for e in container["env"]}.get("SERVER_NAME")
if mirror != archiver:
    sys.exit(f"FAIL {REL}/offsite-mirror/cronjob.yaml: SERVER_NAME {mirror!r} != archiver serverName {archiver!r}")
