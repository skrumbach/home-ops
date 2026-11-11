#!/usr/bin/env python3
"""No Flux Kustomization under kubernetes/apps/main declares spec.patches.

Prevents: a patch that renders in Git but never reaches the cluster (the cluster-apps defaults patch replaces the list).
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
overlays = sorted((ROOT / "kubernetes/apps/main").rglob("*.yaml"))
failures = [
    f"{path.relative_to(ROOT)}: Kustomization {doc['metadata']['name']} sets spec.patches, which "
    "kubernetes/clusters/main/apps.yaml replaces; move the patch into a base kustomization its path builds"
    for path in overlays
    for doc in yaml.safe_load_all(path.read_text())
    if isinstance(doc, dict) and str(doc.get("apiVersion")).startswith("kustomize.toolkit.fluxcd.io/")
    and "patches" in (doc.get("spec") or {})
]
if not overlays:
    failures.append("kubernetes/apps/main: no overlay files found")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
