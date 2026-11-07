#!/usr/bin/env python3
"""Every SecurityPolicy `sectionName` on an HTTPRoute names a rule that route declares.

Prevents: an Authentik ExtAuth gate that silently attaches to nothing. paperless-ngx,
linkwarden and zigbee2mqtt gate one named route rule (`app` / `code`) and leave `api` /
`app` open. If a rule is renamed or loses its `name`, the policy targets no rule and the
UI it was meant to gate is served without sign-in. flate renders that as valid.

Routes are read from raw HTTPRoute manifests and from app-template HelmRelease
`values.route.<key>` in the same app directory (key == release name or `app` -> the
release name, else `<release>-<key>`). Skill `networking`.
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
                for key, route in (values.get("route") or {}).items():
                    if not isinstance(route, dict):
                        continue
                    name = route.get("nameOverride") or (
                        release if key in ("app", release) else f"{release}-{key}"
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
                if ref.get("kind") != "HTTPRoute" or not section:
                    continue
                checked += 1
                rules = route_rules(path.parents[1] if path.parent.name == "app" else path.parent)
                route = ref.get("name")
                rel = path.relative_to(ROOT)
                if route not in rules:
                    failures.append(f"{rel}: HTTPRoute {route} not found next to the policy")
                elif section not in rules[route]:
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
