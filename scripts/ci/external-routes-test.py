#!/usr/bin/env python3
"""Every route on the public gateway (`envoy-external`) is on the allow-list below, host and path.

Prevents: an internal admin UI or a credential-spending app exposed to the internet; exposure is a reviewed diff here.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
GATEWAY = "envoy-external"

# hostname -> path prefixes it may expose ("/" is the whole app).
ALLOWED: dict[str, set[str]] = {
    "auth.${SECRET_DOMAIN}": {"/", "/outpost.goauthentik.io"},
    "coder.${SECRET_DOMAIN}": {"/"},
    "flux-webhook.${SECRET_DOMAIN}": {"/hook/"},
    "hass.${SECRET_DOMAIN}": {"/"},
    "plex.${SECRET_DOMAIN}": {"/"},
    "seerr.${SECRET_DOMAIN}": {"/"},
    "kromgo.${SECRET_DOMAIN}": {"/badges/"},  # public read-only badges only
    "echo.${SECRET_DOMAIN}": {"/"},
    "n8n-webhook.${SECRET_DOMAIN}": {"/webhook", "/rest/oauth2-credential"},  # not the editor
    # Wizarr invite flow only; the admin UI is wizarr.${SECRET_DOMAIN} on envoy-internal.
    "join.${SECRET_DOMAIN}": {
        "/j", "/join", "/invitation", "/wizard", "/static", "/image-proxy",
        "/cinema-posters", "/reset", "/favicon.ico", "/plex/callback",
    },
}


class Loader(yaml.SafeLoader):
    """SafeLoader that tolerates a re-used anchor name (later wins), as YAML 1.2 allows."""

    def compose_node(self, parent, index):
        event = self.peek_event()
        if not isinstance(event, yaml.AliasEvent) and getattr(event, "anchor", None) in self.anchors:
            del self.anchors[event.anchor]
        return super().compose_node(parent, index)


def walk(node):
    """Every route-shaped mapping (an HTTPRoute spec or a chart's `route:` values) in a document."""
    if isinstance(node, dict) and isinstance(node.get("parentRefs"), list):
        yield node
    for value in node.values() if isinstance(node, dict) else node if isinstance(node, list) else []:
        yield from walk(value)


def paths_of(route):
    rules = route.get("rules") or [{}]
    return {((m or {}).get("path") or {}).get("value", "/") for r in rules for m in r.get("matches") or [{}]}


failures, found = [], 0
for path in sorted((ROOT / "kubernetes").rglob("*.yaml")):
    text = path.read_text()
    if GATEWAY not in text:
        continue
    where = path.relative_to(ROOT)
    for doc in yaml.load_all(text, Loader=Loader):
        if not isinstance(doc, dict):
            continue
        # A chart route's hostname may be `{{ .Release.Name }}...`.
        release = str((doc.get("spec") or {}).get("releaseName") or (doc.get("metadata") or {}).get("name", ""))
        for route in walk(doc):
            if not any(isinstance(r, dict) and r.get("name") == GATEWAY for r in route["parentRefs"]):
                continue
            found += 1
            hostnames = [h.replace("{{ .Release.Name }}", release) for h in route.get("hostnames") or []]
            if not hostnames and any(rule.get("backendRefs") for rule in route.get("rules") or []):
                failures.append(f"{where}: a hostname-less public route may only redirect (no backendRefs)")
            for host in hostnames:
                if extra := sorted(paths_of(route) - ALLOWED.get(host, set())):
                    failures.append(f"{where}: {host} paths {extra} are not on the public allow-list (ALLOWED)")
if not found:
    failures.append(f"kubernetes/: found no routes on {GATEWAY}; the walker is broken")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
