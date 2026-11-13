#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6,<7"]
# ///
"""Generate the documentation site's Markdown content tree from the repository.

Reads the cluster as flate renders it (every Flux Kustomization and HelmRelease, offline; Secrets and
CRDs skipped), the overlay files `kubernetes/apps/main/<ns>/<app>.yaml` (one file is one app), the
Renovate presets and a fixed list of hand-written Markdown, and writes `docs/.build/content/` for the
Hugo theme in `docs/`. Output is a pure function of the commit: same commit, byte-identical tree.

Never emits Secret data, ExternalSecret template bodies, env values or ConfigMap contents: the site
is public. Usage: scripts/docs/build.py [--out DIR] [--rendered FILE] [--repo OWNER/NAME] [--branch B]
"""

from __future__ import annotations

import argparse
import collections
import datetime
import json
import os
import posixpath
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable, Iterable

import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKLOAD_KINDS = ("Deployment", "StatefulSet", "DaemonSet", "CronJob")
PUBLIC_GATEWAY = "envoy-external"
RESTORE_RUNBOOK = ".agents/skills/incident-runbooks/references/restore.md"
# Matches a manifest comment that says a claim is deliberately left without a backup.
NO_BACKUP = re.compile(r"(?i)not backed up|unbacked|no backup|deliberately not|disposable|re-?downloadable|\bscratch\b")
NO_BACKUP_STRONG = re.compile(r"(?i)not backed up|unbacked|no backup|deliberately not")
# Home-page versions: (label, HelmRelease namespace, HelmRelease name).
VERSION_RELEASES = [
    ("Cilium", "kube-system", "cilium"),
    ("Rook-Ceph", "rook-ceph", "rook-ceph"),
    ("Envoy Gateway", "network", "envoy-gateway"),
    ("cert-manager", "cert-manager", "cert-manager"),
    ("External Secrets", "security", "external-secrets"),
    ("CloudNativePG", "database", "cloudnative-pg"),
    ("kopiur", "system", "kopiur"),
]
# Hand-written Markdown published under Operations, in this order; the rest follow alphabetically.
OPS_ORDER = [
    "AGENTS.md",
    "bootstrap/README.md",
    "bootstrap/AGENTS.md",
    "talos/AGENTS.md",
]
OPS_RUNBOOK_DIR = ".agents/skills/incident-runbooks/references/"
OPS_RECOVERY = "kubernetes/apps/base/rook-ceph/rook-ceph/backup/RECOVERY-PROCEDURES.md"
OPS_REST = [
    "kubernetes/components/kopiur/README.md",
    "scripts/add-app/README.md",
    "scripts/ci/README.md",
    ".github/workflows/README.md",
    "scripts/docs/README.md",
]


class Loader(yaml.SafeLoader):
    """SafeLoader that tolerates a re-used anchor name (later wins), as YAML 1.2 allows."""

    def compose_node(self, parent, index):
        event = self.peek_event()
        if not isinstance(event, yaml.AliasEvent) and getattr(event, "anchor", None) in self.anchors:
            del self.anchors[event.anchor]
        return super().compose_node(parent, index)


# --------------------------------------------------------------------------------------------
# Inputs


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()


def repo_slug(explicit: str | None) -> str:
    if explicit:
        return explicit
    if os.environ.get("GITHUB_REPOSITORY"):
        return os.environ["GITHUB_REPOSITORY"]
    url = git("remote", "get-url", "origin")
    match = re.search(r"github\.com[:/]([^/]+/[^/]+?)(?:\.git)?/?$", url)
    if not match:
        sys.exit(f"build.py: cannot derive OWNER/NAME from origin {url!r}; pass --repo")
    return match.group(1)


def flatten(docs: Iterable[Any]) -> list[dict]:
    out = []
    for doc in docs:
        if isinstance(doc, list):
            out.extend(flatten(doc))
        elif isinstance(doc, dict) and doc.get("kind") == "List":
            out.extend(flatten(doc.get("items") or []))
        elif isinstance(doc, dict) and doc.get("kind"):
            out.append(doc)
    return out


def load_rendered(path: str | None) -> list[dict]:
    if path:
        text = Path(path).read_text()
    else:
        flate = ["flate"] if shutil.which("flate") else ["mise", "exec", "--", "flate"]
        cmd = flate + ["build", "all", "--path", "kubernetes/clusters/main", "-o", "json", "--no-progress"]
        proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        if proc.returncode != 0:
            tail = "\n".join(proc.stderr.strip().splitlines()[-20:])
            sys.exit(f"build.py: flate failed (exit {proc.returncode}):\n{tail}")
        text = proc.stdout
    try:
        docs = [json.loads(text)]
    except json.JSONDecodeError:
        docs = list(yaml.load_all(text, Loader=Loader))
    objs = [o for o in flatten(docs) if o.get("kind") != "Secret"]  # never publish Secret data
    if not objs:
        sys.exit("build.py: the render is empty; nothing to document")
    return objs


def load_apps() -> dict[tuple[str, str], dict]:
    """(namespace, app) -> app, from the overlay files the namespace kustomization lists."""
    apps = {}
    for ns_dir in sorted((ROOT / "kubernetes/apps/main").iterdir()):
        kfile = ns_dir / "kustomization.yaml"
        if not kfile.is_file():
            continue
        listed = (yaml.load(kfile.read_text(), Loader=Loader) or {}).get("resources") or []
        for res in sorted(listed):
            path = ns_dir / res
            if not path.is_file():
                continue
            ks = []
            try:
                docs = list(yaml.load_all(path.read_text(), Loader=Loader))
            except yaml.YAMLError as exc:
                print(f"WARN {path.relative_to(ROOT)}: not valid YAML, skipped ({exc})", file=sys.stderr)
                continue
            for doc in docs:
                if not isinstance(doc, dict) or doc.get("kind") != "Kustomization":
                    continue
                meta, spec = doc.get("metadata") or {}, doc.get("spec") or {}
                own_ns = meta.get("namespace") or ns_dir.name
                spec_path = str(spec.get("path") or "").lstrip("./")
                ks.append({
                    "name": meta.get("name"),
                    "namespace": own_ns,
                    "path": spec_path,
                    "target": spec.get("targetNamespace") or own_ns,
                    "depends": sorted((d.get("namespace") or own_ns, d["name"]) for d in spec.get("dependsOn") or []),
                    "components": [posixpath.normpath(posixpath.join(spec_path, c)) for c in spec.get("components") or []],
                    "substitute": {k: str(v) for k, v in sorted(((spec.get("postBuild") or {}).get("substitute") or {}).items())},
                })
            if ks:
                key = (ns_dir.name, path.stem)
                apps[key] = {"ns": ns_dir.name, "name": path.stem, "file": str(path.relative_to(ROOT)), "ks": ks}
    return apps


def json5_load(text: str) -> Any:
    """Minimal JSON5 reader for the constructs Renovate presets use: comments, bare keys, single quotes, trailing commas."""
    pos = 0
    escapes = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f", "0": "\0"}

    def skip():
        nonlocal pos
        while pos < len(text):
            if text[pos].isspace():
                pos += 1
            elif text.startswith("//", pos):
                pos = text.find("\n", pos) if "\n" in text[pos:] else len(text)
            elif text.startswith("/*", pos):
                pos = text.index("*/", pos) + 2
            else:
                break

    def string():
        nonlocal pos
        quote, pos, out = text[pos], pos + 1, []
        while text[pos] != quote:
            ch = text[pos]
            if ch == "\\":
                nxt = text[pos + 1]
                if nxt == "u":
                    out.append(chr(int(text[pos + 2:pos + 6], 16)))
                    pos += 6
                    continue
                out.append("" if nxt == "\n" else escapes.get(nxt, nxt))
                pos += 2
                continue
            out.append(ch)
            pos += 1
        pos += 1
        return "".join(out)

    def value():
        nonlocal pos
        skip()
        ch = text[pos]
        if ch == "{":
            pos += 1
            obj = {}
            while True:
                skip()
                if text[pos] == "}":
                    pos += 1
                    return obj
                if text[pos] in "\"'":
                    key = string()
                else:
                    match = re.compile(r"[A-Za-z_$][\w$-]*").match(text, pos)
                    key, pos = match.group(0), match.end()
                skip()
                pos += 1  # ':'
                obj[key] = value()
                skip()
                if text[pos] == ",":
                    pos += 1
        if ch == "[":
            pos += 1
            arr = []
            while True:
                skip()
                if text[pos] == "]":
                    pos += 1
                    return arr
                arr.append(value())
                skip()
                if text[pos] == ",":
                    pos += 1
        if ch in "\"'":
            return string()
        match = re.compile(r"true|false|null|[-+]?(?:0x[0-9a-fA-F]+|\d+(?:\.\d*)?(?:[eE][-+]?\d+)?|\.\d+)").match(text, pos)
        if not match:
            raise ValueError(f"json5: unexpected {text[pos:pos + 20]!r}")
        pos = match.end()
        token = match.group(0)
        if token in ("true", "false", "null"):
            return {"true": True, "false": False, "null": None}[token]
        if "x" in token.lower():
            return int(token, 16)
        return float(token) if any(c in token for c in ".eE") else int(token)

    return value()


# --------------------------------------------------------------------------------------------
# Small helpers


def meta(o: dict) -> dict:
    return o.get("metadata") or {}


def name_of(o: dict) -> str:
    return str(meta(o).get("name") or "")


def ns_of(o: dict) -> str:
    return str(meta(o).get("namespace") or "")


def labels(o: dict) -> dict:
    return meta(o).get("labels") or {}


def annotations(o: dict) -> dict:
    return meta(o).get("annotations") or {}


def cell(value: Any) -> str:
    """A Markdown table cell: pipes escaped, angle brackets outside code made entities, newlines as <br>."""
    text = "" if value is None else str(value)
    text = outside_code(text, lambda s: s.replace("\\", "\\\\").replace("<", "&lt;").replace(">", "&gt;"))
    return text.replace("|", "\\|").replace("\n", "<br>").strip()


