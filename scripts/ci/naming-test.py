#!/usr/bin/env python3
"""File and directory names follow the convention written in AGENTS.md (CONVENTIONS).

Prevents: a manifest whose name does not say what it holds, a second chart-source style, an overlay that
points at a nested app path, and a kustomization entry without `./` that a grep for the file misses.
Does not check Flux Kustomization names, any metadata.name, generator names or keys, piece-name vocabulary,
per-app `resources:` order, schema URL validity or YAML validity.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ABBREV = {"persistentvolumeclaim": "pvc", "poddisruptionbudget": "pdb"}
RBAC = {"serviceaccount", "role", "clusterrole", "rolebinding", "clusterrolebinding", "secret"}
HELPERS = {"httproute": {"httproutefilter"}, "externalsecret": {"password"}}  # primary: kinds that only serve it
COLLECTIONS = {"alerts", "models", "networks", "repos", "rules", "virtualkeys"}
PAYLOAD_DIRS = {"resources", "dashboards", "hooks", "runbooks", "skills"}
# Drawn by scripts/docs/pictures.py from the README they sit next to.
README_PICTURES = {"header.svg", "concept.svg"}
GRANDFATHERED = {  # path or subtree: reason (exempt from every check)
    "kubernetes/apps/base/kube-system/cilium/app/networking.yaml": "bootstrap/helmfile/apps.yaml applies it by path",
    "kubernetes/apps/main/ai/chat-model.yaml": "substitution input ConfigMap, not a Kustomization",
    "kubernetes/apps/base/flux-system/meta": "cluster-meta entry point",
    "kubernetes/apps/base/system/volsync": "retired tree, frozen until the restic repos expire",
}
NAMED_ROOTS = ("kubernetes", "scripts", ".taskfiles", "terraform", "bootstrap")
KIND = re.compile(r"^kind:\s*(\w+)\s*$", re.M)
SEGMENT = re.compile(r"^\.?[a-z0-9][a-z0-9.-]*$")
BASE, MAIN = "kubernetes/apps/base/", "kubernetes/apps/main/"
failures: list[str] = []


def fail(path: str, rule: str) -> None:
    failures.append(f"FAIL {path}: {rule}")


def exempt(path: str) -> bool:
    return any(path == g or path.startswith(g + "/") for g in GRANDFATHERED)


def is_payload(parts: tuple[str, ...]) -> bool:
    return any(p in PAYLOAD_DIRS for p in parts[:-1])


def entries(text: str, key: str) -> list[str]:
    out, inside = [], False
    for line in text.splitlines():
        if re.match(rf"^{key}:\s*$", line):
            inside = True
        elif inside and (m := re.match(r"^\s*-\s+(\S+)", line)):
            out.append(m.group(1).strip("\"'"))
        elif inside and line.strip() and not line.lstrip().startswith("#"):
            inside = False
    return out


files = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split("\n")
files = [f for f in files if f and (ROOT / f).is_file() and not exempt(f)]
manifests = 0

for f in files:
    parts = tuple(f.split("/"))
    name, ext = parts[-1], Path(f).suffix
    payload = is_payload(parts)
    k8s = parts[0] == "kubernetes"
    # 5: names
    if name.lower() == "readme.md" and name != "README.md":
        fail(f, "README.md is upper-case")
    if parts[0] in NAMED_ROOTS and not payload:
        for p in parts[:-1] if name.lower() == "readme.md" else parts:
            allowed = SEGMENT.fullmatch(p) or (p == parts[-1] and (re.fullmatch(r"[A-Z0-9_-]+\.md", p) or p == "Taskfile.yaml"))
            if not allowed and not (p == parts[-1] and ext == ".py" and re.fullmatch(r"[a-z0-9_]+\.py", p)):
                fail(f, "lowercase kebab-case path segments (README.md, SKILL.md, Taskfile.yaml and .py modules excepted)")
                break
    if k8s and ext == ".yml" and not payload:
        fail(f, "use .yaml")
    if not k8s:
        continue
    # 2: payload next to manifests
    under = f.startswith((BASE, "kubernetes/components/"))
    if under and not payload and ext not in (".yaml", ".md") and name not in README_PICTURES:
        fail(f, "non-YAML file belongs in resources/ (or dashboards/ hooks/ runbooks/ skills/)")
    if under and "config" in parts[:-1] and not payload:
        d = "/".join(parts[: parts.index("config") + 1])
        if not (ROOT / d / "kustomization.yaml").exists():
            fail(d, "config/ without kustomization.yaml holds payload: move it to resources/")
    if ext != ".yaml" or payload or name == "kustomizeconfig.yaml":
        continue
    text = (ROOT / f).read_text(errors="replace")
    # 7: header
    lines = text.splitlines() + ["", ""]
    if lines[0] != "---" or not lines[1].startswith("# yaml-language-server: $schema="):
        fail(f, "line 1 `---`, line 2 `# yaml-language-server: $schema=`")
    # 6: kustomization entries
    if name == "kustomization.yaml":
        for key in ("resources", "components"):
            for e in entries(text, key):
                if not e.startswith(("./", "../")):
                    fail(f, f"{key} entry `{e}` must start with ./ or ../")
        m = re.fullmatch(rf"{MAIN}[^/]+/kustomization\.yaml", f)
        if m:
            res = [re.sub(r"\.yaml$", "", e.removeprefix("./")) for e in entries(text, "resources")]
            if res != sorted(res):
                fail(f, "resources not sorted by name (extension stripped)")
        continue
    # 4: overlays
    if f.startswith(MAIN):
        if len(parts) != 5:
            fail(f, "overlays sit directly in kubernetes/apps/main/<ns>/")
            continue
        targets = re.findall(r"^\s+path:\s*[\"']?\./kubernetes/apps/base/([^\"'\s]+)", text, re.M)
        for t in targets:
            seg = t.split("/")
            if len(seg) != 3 or seg[0] != parts[3]:
                fail(f, f"path base/{t} is not <ns>/<app>/<piece> in this overlay's namespace")
        if targets and targets[0].split("/")[1:2] != [Path(f).stem]:
            fail(f, f"file name must equal the app of its first path ({targets[0]})")
        continue
    # 1: manifest name vs kind
    if not f.startswith((BASE, "kubernetes/components/")) or any(p in COLLECTIONS for p in parts[:-1]):
        continue
    kinds = [k.lower() for k in KIND.findall(text)]
    if not kinds:
        continue
    manifests += 1
    stem, kset = Path(f).stem, set(kinds)
    if "helmrelease" in kset and kset & {"ocirepository", "helmrepository"}:
        fail(f, "chart source belongs in ocirepository.yaml / helmrepository.yaml next to helmrelease.yaml")
        continue
    primary = next((k for k in kset if any(stem == n or stem.startswith(n + "-") for n in (k, ABBREV.get(k, k)))), None)
    if (stem == "rbac" or stem.startswith("rbac-")) and kset <= RBAC:
        continue
    if primary is None:
        fail(f, f"name the file for its kind ({', '.join(sorted(kset))}), `<kind>-<qualifier>`, pvc/pdb/rbac")
    elif kset - {primary} - HELPERS.get(primary, set()):
        fail(f, f"one kind per file ({', '.join(sorted(kset))})")

# 3: app shape
dirs: dict[str, set[str]] = {}
for f in files:
    if f.startswith(BASE) and not is_payload(tuple(f.split("/"))):
        d = f.rsplit("/", 1)[0]
        while len(d) > len(BASE):
            dirs.setdefault(d, set()).add(f)
            d = d.rsplit("/", 1)[0]
for d, members in sorted(dirs.items()):
    depth = d.removeprefix(BASE).count("/") + 1  # 1 ns, 2 app, 3 piece
    direct = {m.rsplit("/", 1)[1] for m in members if m.rsplit("/", 1)[0] == d}
    if any(p in COLLECTIONS for p in d.split("/")):
        continue
    if depth == 2:
        subs = sorted({m.removeprefix(d + "/").split("/")[0] for m in members if m.rsplit("/", 1)[0] != d})
        for s in subs:
            if f"{d}/{s}/kustomization.yaml" not in members:
                fail(f"{d}/{s}", "app subdirectory is not a piece (no kustomization.yaml): grouping directory or loose payload")
        if loose := sorted(n for n in direct if not n.endswith(".md") and n not in README_PICTURES):
            fail(d, f"only *.md and the README pictures sit directly in an app directory, not {loose[0]}: wrap the manifests in a piece (app/)")
        pieces = [s for s in subs if f"{d}/{s}/kustomization.yaml" in members]
        if len(pieces) == 1 and pieces[0] not in ("app", "crds"):
            fail(f"{d}/{pieces[0]}", "single piece must be named app (or crds)")
    elif depth >= 3 and any(n.endswith(".yaml") for n in direct) and "kustomization.yaml" not in direct:
        fail(d, "directory holds YAML but no kustomization.yaml")
    elif depth == 1:
        if loose := sorted(n for n in direct if not n.endswith(".md")):
            fail(d, f"only *.md sits directly in a namespace directory, not {loose[0]}")

if not manifests:
    print("FAIL walker is broken: found no manifests under kubernetes/apps/base or kubernetes/components")
    sys.exit(1)
for line in sorted(set(failures)):
    print(line)
sys.exit(1 if failures else 0)
