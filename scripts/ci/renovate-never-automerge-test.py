#!/usr/bin/env python3
"""Talos, Kubernetes, Cilium, Rook, Ceph, kopiur and trust-path bumps never automerge, for any update type.

Prevents: an unattended node upgrade, CNI or storage bump, or an unreviewed identity, secret, edge, TLS, Renovate, runner-controller or Flux bump. Replays local presets; the remote base is not covered.
"""

import fnmatch
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIVE = {  # package -> the manifest Renovate tracks it in (all docker datasource)
    "ghcr.io/siderolabs/installer": "kubernetes/apps/base/system-upgrade/tuppr/upgrades/talosupgrade.yaml",
    "ghcr.io/siderolabs/kubelet": "kubernetes/apps/base/system-upgrade/tuppr/upgrades/kubernetesupgrade.yaml",
    "quay.io/cilium/charts/cilium": "kubernetes/apps/base/kube-system/cilium/app/ocirepository.yaml",
    "ghcr.io/rook/rook-ceph": "kubernetes/apps/base/rook-ceph/rook-ceph/operator/ocirepository.yaml",
    "ghcr.io/rook/rook-ceph-cluster": "kubernetes/apps/base/rook-ceph/rook-ceph/cluster/ocirepository.yaml",
    "quay.io/ceph/ceph": "kubernetes/apps/base/rook-ceph/rook-ceph/cluster/helmrelease.yaml",
    "ghcr.io/home-operations/charts/kopiur": "kubernetes/apps/base/system/kopiur/app/ocirepository.yaml",
    "ghcr.io/pocket-id/pocket-id": "kubernetes/apps/base/security/pocket-id/app/pocketidinstance.yaml",
    "ghcr.io/aclerici38/charts/pocket-id-operator": "kubernetes/apps/base/security/pocket-id-operator/app/ocirepository.yaml",
    "ghcr.io/external-secrets/charts/external-secrets": "kubernetes/apps/base/security/external-secrets/app/ocirepository.yaml",
    "docker.io/1password/connect-api": "kubernetes/apps/base/security/onepassword-connect/app/helmrelease.yaml",
    "docker.io/1password/connect-sync": "kubernetes/apps/base/security/onepassword-connect/app/helmrelease.yaml",
    "mirror.gcr.io/envoyproxy/gateway-helm": "kubernetes/apps/base/network/envoy-gateway/app/ocirepository.yaml",
    "mirror.gcr.io/envoyproxy/envoy": "kubernetes/apps/base/network/envoy-gateway/app/envoyproxy.yaml",
    "docker.io/cloudflare/cloudflared": "kubernetes/apps/base/network/cloudflare-tunnel/app/helmrelease.yaml",
    "quay.io/jetstack/charts/cert-manager": "kubernetes/apps/base/cert-manager/cert-manager/app/ocirepository.yaml",
    "ghcr.io/mogenius/helm-charts/renovate-operator": "kubernetes/apps/base/renovate/renovate-operator/app/ocirepository.yaml",
    "ghcr.io/renovatebot/renovate": "kubernetes/apps/base/renovate/renovate-operator/jobs/renovatejob.yaml",
    "ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller":
        "kubernetes/apps/base/actions-runner-system/gha-runner-scale-set-controller/app/ocirepository.yaml",
    "ghcr.io/controlplaneio-fluxcd/charts/flux-operator": "kubernetes/apps/base/flux-system/flux-operator/app/ocirepository.yaml",
    "ghcr.io/controlplaneio-fluxcd/charts/flux-instance": "kubernetes/apps/base/flux-system/flux-instance/app/ocirepository.yaml",
    "ghcr.io/controlplaneio-fluxcd/flux-operator-manifests": "kubernetes/apps/base/flux-system/flux-instance/app/helmrelease.yaml",
}
STR = r"""\"(?:\\.|[^"\\])*\"|'(?:\\.|[^'\\])*'"""  # JSON5 strings, both quote styles


def token(m):  # JSON5 -> JSON: drop comments and trailing commas, quote bare keys and '...' strings
    s = m.group(0)
    if s[0] == "'":
        return '"' + s[1:-1].replace("\\'", "'").replace('"', '\\"') + '"'
    return s if s[0] == '"' else "" if s[0] in "/," else f'"{s}"'


def json5(path):
    text = re.sub(STR + r"|//[^\n]*|/\*[\s\S]*?\*/", token, (ROOT / path).read_text())
    return json.loads(re.sub(STR + r"|,(?=\s*[}\]])|[A-Za-z_$][\w$]*(?=\s*:)", token, text))


def name_matches(patterns, name):
    for p in patterns:
        if p.startswith("!"):
            sys.exit(f"FAIL .renovate: negated matchPackageNames {p!r} on an automerge rule is not modelled")
        regex = re.fullmatch(r"/(.*)/(i?)", p)
        if re.search(regex[1], name, re.I if regex[2] else 0) if regex else fnmatch.fnmatchcase(name, p):
            return True
    return False


def applies(rule, name, update_type, tracked):
    tests = {
        "matchDatasources": lambda v: "docker" in v,
        "matchUpdateTypes": lambda v: update_type in v,
        "matchPackageNames": lambda v: name_matches(v, name),
        "matchFileNames": lambda v: any(fnmatch.fnmatchcase(tracked, g) for g in v),
        # Not evaluable here: assume they hold on an automerge rule and not on a deny (fail closed).
        "matchCurrentVersion": lambda v: rule["automerge"] is True,
        "matchManagers": lambda v: rule["automerge"] is True,
    }
    if unknown := [k for k in rule if k.startswith(("match", "exclude")) and k not in tests]:
        sys.exit(f"FAIL .renovate: automerge rule uses {unknown}, which this test does not model: {rule}")
    return all(test(rule[key]) for key, test in tests.items() if key in rule)


config = json5(".renovaterc.json5")
rules = []
for entry in config["extends"]:
    if local := re.fullmatch(r"github>skrumbach/home-ops//(\.renovate/[\w.-]+\.json5)", entry):
        rules += json5(local.group(1)).get("packageRules", [])
    elif re.search(r"skrumbach/home-ops|\.renovate/|^local>", entry):
        sys.exit(f"FAIL .renovaterc.json5: extends {entry!r} is a local preset this test does not read")
rules += config.get("packageRules", [])
rules = [r for r in rules if "automerge" in r]
if not rules:
    sys.exit("FAIL .renovaterc.json5: no local preset with automerge rules was read")
failures = []
for name, tracked in LIVE.items():
    if not re.search(re.escape(name) + r"(?![\w./-])", (ROOT / tracked).read_text()):
        failures.append(f"{tracked}: no longer names {name}; update LIVE in this test")
    for update_type in ("patch", "minor", "major", "digest", "pinDigest"):
        last = [r["automerge"] for r in rules if applies(r, name, update_type, tracked)]
        if not last or last[-1] is not False:
            failures.append(f".renovate: {name} {update_type} updates resolve to automerge "
                            f"{last[-1] if last else 'unset'}; the last matching rule must set automerge: false")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