def code(value: Any) -> str:
    text = str(value)
    if not text:
        return ""
    return f"`` {text} ``" if "`" in text else f"`{text}`"


def table(headers: list[str], rows: list[list[Any]]) -> str:
    lines = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    lines += ["| " + " | ".join(cell(c) for c in row) + " |" for row in rows]
    return "\n".join(lines)


def app_url(key: tuple[str, str]) -> str:
    return f"/apps/{key[0]}/{key[1]}/"


def app_link(key: tuple[str, str], label: str | None = None) -> str:
    return f"[{label or key[1]}]({app_url(key)})"


def node_id(*parts: str) -> str:
    return "n_" + re.sub(r"\W", "_", "__".join(parts))


def short_image(image: str) -> str:
    if "@" in image:
        ref, digest = image.split("@", 1)
        algo, _, hexpart = digest.partition(":")
        return f"{ref}@{algo}:{hexpart[:12]}"
    return image


def quantity(res: dict, kind: str, field: str) -> str:
    return str(((res or {}).get(kind) or {}).get(field) or "")


def req_lim(res: dict, field: str) -> str:
    req, lim = quantity(res, "requests", field), quantity(res, "limits", field)
    return f"{req or '-'} / {lim or '-'}" if req or lim else ""


def pod_spec(o: dict) -> dict:
    spec = o.get("spec") or {}
    if o.get("kind") == "CronJob":
        spec = ((spec.get("jobTemplate") or {}).get("spec") or {})
    return ((spec.get("template") or {}).get("spec") or {})


def retention_text(ret: dict) -> str:
    order = [("keepLatest", "latest"), ("keepHourly", "hourly"), ("keepDaily", "daily"), ("keepWeekly", "weekly"),
             ("keepMonthly", "monthly"), ("keepYearly", "yearly")]
    return ", ".join(f"{ret[k]} {label}" for k, label in order if ret and k in ret)


def plain(text: str) -> str:
    """One line of plain text from a Markdown paragraph."""
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"[*_`]", "", text)
    return " ".join(text.split())


def front_matter(fields: dict) -> str:
    return "---\n" + yaml.safe_dump(fields, sort_keys=False, allow_unicode=True, width=10_000) + "---\n"


def page(title: str, weight: int, description: str, kind: str, generated: bool, body: str,
         source: str | None = None, **params: Any) -> str:
    fm_params: dict[str, Any] = {"kind": kind, "generated": generated}
    if source:
        fm_params["source"] = source
    fm_params.update(params)
    fm = {"title": title, "weight": weight, "description": " ".join(description.split()), "params": fm_params}
    return front_matter(fm) + "\n" + body.strip() + "\n"


# --------------------------------------------------------------------------------------------
# The model: every rendered object attributed to an app


def build_model(objs: list[dict], apps: dict) -> dict:
    ks_owner = {(k["namespace"], k["name"]): key for key, app in apps.items() for k in app["ks"]}
    hrs = {(ns_of(o), name_of(o)): o for o in objs if o.get("kind") == "HelmRelease"}

    def owner_of_ks(lab: dict, prefix: str) -> tuple[str, str] | None:
        name, ns = lab.get(f"{prefix}/name"), lab.get(f"{prefix}/namespace")
        return (ns, name) if name and ns else None

    def owner(o: dict) -> tuple[str, str] | None:
        lab = labels(o)
        hr = owner_of_ks(lab, "helm.toolkit.fluxcd.io")
        ann = annotations(o)
        if not hr and ann.get("meta.helm.sh/release-name"):
            hr = (ann.get("meta.helm.sh/release-namespace") or ns_of(o), ann["meta.helm.sh/release-name"])
        if not hr and lab.get("app.kubernetes.io/instance"):
            inst = lab["app.kubernetes.io/instance"]
            matches = sorted(k for k in hrs if k[1] == inst and (not ns_of(o) or k[0] == ns_of(o)))
            hr = matches[0] if matches else None
        ks = owner_of_ks(lab, "kustomize.toolkit.fluxcd.io")
        if not hr and not ks:  # an unlabelled chart hook: the longest HelmRelease name it starts with
            matches = sorted((k for k in hrs if (not ns_of(o) or k[0] == ns_of(o)) and name_of(o).startswith(k[1])),
                             key=lambda k: (-len(k[1]), k))
            hr = matches[0] if matches else None
        if hr and hr in hrs:
            ks = owner_of_ks(labels(hrs[hr]), "kustomize.toolkit.fluxcd.io") or ks
        return ks_owner.get(ks) if ks else None

    by_app: dict = collections.defaultdict(lambda: collections.defaultdict(list))
    by_kind: dict = collections.defaultdict(list)
    owners = {}
    for o in sorted(objs, key=lambda o: (o.get("kind", ""), ns_of(o), name_of(o))):
        by_kind[o["kind"]].append(o)
        key = owner(o)
        owners[(o["kind"], ns_of(o), name_of(o))] = key
        if key:
            by_app[key][o["kind"]].append(o)
    return {"apps": apps, "ks_owner": ks_owner, "by_app": by_app, "by_kind": by_kind, "owners": owners}


def owner_key(model: dict, o: dict) -> tuple[str, str] | None:
    return model["owners"].get((o.get("kind"), ns_of(o), name_of(o)))


def detect_domain(objs: list[dict]) -> str:
    counts = collections.Counter()
    for o in objs:
        if o.get("kind") == "HTTPRoute":
            for host in (o.get("spec") or {}).get("hostnames") or []:
                if "${" not in host and not host.endswith(".") and host.count(".") >= 2:
                    counts[host.split(".", 1)[1]] += 1
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[0][0] if counts else ""


def fix_host(host: str, domain: str) -> str:
    host = re.sub(r"\$\{[^}]*\}", "", str(host))
    if host.endswith(".") and domain:
        host += domain
    return host


def fix_urls(text: str, domain: str) -> str:
    return re.sub(r"(https?://)([^/:\s\"']+)", lambda m: m.group(1) + fix_host(m.group(2), domain), text)


def routes_of(model: dict, objs: list[dict], domain: str) -> list[dict]:
    """HTTPRoutes and Ingresses as plain records."""
    policies = collections.defaultdict(list)
    for p in model["by_kind"]["SecurityPolicy"]:
        spec = p.get("spec") or {}
        kinds = [label for field, label in (("extAuth", "forward-auth (extAuth)"), ("oidc", "OIDC"),
                                            ("apiKeyAuth", "API key"), ("basicAuth", "basic auth"), ("jwt", "JWT"),
                                            ("authorization", "authorization rules")) if field in spec]
        for ref in spec.get("targetRefs") or []:
            if ref.get("kind") == "HTTPRoute":
                policies[(ns_of(p), ref.get("name"))].append(f"{name_of(p)}: {', '.join(kinds) or 'policy'}")
    out = []
    for o in objs:
        spec, ann = o.get("spec") or {}, annotations(o)
        if o["kind"] == "HTTPRoute":
            gateways = sorted({r.get("name", "") for r in spec.get("parentRefs") or []})
            hosts = [h for h in (fix_host(h, domain) for h in spec.get("hostnames") or []) if h]
            paths = sorted({f"{((m or {}).get('path') or {}).get('value', '/')}"
                            for rule in spec.get("rules") or [{}] for m in rule.get("matches") or [{}]})
        elif o["kind"] == "Ingress":
            gateways = [f"ingress ({spec.get('ingressClassName') or 'default'})"]
            hosts = sorted({r.get("host") for r in spec.get("rules") or [] if r.get("host")}
                           | {h for t in spec.get("tls") or [] for h in t.get("hosts") or []})
            paths = ["/"]
        else:
            continue
        gatus = ""
        if ann.get("gatus.home-operations.com/endpoint"):
            try:
                gatus = fix_urls(str((yaml.safe_load(ann["gatus.home-operations.com/endpoint"]) or {}).get("url") or ""), domain)
            except yaml.YAMLError:
                gatus = ""
        out.append({
            "ns": ns_of(o), "name": name_of(o), "kind": o["kind"], "hosts": hosts, "gateways": gateways,
            "public": PUBLIC_GATEWAY in gateways, "paths": [] if paths == ["/"] else paths,
            "policies": sorted(policies.get((ns_of(o), name_of(o)), [])),
            "description": str(ann.get("gethomepage.dev/description") or ""), "gatus": gatus,
            "app": owner_key(model, o),
        })
    return sorted(out, key=lambda r: (r["ns"], r["name"]))


def gateway_label(gateways: list[str]) -> str:
    names = {"envoy-external": "public", "envoy-internal": "internal"}
    return ", ".join(names.get(g, g) for g in gateways)


def host_link(route: dict) -> str:
    if not route["hosts"]:
        return "(any host)"
    return f"[{route['hosts'][0]}](https://{route['hosts'][0]}/)" if "." in route["hosts"][0] else route["hosts"][0]


def chart_of(model: dict, hr: dict) -> dict:
    spec = hr.get("spec") or {}
    if spec.get("chartRef"):
        ref = spec["chartRef"]
        src_ns = ref.get("namespace") or ns_of(hr)
        repo = next((o for o in model["by_kind"].get(ref.get("kind"), []) if ns_of(o) == src_ns and name_of(o) == ref.get("name")), None)
        if not repo:
            return {"chart": ref.get("name", ""), "version": "", "url": ""}
        rspec = repo.get("spec") or {}
        ref_spec = rspec.get("ref") or {}
        version = ref_spec.get("tag") or ref_spec.get("semver") or (ref_spec.get("digest") or "")[:19]
        url = str(rspec.get("url") or "")
        return {"chart": url.rstrip("/").rsplit("/", 1)[-1], "version": str(version), "url": url}
    cspec = ((spec.get("chart") or {}).get("spec") or {})
    src = cspec.get("sourceRef") or {}
    src_ns = src.get("namespace") or ns_of(hr)
    repo = next((o for o in model["by_kind"].get(src.get("kind"), []) if ns_of(o) == src_ns and name_of(o) == src.get("name")), None)
    return {"chart": str(cspec.get("chart") or ""), "version": str(cspec.get("version") or ""),
            "url": str(((repo or {}).get("spec") or {}).get("url") or "")}


