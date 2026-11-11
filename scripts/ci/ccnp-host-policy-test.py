#!/usr/bin/env python3
"""Every CiliumClusterwideNetworkPolicy with a nodeSelector sets enableDefaultDeny ingress and egress to false.

Prevents: a host policy that puts the nodes into default-deny and locks out management (default-deny is OR-ed).
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
failures, checked = [], 0
for path in sorted((ROOT / "kubernetes").rglob("*.yaml")):
    text = path.read_text()
    if "CiliumClusterwideNetworkPolicy" not in text:
        continue
    for doc in yaml.safe_load_all(text):
        if not isinstance(doc, dict) or doc.get("kind") != "CiliumClusterwideNetworkPolicy":
            continue
        for spec in [doc.get("spec")] + list(doc.get("specs") or []):
            # Presence, not truthiness: `nodeSelector: {}` selects every host.
            if not isinstance(spec, dict) or "nodeSelector" not in spec:
                continue
            checked += 1
            deny = spec.get("enableDefaultDeny") or {}
            for direction in ("ingress", "egress"):
                if deny.get(direction) is not False:
                    failures.append(f"{path.relative_to(ROOT)}: {doc['metadata']['name']} has a nodeSelector, "
                                    f"so enableDefaultDeny.{direction} must be explicitly false")
if not checked:
    failures.append("kubernetes/: found no CiliumClusterwideNetworkPolicy with a nodeSelector to check")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
