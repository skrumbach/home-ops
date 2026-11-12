#!/usr/bin/env python3
"""Every SecurityPolicy HTTPRoute target exists, and every `sectionName` names a rule of it.

Prevents: an Authentik ExtAuth gate that silently attaches to nothing. paperless-ngx and
linkwarden gate one named route rule (`app`) and leave `api` open. If a rule is renamed
or loses its `name`, the policy targets no rule and the UI it was meant to gate is
served without sign-in. A whole-route policy (esphome, syncthing, zigbee2mqtt) fails the
same way if its target name drifts from the rendered route name. flate renders both as
valid, and a Gatus check on the in-cluster Service stays green.

Routes are read from raw HTTPRoute manifests and from app-template HelmRelease
`values.route.<key>` in the same app directory (`nameOverride`, else the release name
when the release has one route, else `<release>-<key>`; matched against the live
cluster).
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "kubernetes" / "apps" / "base"


def load(path: Path) -> list[dict]:
    try:
        return [d for d in yaml.safe_load_all(path.read_text()) if isinstance(d, dict)]
    except yaml.YAMLError:
        return []


def route_rules(app_dir: Path) -> dict[str, set[str]]:
    routes: dict[str, set[str]] = {}
    for path in app_dir.rglob("*.yaml"):
        for doc in load(path):
            kind = doc.get("kind")
            if kind == "HTTPRoute":
                name = doc.get("metadata", {}).get("name", "")
                rules = doc.get("spec", {}).get("rules") or []
                routes[name] = {r.get("name") for r in rules if r.get("name")}
            elif kind == "HelmRelease":
                release = doc.get("metadata", {}).get("name", "")
                values = doc.get("spec", {}).get("values") or {}
                declared = {
                    k: v for k, v in (values.get("route") or {}).items() if isinstance(v, dict)
                }
                for key, route in declared.items():
                    name = route.get("nameOverride") or (
                        release if len(declared) == 1 else f"{release}-{key}"
                    )
                    rules = route.get("rules") or []
                    routes[name] = {r.get("name") for r in rules if r.get("name")}
    return routes


def main() -> int:
    failures: list[str] = []
    checked = 0
    for path in sorted(BASE.rglob("*.yaml")):
        for doc in load(path):
            if doc.get("kind") != "SecurityPolicy":
                continue
            for ref in doc.get("spec", {}).get("targetRefs") or []:
                section = ref.get("sectionName")
                if ref.get("kind") != "HTTPRoute":
                    continue
                checked += 1
                rules = route_rules(path.parents[1] if path.parent.name == "app" else path.parent)
                route = ref.get("name")
                rel = path.relative_to(ROOT)
                if route not in rules:
                    failures.append(f"{rel}: HTTPRoute {route} not found next to the policy")
                elif section and section not in rules[route]:
                    failures.append(
                        f"{rel}: sectionName {section} is not a rule of {route} "
                        f"(rules: {sorted(rules[route]) or 'none named'})"
                    )
    for failure in failures:
        print(f"[FAIL] {failure}")
    print(f"Summary: {checked - len(failures)} passed, {len(failures)} failed")
    return 1 if failures or checked == 0 else 0


if __name__ == "__main__":
    sys.exit(main())