def backups_of(model: dict) -> dict[tuple[str, str], dict]:
    """(namespace, claim) -> {repo: {cron, timezone, retention, policy}} from kopiur objects."""
    schedules = {(ns_of(s), ((s.get("spec") or {}).get("policyRef") or {}).get("name")): s
                 for s in model["by_kind"]["SnapshotSchedule"]}
    out: dict = collections.defaultdict(dict)
    for p in model["by_kind"]["SnapshotPolicy"]:
        spec = p.get("spec") or {}
        repo = (spec.get("repository") or {}).get("name", "")
        sched = ((schedules.get((ns_of(p), name_of(p))) or {}).get("spec") or {}).get("schedule") or {}
        for src in spec.get("sources") or []:
            claim = (src.get("pvc") or {}).get("name")
            if claim:
                out[(ns_of(p), claim)][repo] = {
                    "policy": name_of(p), "cron": str(sched.get("cron") or ""), "timezone": str(sched.get("timezone") or ""),
                    "retention": retention_text(spec.get("retention") or {}), "app": owner_key(model, p),
                }
    return out


def schedule_text(entry: dict | None) -> str:
    if not entry:
        return ""
    return f"{entry['cron']} ({entry['timezone']})" if entry["timezone"] else entry["cron"]


def claims_of(model: dict, objs_by_kind: dict) -> list[dict]:
    """PVCs plus StatefulSet/Prometheus claim templates, as records."""
    out = []
    for o in objs_by_kind.get("PersistentVolumeClaim", []):
        spec = o.get("spec") or {}
        out.append({"ns": ns_of(o), "name": name_of(o), "size": quantity(spec.get("resources") or {}, "requests", "storage"),
                    "class": spec.get("storageClassName") or "", "access": ", ".join(spec.get("accessModes") or []),
                    "template": False, "app": owner_key(model, o), "obj": o})
    for kind in ("StatefulSet", "Prometheus", "Alertmanager"):
        for o in objs_by_kind.get(kind, []):
            spec = o.get("spec") or {}
            templates = spec.get("volumeClaimTemplates") or []
            if kind != "StatefulSet" and ((spec.get("storage") or {}).get("volumeClaimTemplate")):
                templates = [spec["storage"]["volumeClaimTemplate"]]
            for t in templates:
                tspec = t.get("spec") or {}
                out.append({"ns": ns_of(o), "name": f"{(t.get('metadata') or {}).get('name') or 'storage'} ({kind} {name_of(o)}, per replica)",
                            "size": quantity(tspec.get("resources") or {}, "requests", "storage"),
                            "class": tspec.get("storageClassName") or "", "access": ", ".join(tspec.get("accessModes") or []),
                            "template": True, "app": owner_key(model, o), "obj": o})
    return sorted(out, key=lambda c: (c["ns"], c["name"]))


def comment_blocks(lines: list[str]) -> list[tuple[int, int, str]]:
    """(first line, last line, joined text) for each run of consecutive `#` comment lines."""
    blocks, start = [], None
    for i, line in enumerate(lines + [""]):
        if line.strip().startswith("#") and "yaml-language-server:" not in line:
            start = i if start is None else start
        elif start is not None:
            text = " ".join(l.strip().lstrip("#").strip() for l in lines[start:i])
            blocks.append((start, i - 1, text))
            start = None
    return blocks


def no_backup_reason(claim: dict, app: dict | None) -> str:
    """The sentence of a manifest comment that says this claim is deliberately not backed up, if one exists.

    Looked for in the app's overlay file and base manifests: a comment that names the claim, the comments
    of the PVC document that defines it, or a comment in the `persistence:` block of the HelmRelease that
    renders it. A comment saying "not backed up" beats one that only says "scratch".
    """
    if not app or claim["template"]:
        return ""
    files = [ROOT / app["file"]]
    for k in app["ks"]:
        base = ROOT / k["path"]
        if base.is_dir() and k["path"].startswith("kubernetes/apps/base/"):
            files += sorted(base.rglob("*.yaml"))
    token = re.compile(rf"(?<![\w-]){re.escape(claim['name'])}(?![\w-])")
    defines = re.compile(rf"^\s*name:\s*['\"]?{re.escape(claim['name'])}['\"]?\s*$", re.M)
    from_helm = "helm.toolkit.fluxcd.io/name" in labels(claim["obj"])
    candidates = []
    for path in files:
        lines = path.read_text().splitlines()
        persistence = set()
        if from_helm and path.name.startswith("helmrelease"):
            indent = None
            for i, line in enumerate(lines):
                if re.match(r"^\s*persistence:\s*$", line):
                    indent = len(line) - len(line.lstrip())
                elif indent is not None and line.strip() and not line.strip().startswith("#") and len(line) - len(line.lstrip()) <= indent:
                    indent = None
                elif indent is not None:
                    persistence.add(i)
        doc_start = 0
        docs = []  # (first line, last line) of each YAML document
        for i, line in enumerate(lines + ["---"]):
            if line.startswith("---"):
                docs.append((doc_start, i - 1))
                doc_start = i + 1
        for first, last, text in comment_blocks(lines):
            doc = next(((a, b) for a, b in docs if a <= first <= b), (0, -1))
            doc_text = "\n".join(lines[doc[0]:doc[1] + 1])
            if (token.search(text) or first in persistence or
                    (re.search(r"kind:\s*PersistentVolumeClaim", doc_text) and defines.search(doc_text))):
                # The whole comment when it is short, else the sentence that says so.
                candidates += [(s, text if len(text) <= 200 else s) for s in re.split(r"(?<=[.!?])\s+", text) if NO_BACKUP.search(s)]
    strong = [shown for sentence, shown in candidates if NO_BACKUP_STRONG.search(sentence)]
    return (strong or [shown for _, shown in candidates] or [""])[0]


# --------------------------------------------------------------------------------------------
# Hand-written Markdown


def ops_sources() -> list[str]:
    runbooks = sorted(str(p.relative_to(ROOT)) for p in (ROOT / OPS_RUNBOOK_DIR).glob("*.md") if p.name != "SKILL.md")
    terraform = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "terraform").glob("*.md"))
    terraform += sorted(str(p.relative_to(ROOT)) for p in (ROOT / "terraform").glob("*/README.md"))
    rest = sorted(OPS_REST + terraform)
    ordered = OPS_ORDER + runbooks + [OPS_RECOVERY] + rest
    return [p for p in ordered if (ROOT / p).is_file()]


def ops_slug(path: str) -> str:
    stem = path[:-3]
    for prefix, repl in ((OPS_RUNBOOK_DIR, "runbook-"), ("kubernetes/apps/base/", ""), ("kubernetes/", "")):
        if stem.startswith(prefix):
            stem = repl + stem[len(prefix):]
    stem = re.sub(r"/README$", "", stem)
    slug = re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")
    return slug or "index"


def app_docs(apps: dict) -> tuple[dict, dict]:
    """In-tree Markdown under kubernetes/apps/base: {app key: [paths]} and {namespace: [paths]}."""
    dir_apps = collections.defaultdict(list)
    for key, app in apps.items():
        for k in app["ks"]:
            parts = k["path"].split("/")
            if k["path"].startswith("kubernetes/apps/base/") and len(parts) >= 5:
                dir_apps["/".join(parts[:5])].append(key)
    by_app, by_ns = collections.defaultdict(list), collections.defaultdict(list)
    for path in sorted((ROOT / "kubernetes/apps/base").rglob("*.md")):
        rel = str(path.relative_to(ROOT))
        parts = rel.split("/")
        if path.name in ("SKILL.md", "CLAUDE.md") or "resources" in parts or "skills" in parts or rel == OPS_RECOVERY:
            continue
        if len(parts) == 5 and path.name in ("README.md", "TROUBLESHOOTING.md"):
            by_ns[parts[3]].append(rel)
        elif len(parts) >= 6:
            appdir = "/".join(parts[:5])
            owners = sorted(set(dir_apps.get(appdir, [])))
            if owners:
                preferred = [k for k in owners if k[1] == parts[4]] or owners
                by_app[preferred[0]].append(rel)
    return by_app, by_ns


IMG_TAG = re.compile(r"<img\s[^>]*?>", re.I)


def html_to_markdown(line: str) -> str:
    """Raw HTML in hand-written files becomes Markdown (images, links, bold) or is dropped."""
    def img(m):
        tag = m.group(0)
        src = re.search(r"src=\"([^\"]*)\"", tag)
        alt = re.search(r"alt=\"([^\"]*)\"", tag)
        return f"![{(alt.group(1) if alt else '').replace(']', '')}]({src.group(1)})" if src else ""
    line = IMG_TAG.sub(img, line)
    line = re.sub(r"<summary>(.*?)</summary>", lambda m: f"**{re.sub(r'<[^>]+>', '', m.group(1)).strip()}**", line, flags=re.I)
    line = re.sub(r"<a\s[^>]*href=\"([^\"]*)\"[^>]*>(.*?)</a>", r"[\2](\1)", line, flags=re.I)
    line = re.sub(r"</?(b|strong)>", "**", line, flags=re.I)
    line = re.sub(r"</?(i|em)>", "_", line, flags=re.I)
    keep_br = line.lstrip().startswith("|")
    line = re.sub(r"</?(p|div|span|center|details|summary|picture|source|sup|sub|kbd|br)(\s[^>]*)?/?>",
                  lambda m: m.group(0) if keep_br and m.group(1).lower() == "br" else "", line, flags=re.I)
    return line


def outside_code(line: str, fn: Callable[[str], str]) -> str:
    parts = re.split(r"(`+[^`]*`+)", line)
    return "".join(p if p.startswith("`") else fn(p) for p in parts)


