#!/usr/bin/env python3
# ci: gate
"""No Flux Kustomization under kubernetes/apps/main declares spec.patches.

Prevents: a per-app patch that renders in Git but never reaches the cluster.
kubernetes/clusters/main/apps.yaml strategic-merges a defaults patch onto every
child Kustomization, and its `spec.patches` list has no merge key, so kustomize
REPLACES the child's list with the HelmRelease defaults. Found 2026-11-06: the
surrealdb SnapshotPolicies had lost their `surreal export` hooks (every backup
since 2026-09-12 crash-consistent only) and the litellm-pgvector Database CR its
`vector` extension. flate and `task flux:test:all` render the overlay as written,
so neither catches it.

Put the patch in a base kustomization the Kustomization's `path` builds
(kubernetes/apps/base/database/surrealdb/backup is the shape). Skill `flux-gitops`.

Also prevents: authentik silently regaining the automatic Helm rollback. The
HelmRelease defaults patch skips `home-ops.io/helm-remediation: manual`; a
rollback after a failed upgrade runs the old server on the migrated schema.
Asserts the selector, the label, no `rollback` and `upgrade.remediation.retries: 0`.
"""

from __future__ import annotations

import copy
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
APPS_MAIN = ROOT / "kubernetes" / "apps" / "main"
FLUX_KS_GROUP = "kustomize.toolkit.fluxcd.io/"
CLUSTER_APPS = ROOT / "kubernetes" / "clusters" / "main" / "apps.yaml"
AUTHENTIK_HR = ROOT / "kubernetes" / "apps" / "base" / "security" / "authentik" / "app" / "helmrelease.yaml"
OPT_OUT_KEY = "home-ops.io/helm-remediation"
OPT_OUT_SELECTOR = f"{OPT_OUT_KEY} notin (manual)"


def offenders(docs_by_path: dict[Path, list]) -> list[str]:
    out = []
    for path, docs in docs_by_path.items():
        for d in docs:
            if not isinstance(d, dict) or d.get("kind") != "Kustomization":
                continue
            if not str(d.get("apiVersion", "")).startswith(FLUX_KS_GROUP):
                continue
            if "patches" in (d.get("spec") or {}):
                name = (d.get("metadata") or {}).get("name", "?")
                out.append(f"{path.relative_to(ROOT)}: Kustomization {name}")
    return out


def helm_defaults_targets(cluster_apps_docs: list) -> list:
    """Targets of the HelmRelease patches cluster-apps writes into every child Kustomization."""
    out = []
    for d in cluster_apps_docs:
        if not isinstance(d, dict) or (d.get("metadata") or {}).get("name") != "cluster-apps":
            continue
        for outer in (d.get("spec") or {}).get("patches") or []:
            inner = yaml.safe_load(outer.get("patch") or "") or {}
            for p in (inner.get("spec") or {}).get("patches") or []:
                target = p.get("target") or {}
                if target.get("kind") == "HelmRelease":
                    out.append(target)
    return out


def remediation_problems(cluster_apps_docs: list, authentik_docs: list) -> list[str]:
    problems = []
    targets = helm_defaults_targets(cluster_apps_docs)
    if not targets:
        problems.append("cluster-apps: no HelmRelease defaults patch found")
    for t in targets:
        if t.get("labelSelector") != OPT_OUT_SELECTOR:
            problems.append(f"cluster-apps: HelmRelease defaults labelSelector is not {OPT_OUT_SELECTOR!r}")
    hrs = [d for d in authentik_docs if isinstance(d, dict) and d.get("kind") == "HelmRelease"]
    if len(hrs) != 1:
        return problems + [f"authentik: expected one HelmRelease, found {len(hrs)}"]
    hr = hrs[0]
    if ((hr.get("metadata") or {}).get("labels") or {}).get(OPT_OUT_KEY) != "manual":
        problems.append(f"authentik: HelmRelease lacks label {OPT_OUT_KEY}: manual")
    spec = hr.get("spec") or {}
    if "rollback" in spec:
        problems.append("authentik: HelmRelease declares spec.rollback")
    rem = (spec.get("upgrade") or {}).get("remediation") or {}
    if rem.get("retries") != 0 or rem.get("remediateLastFailure") is not False:
        problems.append("authentik: upgrade.remediation must be retries: 0, remediateLastFailure: false")
    return problems


def load_overlays() -> dict[Path, list]:
    return {p: list(yaml.safe_load_all(p.read_text())) for p in sorted(APPS_MAIN.rglob("*.yaml"))}


def main() -> int:
    failed = 0
    overlays = load_overlays()
    found = offenders(overlays)
    if found:
        failed += 1
        print("[FAIL] overlay spec.patches is replaced by the cluster-apps defaults patch and never applied:")
        for line in found:
            print(f"  {line}")
        print("  Move each patch into a base kustomization the Kustomization's path builds.")
    else:
        print(f"[PASS] no Flux Kustomization in {len(overlays)} overlay files declares spec.patches")

    probe = {APPS_MAIN / "probe.yaml": [{
        "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
        "kind": "Kustomization",
        "metadata": {"name": "probe"},
        "spec": {"patches": [{"patch": "x"}]},
    }]}
    if offenders(probe):
        print("[PASS] checker refuses a probe overlay with spec.patches")
    else:
        failed += 1
        print("[FAIL] checker accepted a probe overlay with spec.patches")

    cluster_apps = list(yaml.safe_load_all(CLUSTER_APPS.read_text()))
    authentik = list(yaml.safe_load_all(AUTHENTIK_HR.read_text()))
    problems = remediation_problems(cluster_apps, authentik)
    if problems:
        failed += 1
        print("[FAIL] authentik would regain the automatic Helm rollback:")
        for line in problems:
            print(f"  {line}")
    else:
        print("[PASS] cluster-apps HelmRelease defaults skip authentik, which never rolls back")

    unlabelled = copy.deepcopy(authentik)
    for d in unlabelled:
        if isinstance(d, dict) and d.get("kind") == "HelmRelease":
            d["metadata"].pop("labels", None)
    if remediation_problems(cluster_apps, unlabelled):
        print("[PASS] checker refuses a probe authentik HelmRelease without the opt-out label")
    else:
        failed += 1
        print("[FAIL] checker accepted a probe authentik HelmRelease without the opt-out label")

    print(f"Summary: {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