def rewrite_markdown(text: str, source: str, ctx: dict, demote: int = 0) -> str:
    """Relative links to published pages, GitHub for everything else; headings demoted; HTML converted."""
    src_dir = posixpath.dirname(source)
    slug, branch, published = ctx["repo"], ctx["branch"], ctx["published"]
    real_root = os.path.realpath(ROOT)

    def resolve(target: str, image: bool) -> str:
        if target.startswith("#") or re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith("//"):
            return target
        path, sep, anchor = target.partition("#")
        if not path:
            return target
        rel = posixpath.normpath(path.lstrip("/") if path.startswith("/") else posixpath.join(src_dir, path))
        if rel.startswith(".."):
            return target
        real = os.path.realpath(ROOT / rel)
        if real.startswith(real_root + os.sep):
            rel = os.path.relpath(real, real_root).replace(os.sep, "/")
        suffix = f"#{anchor}" if sep else ""
        if image:
            if (ROOT / rel).is_file():  # served by the site itself, from <out>/../static/files/
                ctx["images"].add(rel)
                return f"/files/{rel}"
            return f"https://raw.githubusercontent.com/{slug}/{branch}/{rel}"
        if rel in published:
            return published[rel] + suffix
        if (ROOT / rel).is_dir():
            readme = posixpath.join(rel, "README.md")
            if readme in published:
                return published[readme] + suffix
            return f"https://github.com/{slug}/tree/{branch}/{rel}"
        return f"https://github.com/{slug}/blob/{branch}/{rel}{suffix}"

    def links(line: str) -> str:
        spans = [m.span() for m in re.finditer(r"`+[^`]*`+", line)]

        def link(m):
            if any(a <= m.start() < b for a, b in spans):  # inside inline code: an example, not a link
                return m.group(0)
            return f"{m.group(1)}[{m.group(2)}]({resolve(m.group(3), bool(m.group(1)))}{m.group(4) or ''})"
        line = re.sub(r"(!?)\[((?:[^\[\]]|\[[^\]]*\])*)\]\(\s*<?([^)\s>]+)>?(\s+\"[^\"]*\")?\s*\)", link, line)
        return re.sub(r"^(\s*\[[^\]]+\]:\s*)(\S+)", lambda m: m.group(1) + resolve(m.group(2), False), line)

    out, fence, in_comment = [], None, False
    for line in text.splitlines():
        if not fence:  # HTML comments are dropped, single- or multi-line
            if in_comment:
                if "-->" not in line:
                    continue
                line, in_comment = line.split("-->", 1)[1], False
            line = re.sub(r"<!--.*?-->", "", line)
            if "<!--" in line:
                line, in_comment = line.split("<!--", 1)[0], True
        stripped = line.lstrip()
        marker = re.match(r"(`{3,}|~{3,})", stripped)
        if fence:
            if marker and stripped.startswith(fence):
                fence = None
            out.append(line)
            continue
        if marker:
            fence = marker.group(1)
            out.append(line)
            continue
        heading = re.match(r"^(#{1,6})(\s.*)$", line)
        if heading and demote:
            line = "#" * min(6, len(heading.group(1)) + demote) + heading.group(2)
        line = outside_code(line, html_to_markdown)
        out.append(links(line))
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip() + "\n"


HEADER_IMG = re.compile(r"(?:<p[^>]*>\s*)?<img\s[^>]*src=\"(?:\./)?header\.svg\"[^>]*>(?:\s*</p>)?", re.I)


def readme_parts(text: str) -> tuple[str, str] | None:
    """A README in the standard shape (scripts/docs/README.md), as its tagline and its body.

    The header picture, the tagline and the `Live facts` line are the README's own page head on GitHub;
    the site has its own, so they leave the body. Any other README returns None.
    """
    if not HEADER_IMG.search(text):
        return None
    lines = HEADER_IMG.sub("", text, count=1).splitlines()
    quote = next((i for i, line in enumerate(lines) if line.startswith(">")), None)
    tagline = ""
    if quote is not None and not any(line.startswith("#") for line in lines[:quote]):
        end = quote
        while end < len(lines) and lines[end].startswith(">"):
            end += 1
        tagline = plain(" ".join(line.lstrip("> ") for line in lines[quote:end]))
        if tagline.startswith("TODO"):  # the scaffold's placeholder
            tagline = ""
        del lines[quote:end]
    lines = [line for line in lines if not line.startswith("**Live facts:**")]
    return tagline, "\n".join(lines)


def split_title(text: str) -> tuple[str, str]:
    """The first `# ` heading (outside code) and the text without it."""
    lines, fence = text.splitlines(), False
    for i, line in enumerate(lines):
        if line.lstrip().startswith(("```", "~~~")):
            fence = not fence
        if not fence and line.startswith("# "):
            return line[2:].strip(), "\n".join(lines[:i] + lines[i + 1:])
    return "", text


def first_sentence(body: str) -> str:
    fence = False
    for para in re.split(r"\n\s*\n", body):
        text = para.strip()
        if text.startswith(("```", "~~~")):
            fence = text.count("```") % 2 == 1
            continue
        if fence or not text or text[0] in "#|>-*<!`[0123456789" or text.startswith("---"):
            continue
        sentence = plain(text)
        match = re.match(r"(.+?[.!?])(\s|$)", sentence)
        sentence = match.group(1) if match else sentence
        return sentence if len(sentence) <= 200 else sentence[:197].rstrip() + "..."
    return ""


# --------------------------------------------------------------------------------------------
# Pages


def app_rows(keys: list[tuple[str, str]], ctx: dict) -> list[list[str]]:
    rows = []
    for key in keys:
        routes = ctx["routes_by_app"].get(key, [])
        host = host_link(routes[0]) + (" (public)" if routes[0]["public"] else "") if routes else ""
        rows.append([key[0], app_link(key), ctx["descriptions"].get(key, ""), host, "yes" if ctx["backups_by_app"].get(key) else "no"])
    return rows


def mermaid_edges(edges: list[tuple[tuple[str, str], tuple[str, str], str]], labels_: dict) -> str:
    nodes = sorted({n for a, b, _ in edges for n in (a, b)} | set(labels_))
    lines = ["```mermaid", "graph LR"]
    for n in nodes:
        lines.append(f'  {node_id(*n)}["{labels_.get(n, "/".join(n))}"]')
    for a, b, label in sorted(edges):
        arrow = f" -->|{label}| " if label else " --> "
        lines.append(f"  {node_id(*a)}{arrow}{node_id(*b)}")
    lines.append("```")
    return "\n".join(lines)


def build_app_page(key, app, model, ctx, weight) -> tuple[str, list[str]]:
    """The page for one app and a list of warnings for sections that could not be built."""
    objs = model["by_app"].get(key, {})
    warnings = []
    sections: list[str] = []
    slug, branch = ctx["repo"], ctx["branch"]
    routes = ctx["routes_by_app"].get(key, [])
    desc = ctx["descriptions"].get(key, "")

    def add(title: str, fn: Callable[[], str]):
        try:
            body = fn()
        except Exception as exc:  # one bad object must not cost the app its page
            warnings.append(f"{key[0]}/{key[1]}: section {title!r} skipped ({type(exc).__name__}: {exc})")
            return
        if body and body.strip():
            sections.append(f"## {title}\n\n{body.strip()}")

    base_dirs = sorted({"/".join(k["path"].split("/")[:5]) for k in app["ks"] if k["path"].startswith("kubernetes/apps/base/")})
    head = [desc] if desc else []
    src_links = [f"[{d}](https://github.com/{slug}/tree/{branch}/{d})" for d in base_dirs]
    src_links.append(f"overlay [{app['file']}](https://github.com/{slug}/blob/{branch}/{app['file']})")
    head.append("**Source:** " + ", ".join(src_links))

    def flux():
        rows = []
        for k in app["ks"]:
            subs = "\n".join(f"{n}={v}" for n, v in k["substitute"].items())
            rows.append([code(k["name"]), code(k["path"]), k["target"], "\n".join(code(c) for c in k["components"]), subs])
        return table(["Kustomization", "Path", "Target namespace", "Components", "Substitutions"], rows)

    def workloads():
        rows = []
        for kind in WORKLOAD_KINDS:
            for o in objs.get(kind, []):
                spec = o.get("spec") or {}
                if kind == "CronJob":
                    scale = f"schedule {code(spec.get('schedule', ''))}"
                elif kind == "DaemonSet":
                    scale = "one per node"
                else:
                    scale = f"{spec.get('replicas', 1)} replica(s)"
                ps = pod_spec(o)
                containers = [(c, False) for c in ps.get("initContainers") or []] + [(c, True) for c in ps.get("containers") or []]
                containers = [(c, main) for c, main in containers if not main] + [(c, main) for c, main in containers if main]
                for i, (c, main) in enumerate(containers):
                    res = c.get("resources") or {}
                    first = i == 0
                    rows.append([kind if first else "", f"{ns_of(o)}/{name_of(o)}" if first else "", scale if first else "",
                                 c.get("name", "") + ("" if main else " (init)"), code(short_image(str(c.get("image", "")))),
                                 req_lim(res, "cpu"), req_lim(res, "memory")])
        return table(["Kind", "Name", "Replicas / schedule", "Container", "Image", "CPU req / limit", "Memory req / limit"], rows) if rows else ""

    def charts():
        rows = []
        for hr in objs.get("HelmRelease", []):
            c = chart_of(model, hr)
            url = f"[{c['url']}]({c['url']})" if c["url"].startswith("http") else code(c["url"])
            rows.append([f"{ns_of(hr)}/{name_of(hr)}", c["chart"], c["version"], url])
        return table(["Release", "Chart", "Version", "Source"], rows) if rows else ""

    def route_section():
        rows = []
        for r in routes:
            hosts = "\n".join(f"[{h}](https://{h}/)" if "." in h else h for h in r["hosts"]) or "(any host)"
            rows.append([hosts, gateway_label(r["gateways"]), "\n".join(code(p) for p in r["paths"]), "\n".join(r["policies"]) or "none at the gateway",
                         f"{r['kind']} {code(r['name'])}"])
        return table(["Host", "Gateway", "Paths", "Gateway policy", "Object"], rows) if rows else ""

    def storage():
        rows = []
        for c in ctx["claims_by_app"].get(key, []):
            b = ctx["backups"].get((c["ns"], c["name"]), {})
            backed = " + ".join(sorted(b)) if b else "no"
            note = "" if b else ctx["no_backup_reasons"].get((c["ns"], c["name"]), "")
            rows.append([code(c["name"]) if not c["template"] else c["name"], c["ns"], c["size"], c["class"], c["access"], backed, note])
        return table(["Claim", "Namespace", "Size", "Storage class", "Access", "Backup", "Note"], rows) if rows else ""

    def backup_section():
        rows = []
        for (ns, claim), repos in sorted(ctx["backups"].items()):
            for repo, entry in sorted(repos.items()):
                if entry["app"] == key:
                    rows.append([code(claim), repo, code(schedule_text(entry)), entry["retention"], code(entry["policy"])])
        if not rows:
            return ""
        return (table(["Claim", "Repository", "Schedule", "Retention", "SnapshotPolicy"], rows) +
                f"\n\n`H` in a schedule is a hashed minute that kopiur picks per schedule. Restore: [{ctx['restore_title']}]({ctx['restore_url']}).")

    def databases():
        parts = []
        rows = []
        for db in objs.get("Database", []):
            spec = db.get("spec") or {}
            rows.append([(spec.get("cluster") or {}).get("name", ""), code(spec.get("name", "")), code(spec.get("owner", "")),
                         ns_of(db)])
        for role in objs.get("DatabaseRole", []):
            spec = role.get("spec") or {}
            if not any(r[2] == code(spec.get("name", "")) for r in rows):
                rows.append([(spec.get("cluster") or {}).get("name", ""), "", code(spec.get("name", "")), ns_of(role)])
        if rows:
            parts.append("CloudNativePG:\n\n" + table(["Cluster", "Database", "Role (owner)", "Namespace"], rows))
        clusters = [[f"{ns_of(c)}/{name_of(c)}", (c.get("spec") or {}).get("instances", ""), ((c.get("spec") or {}).get("storage") or {}).get("size", ""),
                     code(short_image(str((c.get("spec") or {}).get("imageName", ""))))] for c in objs.get("Cluster", [])
                    if str(c.get("apiVersion", "")).startswith("postgresql.cnpg.io/")]
        if clusters:
            parts.append("Clusters (see [Databases](/reference/databases/)):\n\n" + table(["Cluster", "Instances", "Storage", "Image"], clusters))
        df = [[f"{ns_of(d)}/{name_of(d)}", (d.get("spec") or {}).get("replicas", 1), code(short_image(str((d.get("spec") or {}).get("image", ""))))]
              for d in objs.get("Dragonfly", [])]
        if df:
            parts.append("Dragonfly:\n\n" + table(["Instance", "Replicas", "Image"], df))
        return "\n\n".join(parts)

    def secrets():
        rows = [secret_row(es) for es in objs.get("ExternalSecret", [])]
        rows = [[r[1], r[2], r[3], r[4]] for r in rows]
        body = table(["ExternalSecret", "Store", "1Password items", "Secret"], rows) if rows else ""
        push = [push_row(p) for p in objs.get("PushSecret", [])]
        if push:
            body += "\n\nPushSecrets (cluster Secret to 1Password):\n\n" + table(["PushSecret", "Store", "1Password items", "From Secret"], [[r[1], r[2], r[3], r[4]] for r in push])
        return body

    def deps():
        lines = []
        out_apps = collections.defaultdict(set)
        for k in app["ks"]:
            for dep in k["depends"]:
                owner = model["ks_owner"].get(dep)
                if owner != key:
                    out_apps[owner or ("", f"{dep[0]}/{dep[1]}")].add(dep[1])
        if out_apps:
            lines.append("**Depends on:** " + ", ".join(
                (app_link(o, f"{o[0]}/{o[1]}") if o[0] else code(o[1])) + (f" ({', '.join(code(n) for n in sorted(ks) if n != o[1])})" if any(n != o[1] for n in ks) else "")
                for o, ks in sorted(out_apps.items())))
        req = sorted(ctx["required_by"].get(key, set()))
        if req:
            lines.append("**Required by:** " + ", ".join(app_link(o, f"{o[0]}/{o[1]}") for o in req))
        return "\n\n".join(lines)

    def monitoring():
        lines = []
        for rule in objs.get("PrometheusRule", []):
            alerts = sorted({r.get("alert") for g in (rule.get("spec") or {}).get("groups") or [] for r in g.get("rules") or [] if r.get("alert")})
            if alerts:
                shown = ", ".join(code(a) for a in alerts[:30]) + (f" and {len(alerts) - 30} more" if len(alerts) > 30 else "")
                lines.append(f"- PrometheusRule `{name_of(rule)}`: {shown} ([alerts](/reference/alerts/))")
        for kind in ("ServiceMonitor", "PodMonitor", "Probe"):
            names = [name_of(o) for o in objs.get(kind, [])]
            if names:
                lines.append(f"- {kind}: " + ", ".join(code(n) for n in names))
        for r in routes:
            if r["gatus"]:
                lines.append(f"- Gatus endpoint: <{r['gatus']}>" if r["gatus"].startswith("http") else f"- Gatus endpoint: {code(r['gatus'])}")
        return "\n".join(lines)

    readme = ctx["readmes"].get(key)

    def notes():
        parts = []
        for src in ctx["app_docs"].get(key, []):
            if readme and src == readme[0]:
                continue
            text = (ROOT / src).read_text()
            title, _ = split_title(text)
            body = rewrite_markdown(text, src, ctx, demote=2)
            if not title:
                body = f"### {posixpath.basename(src)}\n\n" + body
            parts.append(body.strip() + "\n\n" + from_line(src, ctx))
        for src, url in sorted(ctx["ops_by_appdir"].items()):
            if any(src.startswith(d + "/") for d in base_dirs):
                parts.append(f"See also: [{ctx['ops_titles'][src]}]({url}).")
        return "\n\n".join(parts)

    if readme:  # its own `##` sections lead the page and the table of contents
        try:
            sections.append(rewrite_markdown(readme[2], readme[0], ctx).strip() + "\n\n" + from_line(readme[0], ctx))
        except Exception as exc:
            warnings.append(f"{key[0]}/{key[1]}: README skipped ({type(exc).__name__}: {exc})")
    add("Flux Kustomizations", flux)
    add("Workloads", workloads)
    add("Chart", charts)
    add("Routes", route_section)
    add("Storage", storage)
    add("Backups", backup_section)
    add("Database", databases)
    add("Secrets", secrets)
    add("Dependencies", deps)
    add("Monitoring", monitoring)
    add("Notes", notes)
    body = "\n\n".join(head + sections)
    source = base_dirs[0] if base_dirs else app["file"]
    return page(key[1], weight, desc, "app", True, body, source=source), warnings


def secret_row(es: dict) -> list[str]:
    """Names only: the store, the 1Password items read and the Secret produced. Never template data."""
    spec = es.get("spec") or {}
    store = spec.get("secretStoreRef") or {}
    items = set()
    for d in spec.get("dataFrom") or []:
        if (d.get("extract") or {}).get("key"):
            items.add(code(d["extract"]["key"]))
        if (d.get("find") or {}).get("name"):
            items.add("find " + code(((d["find"].get("name") or {}).get("regexp")) or ""))
        gen = (d.get("sourceRef") or {}).get("generatorRef")
        if gen:
            items.add(f"generator {gen.get('kind', '')} {code(gen.get('name', ''))}")
    for d in spec.get("data") or []:
        if (d.get("remoteRef") or {}).get("key"):
            items.add(code(d["remoteRef"]["key"]))
    target = (spec.get("target") or {}).get("name") or name_of(es)
    store_text = f"{store.get('kind', '')} {store.get('name', '')}".strip() or ("generator" if any("generator" in i for i in items) else "")
    return [ns_of(es), code(name_of(es)), store_text, "\n".join(sorted(items)), code(target)]


def push_row(ps: dict) -> list[str]:
    spec = ps.get("spec") or {}
    stores = ", ".join(sorted(s.get("name", "") for s in spec.get("secretStoreRefs") or []))
    items = sorted({code(((d.get("match") or {}).get("remoteRef") or {}).get("remoteKey", "")) for d in spec.get("data") or []})
    src = ((spec.get("selector") or {}).get("secret") or {}).get("name", "")
    return [ns_of(ps), code(name_of(ps)), stores, "\n".join(items), code(src)]


def versions_of(model: dict) -> list[dict]:
    out = []
    for kind, field, label in (("TalosUpgrade", "talos", "Talos"), ("KubernetesUpgrade", "kubernetes", "Kubernetes")):
        objs = model["by_kind"].get(kind, [])
        version = ((objs[0].get("spec") or {}).get(field) or {}).get("version") if objs else None
        if version:
            out.append({"name": label, "version": str(version)})
    flux = model["by_kind"].get("FluxInstance", [])
    flux_version = ((flux[0].get("spec") or {}).get("distribution") or {}).get("version") if flux else None
    operator = next((h for h in model["by_kind"]["HelmRelease"] if name_of(h) == "flux-operator"), None)
    op_version = chart_of(model, operator)["version"] if operator else ""
    if flux_version:
        out.append({"name": "Flux", "version": f"{flux_version} (flux-operator {op_version})" if op_version else str(flux_version)})
    for label, ns, name in VERSION_RELEASES:
        hr = next((h for h in model["by_kind"]["HelmRelease"] if ns_of(h) == ns and name_of(h) == name), None)
        version = chart_of(model, hr)["version"] if hr else ""
        if version:
            out.append({"name": label, "version": version})
    return out


def images_of(model: dict) -> dict[str, list[str]]:
    """image -> ['ns/app: Kind name', ...] for workloads and image-carrying CRs."""
    uses = collections.defaultdict(set)
    for kind in WORKLOAD_KINDS + ("Job",):
        for o in model["by_kind"].get(kind, []):
            ps = pod_spec(o)
            for c in (ps.get("initContainers") or []) + (ps.get("containers") or []):
                if c.get("image"):
                    uses[short_image(str(c["image"]))].add((owner_key(model, o), f"{kind} {ns_of(o)}/{name_of(o)}"))
    for kind, getter in (("Cluster", lambda s: s.get("imageName")), ("Dragonfly", lambda s: s.get("image")),
                         ("CephCluster", lambda s: (s.get("cephVersion") or {}).get("image"))):
        for o in model["by_kind"].get(kind, []):
            image = getter(o.get("spec") or {})
            if image:
                uses[short_image(str(image))].add((owner_key(model, o), f"{kind} {ns_of(o)}/{name_of(o)}"))
    return {img: sorted((app_link(k, f"{k[0]}/{k[1]}") + ": " if k else "") + what for k, what in v) for img, v in sorted(uses.items())}


# --------------------------------------------------------------------------------------------
# Main


def link_ops(apps: dict, ctx: dict) -> None:
    """Hand-written pages and the repo path -> site path map that link rewriting uses."""
    ops = ops_sources()
    by_app_docs, by_ns_docs = app_docs(apps)
    published: dict[str, str] = {}
    titles = {}
    for src in ops:
        published[src] = f"/operations/{ops_slug(src)}/"
        title, _ = split_title((ROOT / src).read_text())
        if src == "AGENTS.md":
            title = "Operator guide"
        elif src.startswith(OPS_RUNBOOK_DIR):
            title = f"Runbook: {title or Path(src).stem}"
        titles[src] = title or src
    counts = collections.Counter(titles.values())
    titles = {src: f"{t} ({src})" if counts[t] > 1 else t for src, t in titles.items()}
    published["CLAUDE.md"] = published.get("AGENTS.md", "/operations/agents/")
    for key, docs in by_app_docs.items():
        for src in docs:
            published[src] = app_url(key)
    for ns, docs in by_ns_docs.items():
        for src in docs:
            published[src] = f"/apps/{ns}/"
    restore = published.get(RESTORE_RUNBOOK, f"https://github.com/{ctx['repo']}/blob/{ctx['branch']}/{RESTORE_RUNBOOK}")
    readmes = {}
    for key, docs in by_app_docs.items():
        for src in docs:
            if src.count("/") == 5 and src.endswith("/README.md") and (parts := readme_parts((ROOT / src).read_text())):
                readmes[key] = (src, *parts)
    ctx.update(ops=ops, published=published, app_docs=by_app_docs, ns_docs=by_ns_docs, ops_titles=titles, readmes=readmes,
               ops_by_appdir={src: published[src] for src in ops if src.startswith("kubernetes/apps/base/")},
               restore_url=restore, restore_title=titles.get(RESTORE_RUNBOOK, "restore runbook"))


def collect_facts(model: dict, apps: dict, ctx: dict) -> None:
    """Routes, backups, claims and dependencies, shared by the app pages and the reference pages."""
    routes = routes_of(model, model["by_kind"]["HTTPRoute"] + model["by_kind"]["Ingress"], ctx["domain"])
    routes_by_app = collections.defaultdict(list)
    for r in routes:
        if r["app"]:
            routes_by_app[r["app"]].append(r)
    for rs in routes_by_app.values():
        rs.sort(key=lambda r: (r["kind"] != "HTTPRoute", r["name"]))
    backups = backups_of(model)
    backups_by_app = collections.defaultdict(set)
    for (ns, claim), repos in backups.items():
        for entry in repos.values():
            if entry["app"]:
                backups_by_app[entry["app"]].add((ns, claim))
    claims = claims_of(model, model["by_kind"])
    claims_by_app = collections.defaultdict(list)
    for c in claims:
        if c["app"]:
            claims_by_app[c["app"]].append(c)
    reasons = {(c["ns"], c["name"]): no_backup_reason(c, apps.get(c["app"]) if c["app"] else None)
               for c in claims if (c["ns"], c["name"]) not in backups}
    required_by = collections.defaultdict(set)
    ks_ns = {}
    for key, app in apps.items():
        for k in app["ks"]:
            ks_ns[(k["namespace"], k["name"])] = key[0]
            for dep in k["depends"]:
                owner = model["ks_owner"].get(dep)
                if owner and owner != key:
                    required_by[owner].add(key)
    ctx.update(routes=routes, routes_by_app=routes_by_app, backups=backups, backups_by_app=backups_by_app, claims=claims,
               claims_by_app=claims_by_app, no_backup_reasons=reasons, required_by=required_by, ks_ns=ks_ns,
               descriptions={key: next((r["description"] for r in rs if r["description"]), "") for key, rs in routes_by_app.items()})
    ctx["descriptions"].update({key: tagline for key, (_, tagline, _) in ctx["readmes"].items() if tagline})


APP_HEADERS = ["Namespace", "App", "What it is", "Host", "Backup"]


def home_page(model: dict, apps: dict, ctx: dict) -> str:
    repo, sha, routes = ctx["repo"], ctx["sha"], ctx["routes"]
    stats = [
        {"label": "Apps", "value": len(apps)},
        {"label": "Namespaces", "value": len({k[0] for k in apps})},
        {"label": "Flux Kustomizations", "value": sum(len(app["ks"]) for app in apps.values())},
        {"label": "HelmReleases", "value": len(model["by_kind"]["HelmRelease"])},
        {"label": "Routes", "value": len(routes)},
        {"label": "Public routes", "value": sum(r["public"] for r in routes)},
        {"label": "Volumes with backups", "value": len(ctx["backups"])},
        {"label": "Databases", "value": len(model["by_kind"]["Database"])},
        {"label": "ExternalSecrets", "value": len(model["by_kind"]["ExternalSecret"])},
    ]
    body = (f"This site documents a three-node Talos Linux Kubernetes cluster that Flux reconciles from the "
            f"[{repo}](https://github.com/{repo}) repository.\n\n"
            f"The pages under [Apps](/apps/) and [Reference](/reference/) are generated from the manifests at commit "
            f"[`{sha}`](https://github.com/{repo}/commit/{sha}) and are rebuilt on every merge; nobody edits them by hand. "
            f"[Operations](/operations/) collects the hand-written guides and runbooks from the same commit.")
    return page("Home", 0, "The cluster, documented from its own manifests.", "home", True, body,
                stats=stats, versions=ctx["versions"], commit=sha, built=ctx["built"])


def namespace_page(ns: str, weight: int, model: dict, apps: dict, ctx: dict) -> str:
    keys = sorted(k for k in apps if k[0] == ns)
    body = [table(APP_HEADERS, app_rows(keys, ctx)), f"{len(keys)} apps."]
    own = sorted((k["namespace"], k["name"]) for key in keys for k in apps[key]["ks"])
    intra, cross = [], []
    for key in keys:
        for k in apps[key]["ks"]:
            for dep in k["depends"]:
                (intra if ctx["ks_ns"].get(dep) == ns else cross).append(((k["namespace"], k["name"]), dep, ""))
    # Over ~40 nodes a diagram stops being readable: draw the namespace alone, list the rest.
    too_big = len(own) + len({d for _, d, _ in cross}) > 40
    edges = intra if too_big else intra + cross
    node_labels = {n: n[1] for n in own} | {d: f"{d[0]}/{d[1]}" for _, d, _ in edges if d not in own}
    body.append("## Dependencies\n\nFlux Kustomizations in this namespace and what they wait for (`dependsOn`).\n\n" +
                mermaid_edges(edges, node_labels))
    if too_big and cross:
        body.append(table(["Kustomization", "Depends on (other namespace)"],
                          [[code(a[1]), code(f"{b[0]}/{b[1]}")] for a, b, _ in sorted(cross)]))
    notes = [rewrite_markdown((ROOT / src).read_text(), src, ctx, demote=2).strip() + "\n\n" + from_line(src, ctx)
             for src in ctx["ns_docs"].get(ns, [])]
    if notes:
        body.append("## Notes\n\n" + "\n\n".join(notes))
    return page(ns, weight, f"Apps in the {ns} namespace.", "namespace", True, "\n\n".join(body),
                source=f"kubernetes/apps/main/{ns}")


def from_line(src: str, ctx: dict) -> str:
    return f"_From [{src}](https://github.com/{ctx['repo']}/blob/{ctx['branch']}/{src})._"


def owner_link(model: dict, o: dict) -> str:
    owner = owner_key(model, o)
    return app_link(owner, f"{owner[0]}/{owner[1]}") if owner else ""


def backups_page(ctx: dict) -> str:
    backups, reasons = ctx["backups"], ctx["no_backup_reasons"]
    sizes = {(c["ns"], c["name"]): c["size"] for c in ctx["claims"]}
    rows = []
    for (ns, claim), repos in sorted(backups.items()):
        owner = next(iter(repos.values()))["app"]
        rows.append([ns, app_link(owner) if owner else "", code(claim), sizes.get((ns, claim), ""),
                     code(schedule_text(repos.get("ceph"))), code(schedule_text(repos.get("r2"))),
                     "\n".join(f"{r}: {e['retention']}" for r, e in sorted(repos.items()))])
    unbacked = [c for c in ctx["claims"] if (c["ns"], c["name"]) not in backups]
    explained = [c for c in unbacked if reasons.get((c["ns"], c["name"]))]
    unexplained = [c for c in unbacked if not reasons.get((c["ns"], c["name"]))]

    def claim_row(c: dict, note: bool = False) -> list[str]:
        row = [c["ns"], app_link(c["app"]) if c["app"] else "", c["name"] if c["template"] else code(c["name"]), c["size"], c["class"]]
        return row + [reasons.get((c["ns"], c["name"]), "")] if note else row
    body = (f"{len(backups)} volumes are backed up by kopiur to the in-cluster `ceph` repository and the offsite `r2` repository. "
            f"`H` in a schedule is a hashed minute that kopiur picks per schedule. "
            f"Restore: [{ctx['restore_title']}]({ctx['restore_url']}).\n\n" +
            table(["Namespace", "App", "Claim", "Size", "Ceph schedule", "R2 schedule", "Retention"], rows) +
            f"\n\n## Volumes without a backup\n\n{len(unexplained)} claims have no kopiur backup and no manifest comment explaining why. "
            "Postgres data is not here: CloudNativePG backs it up itself (see [Databases](/reference/databases/)).\n\n" +
            table(["Namespace", "App", "Claim", "Size", "Storage class"], [claim_row(c) for c in unexplained]) +
            f"\n\n## Deliberately not backed up\n\n{len(explained)} claims carry a manifest comment saying they need no backup.\n\n" +
            table(["Namespace", "App", "Claim", "Size", "Storage class", "Manifest comment"], [claim_row(c, True) for c in explained]))
    return page("Backups", 10, "Every kopiur-protected volume and every volume without a backup.", "reference", True, body,
                source="kubernetes/components/kopiur")


def cnpg_cluster_section(model: dict, cluster: dict, domain: str) -> str:
    spec = cluster.get("spec") or {}
    stores = {name_of(s): s.get("spec") or {} for s in model["by_kind"].get("ObjectStore", []) if ns_of(s) == ns_of(cluster)}
    backup = []
    for plugin in spec.get("plugins") or []:
        if not plugin.get("isWALArchiver"):
            continue
        store_name = (plugin.get("parameters") or {}).get("barmanObjectName", "")
        store = stores.get(store_name) or {}
        conf = store.get("configuration") or {}
        where = (f" ({code(conf.get('destinationPath', ''))} at {code(fix_urls(str(conf.get('endpointURL', '')), domain))}, "
                 f"retention {store.get('retentionPolicy', 'unset')})") if store else ""
        backup.append(f"WAL archiving and base backups through `{plugin.get('name', '')}` to ObjectStore `{store_name}`{where}")
    for sb in model["by_kind"].get("ScheduledBackup", []):
        sb_spec = sb.get("spec") or {}
        if ns_of(sb) == ns_of(cluster) and (sb_spec.get("cluster") or {}).get("name") == name_of(cluster):
            backup.append(f"ScheduledBackup `{name_of(sb)}`: {code(sb_spec.get('schedule', ''))} (seconds field first), "
                          f"method {sb_spec.get('method', '')}")
    storage = spec.get("storage") or {}
    return f"### {ns_of(cluster)}/{name_of(cluster)}\n\n" + table(["Field", "Value"], [
        ["App", owner_link(model, cluster)],
        ["Instances", spec.get("instances", "")],
        ["Storage", f"{storage.get('size', '')} {storage.get('storageClass', '')}".strip()],
        ["Image", code(short_image(str(spec.get("imageName", ""))))],
        ["Backup", "\n".join(backup) or "none in the render"],
    ])


def databases_page(model: dict, ctx: dict) -> str:
    clusters = [cnpg_cluster_section(model, c, ctx["domain"]) for c in model["by_kind"]["Cluster"]
                if str(c.get("apiVersion", "")).startswith("postgresql.cnpg.io/")]
    db_rows = [[((db.get("spec") or {}).get("cluster") or {}).get("name", ""), code((db.get("spec") or {}).get("name", "")),
                code((db.get("spec") or {}).get("owner", "")), owner_link(model, db)] for db in model["by_kind"]["Database"]]
    role_rows = [[((r.get("spec") or {}).get("cluster") or {}).get("name", ""), code((r.get("spec") or {}).get("name", "")),
                  "yes" if (r.get("spec") or {}).get("login") else "no", owner_link(model, r)] for r in model["by_kind"]["DatabaseRole"]]
    other = []
    for kind, detail in (("Dragonfly", lambda s: code(short_image(str(s.get("image", ""))))),
                         ("EMQX", lambda s: code(short_image(str(s.get("image", ""))))),
                         ("CephObjectStore", lambda s: ""),
                         ("ObjectBucketClaim", lambda s: code(s.get("bucketName") or s.get("generateBucketName") or ""))):
        for o in model["by_kind"].get(kind, []):
            spec = o.get("spec") or {}
            other.append([kind, f"{ns_of(o)}/{name_of(o)}", owner_link(model, o), spec.get("replicas", ""), detail(spec)])
    body = ("## CloudNativePG clusters\n\n" + ("\n\n".join(clusters) or "None in the render.") +
            f"\n\n## Databases\n\n{len(db_rows)} databases.\n\n" + table(["Cluster", "Database", "Owner role", "App"], db_rows) +
            "\n\n## Roles\n\n" + table(["Cluster", "Role", "Login", "App"], role_rows) +
            "\n\n## Other data stores\n\n" + table(["Kind", "Name", "App", "Replicas", "Image / bucket"], other))
    return page("Databases", 20, "CloudNativePG clusters, databases, roles and other data stores.", "reference", True, body,
                source="kubernetes/components/cnpg-database")


def exposure_page(ctx: dict) -> str:
    routes = ctx["routes"]
    public = [r for r in routes if r["public"]]
    internal = [r for r in routes if not r["public"] and r["kind"] == "HTTPRoute"]
    other = [r for r in routes if not r["public"] and r["kind"] != "HTTPRoute"]

    def row(r: dict) -> list[str]:
        hosts = "\n".join(f"[{h}](https://{h}/)" if "." in h else h for h in r["hosts"]) or "(any host)"
        return [r["ns"], app_link(r["app"]) if r["app"] else "", hosts, "\n".join(code(p) for p in r["paths"]) or "/",
                "\n".join(r["policies"]) or "none at the gateway", code(r["name"])]
    headers = ["Namespace", "App", "Host", "Paths", "Gateway policy", "Route"]
    body = (f"{len(public)} routes are attached to the public gateway `{PUBLIC_GATEWAY}` and {len(internal)} only to internal "
            "gateways. A route on both counts as public.\n\n## Public\n\n" + table(headers, [row(r) for r in public]) +
            f"\n\n## Internal\n\n{len(internal)} routes.\n\n")
    for ns in sorted({r["ns"] for r in internal}):
        body += f"### {ns}\n\n" + table(headers, [row(r) for r in internal if r["ns"] == ns]) + "\n\n"
    if other:
        body += "## Other ingress\n\n" + table(headers[:-1] + ["Ingress"], [row(r) for r in other])
    return page("Exposure", 30, "Every route by gateway, public first.", "reference", True, body)


def secrets_page(model: dict) -> str:
    rows = []
    for es in model["by_kind"]["ExternalSecret"]:
        row = secret_row(es)
        namespace_wide = labels(es).get("kustomize.toolkit.fluxcd.io/name") == "cluster-apps"
        row.insert(1, owner_link(model, es) or ("(every namespace)" if namespace_wide else ""))
        rows.append(row)
    push = [push_row(p) for p in model["by_kind"]["PushSecret"]]
    body = (f"Which 1Password items each ExternalSecret reads, by item name. {len(rows)} ExternalSecrets, {len(push)} PushSecrets. "
            "Values and templates are never published.\n\n" +
            table(["Namespace", "App", "ExternalSecret", "Store", "1Password items", "Secret"], rows) +
            "\n\n## PushSecrets\n\nCluster Secrets written back to 1Password.\n\n" +
            table(["Namespace", "PushSecret", "Stores", "1Password items", "From Secret"], push))
    return page("Secrets", 40, "ExternalSecret to 1Password item map, names only.", "reference", True, body)


def versions_page(model: dict, ctx: dict) -> str:
    charts = []
    for hr in model["by_kind"]["HelmRelease"]:
        c = chart_of(model, hr)
        owner = owner_key(model, hr)
        charts.append([ns_of(hr), code(name_of(hr)), app_link(owner) if owner else "", c["chart"], c["version"],
                       f"[{c['url']}]({c['url']})" if c["url"].startswith("http") else code(c["url"])])
    images = [[code(img), "\n".join(users)] for img, users in images_of(model).items()]
    body = ("Pinned in Git: Talos and Kubernetes by the tuppr upgrade CRs, Flux by the FluxInstance, the rest by chart version.\n\n" +
            table(["Component", "Version"], [[v["name"], v["version"]] for v in ctx["versions"]]) +
            f"\n\n## Helm charts\n\n{len(charts)} HelmReleases.\n\n" +
            table(["Namespace", "Release", "App", "Chart", "Version", "Source"], charts) +
            f"\n\n## Container images\n\n{len(images)} distinct images (digests shortened).\n\n" + table(["Image", "Used by"], images))
    return page("Versions", 50, "Platform versions, every chart and every container image.", "reference", True, body)


def dependencies_page(model: dict, apps: dict, ctx: dict) -> str:
    ns_edges = collections.Counter()
    dependents = collections.defaultdict(set)
    for key, app in apps.items():
        for k in app["ks"]:
            for dep in k["depends"]:
                dependents[dep].add((k["namespace"], k["name"]))
                target = ctx["ks_ns"].get(dep, dep[0])
                if key[0] != target:
                    ns_edges[(key[0], target)] += 1
    edges = [((a,), (b,), str(n)) for (a, b), n in ns_edges.items()]
    rows = []
    for dep, users in sorted(dependents.items(), key=lambda kv: (-len(kv[1]), kv[0]))[:20]:
        owner = model["ks_owner"].get(dep)
        rows.append([code(f"{dep[0]}/{dep[1]}"), app_link(owner, f"{owner[0]}/{owner[1]}") if owner else "", len(users),
                     ", ".join(code(u[1]) for u in sorted(users))])
    body = ("Namespace-to-namespace dependencies, aggregated from every Flux Kustomization's `dependsOn` "
            "(edge label: number of edges).\n\n" + mermaid_edges(edges, {(ns,): ns for ns in sorted({k[0] for k in apps})}) +
            "\n\n## Most depended-on Kustomizations\n\n" + table(["Kustomization", "App", "Dependents", "Dependent Kustomizations"], rows))
    return page("Dependencies", 60, "How namespaces and Flux Kustomizations depend on each other.", "reference", True, body)


def alerts_page(model: dict) -> str:
    rows = []
    for rule in model["by_kind"]["PrometheusRule"]:
        owner = owner_key(model, rule)
        for group in (rule.get("spec") or {}).get("groups") or []:
            for r in group.get("rules") or []:
                if r.get("alert"):
                    rows.append([ns_of(rule), app_link(owner) if owner else "", code(r["alert"]),
                                 (r.get("labels") or {}).get("severity", ""), r.get("for", ""), code(name_of(rule))])
    rows.sort(key=lambda r: (r[0], r[1], r[2]))
    return page("Alerts", 80, "Every Prometheus alert rule with its severity and pending duration.", "reference", True,
                f"{len(rows)} alert rules (recording rules are left out).\n\n" +
                table(["Namespace", "App", "Alert", "Severity", "For", "PrometheusRule"], rows))


REFERENCE_PAGES = [("backups", "Backups"), ("databases", "Databases"), ("exposure", "Exposure"), ("secrets", "Secrets"),
                   ("versions", "Versions"), ("dependencies", "Dependencies"), ("renovate", "Renovate"), ("alerts", "Alerts")]


def build_pages(model: dict, apps: dict, ctx: dict) -> tuple[dict[str, str], list[str]]:
    """Relative path -> page text for the whole tree, and warnings."""
    pages: dict[str, str] = {"_index.md": home_page(model, apps, ctx)}
    warnings: list[str] = []
    app_keys = sorted(apps)
    backed = sum(1 for k in app_keys if ctx["backups_by_app"].get(k))
    namespaces = sorted({k[0] for k in apps})
    pages["apps/_index.md"] = page("Apps", 10, "Every app in the cluster, by namespace.", "section", True,
                                   table(APP_HEADERS, app_rows(app_keys, ctx)) +
                                   f"\n\n{len(apps)} apps in {len(namespaces)} namespaces, {backed} with backups.")
    for i, ns in enumerate(namespaces):
        pages[f"apps/{ns}/_index.md"] = namespace_page(ns, (i + 1) * 10, model, apps, ctx)
        for j, key in enumerate(k for k in app_keys if k[0] == ns):
            pages[f"apps/{ns}/{key[1]}.md"], warns = build_app_page(key, apps[key], model, ctx, (j + 1) * 10)
            warnings += warns

    pages["reference/_index.md"] = page("Reference", 20, "Cluster-wide tables generated from the manifests.", "section", True,
                                        "Cluster-wide views of the same facts the app pages show:\n\n" +
                                        "\n".join(f"- [{title}](/reference/{slug}/)" for slug, title in REFERENCE_PAGES))
    builders: dict[str, Callable[[], str]] = {
        "backups": lambda: backups_page(ctx),
        "databases": lambda: databases_page(model, ctx),
        "exposure": lambda: exposure_page(ctx),
        "secrets": lambda: secrets_page(model),
        "versions": lambda: versions_page(model, ctx),
        "dependencies": lambda: dependencies_page(model, apps, ctx),
        "renovate": lambda: page("Renovate", 70, "What Renovate merges on its own and what waits for review.",
                                 "reference", True, renovate_body(ctx), source=".renovate"),
        "alerts": lambda: alerts_page(model),
    }
    for i, (slug, title) in enumerate(REFERENCE_PAGES):
        try:
            pages[f"reference/{slug}.md"] = builders[slug]()
        except Exception as exc:  # a stub page beats a missing one, and the warning names the cause
            warnings.append(f"reference/{slug}: {type(exc).__name__}: {exc}")
            pages[f"reference/{slug}.md"] = page(title, (i + 1) * 10, "", "reference", True,
                                                 "This page could not be generated from this commit.")

    ops, titles, published = ctx["ops"], ctx["ops_titles"], ctx["published"]
    pages["operations/_index.md"] = page("Operations", 30, "Hand-written guides and runbooks, published from the repository.",
                                         "section", True,
                                         "Guides and runbooks copied from the repository at build time. Edit them where they live; "
                                         "the source path is on each page.\n\n" +
                                         "\n".join(f"- [{titles[s]}]({published[s]})" for s in ops))
    for i, src in enumerate(ops):
        _, body = split_title((ROOT / src).read_text())
        body = rewrite_markdown(body, src, ctx)
        pages[f"operations/{ops_slug(src)}.md"] = page(titles[src], (i + 1) * 10, first_sentence(body), "guide", False, body,
                                                       source=src)
    return pages, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default="docs/.build/content", help="output directory, recreated on every run")
    parser.add_argument("--rendered", help="a pre-rendered flate JSON or YAML file instead of running flate")
    parser.add_argument("--repo", help="OWNER/NAME for GitHub links (default: $GITHUB_REPOSITORY, then origin)")
    parser.add_argument("--branch", default="main", help="branch GitHub links point at")
    args = parser.parse_args()

    out_dir = Path(args.out) if Path(args.out).is_absolute() else ROOT / args.out
    objs = load_rendered(args.rendered)
    apps = load_apps()
    if not apps:
        sys.exit("build.py: no apps found under kubernetes/apps/main")
    model = build_model(objs, apps)
    committed = int(git("show", "-s", "--format=%ct", "HEAD"))
    ctx: dict[str, Any] = {
        "repo": repo_slug(args.repo), "branch": args.branch, "sha": git("rev-parse", "--short", "HEAD"),
        # The commit date, not the clock: the same commit must build the same bytes.
        "built": datetime.datetime.fromtimestamp(committed, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "domain": detect_domain(objs), "versions": versions_of(model), "images": set(),
    }
    link_ops(apps, ctx)
    collect_facts(model, apps, ctx)
    pages, warnings = build_pages(model, apps, ctx)

    static_dir = out_dir.parent / "static"  # hugo.yaml: staticDir
    for stale in (out_dir, static_dir):
        if stale.exists():
            shutil.rmtree(stale)
    for rel, text in sorted(pages.items()):
        path = out_dir / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    static_dir.mkdir(parents=True, exist_ok=True)
    for rel in sorted(ctx["images"]):  # pictures the published Markdown shows
        (static_dir / "files" / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / rel, static_dir / "files" / rel)

    # A page that silently went empty is worse than a red build: a hand-kept name that no longer
    # matches, or a manifest shape this script no longer understands, fails the run.
    found = {v["name"] for v in ctx["versions"]}
    warnings += [f"VERSION_RELEASES: no HelmRelease {ns}/{name} for {label!r}" for label, ns, name in VERSION_RELEASES if label not in found]
    warnings += [f"{path}: listed for Operations but missing" for path in [*OPS_ORDER, OPS_RECOVERY, *OPS_REST] if not (ROOT / path).is_file()]
    if model["by_kind"].get("SnapshotPolicy") and not ctx["backups"]:
        warnings.append("SnapshotPolicy objects exist but no backup was recognised")
    if model["by_kind"].get("HTTPRoute") and "| " not in pages.get("reference/exposure.md", ""):
        warnings.append("HTTPRoute objects exist but the exposure page has no table")
    for warning in warnings:
        print(f"WARN {warning}", file=sys.stderr)
    kinds = collections.Counter(re.search(r"^  kind: (\w+)$", t, re.M).group(1) for t in pages.values())
    unbacked = [c for c in ctx["claims"] if (c["ns"], c["name"]) not in ctx["backups"]]
    explained = sum(1 for c in unbacked if ctx["no_backup_reasons"].get((c["ns"], c["name"])))
    where = out_dir.relative_to(ROOT) if out_dir.is_relative_to(ROOT) else out_dir
    print(f"build.py: {len(pages)} pages in {where} at {ctx['sha']} (" + ", ".join(f"{k} {n}" for k, n in sorted(kinds.items())) +
          f"); {sum(1 for k in apps if not ctx['descriptions'].get(k))} apps without description; "
          f"{len(unbacked)} PVCs without backup ({explained} explained by a manifest comment)")
    return 1 if warnings else 0


def renovate_body(ctx: dict) -> str:
    files = [".renovaterc.json5"] + sorted(str(p.relative_to(ROOT)) for p in (ROOT / ".renovate").glob("*.json5"))
    merges, holds, sections = [], [], []
    for rel in files:
        try:
            data = json5_load((ROOT / rel).read_text())
        except (ValueError, IndexError, AttributeError) as exc:
            sections.append(f"## {rel}\n\nCould not be read ({exc}).")
            continue
        rules = data.get("packageRules") or []
        rows = []
        for rule in rules:
            matches = "\n".join(f"{k}: {', '.join(code(x) for x in v) if isinstance(v, list) else code(v)}" for k, v in rule.items()
                                if k.startswith(("match", "exclude")))
            effects = [f"{k}: {code(json.dumps(v) if isinstance(v, (bool, int)) else v)}" for k, v in rule.items()
                       if k in ("automerge", "automergeType", "enabled", "groupName", "minimumReleaseAge", "schedule", "ignoreTests",
                                "versioning", "allowedVersions", "rangeStrategy", "dependencyDashboardApproval")]
            label = rule.get("description") or "(no description) " + matches.replace("\n", "; ").replace("`", "")
            rows.append([label, matches, "\n".join(effects)])
            if rule.get("automerge") is True:
                merges.append(label)
            elif rule.get("automerge") is False:
                holds.append(label)
        extra = ""
        if rel == ".renovaterc.json5" and data.get("extends"):
            extra = "Extends: " + ", ".join(code(e) for e in data["extends"]) + "\n\n"
        link = f"https://github.com/{ctx['repo']}/blob/{ctx['branch']}/{rel}"
        sections.append(f"## {rel}\n\n[Source]({link}). {len(rules)} package rules.\n\n" + extra +
                        (table(["Description", "Matches", "Effect"], rows) if rows else ""))
    summary = ("Rules apply in order and a later match wins, so the hold rules sit after the automerge rules.\n\n"
               "**Merges on its own once checks pass:**\n\n" + "\n".join(f"- {m}" for m in merges) +
               "\n\n**Always waits for review:**\n\n" + "\n".join(f"- {h}" for h in holds))
    return summary + "\n\n" + "\n\n".join(sections)


if __name__ == "__main__":
    sys.exit(main())
