#!/usr/bin/env python3
"""Every kustomize.toolkit.fluxcd.io/* annotation or label under kubernetes/ carries a value Flux honours.

Prevents: a value Flux silently ignores (`force: "true"` once shipped), which drops prune, SSA or force protection.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
# kustomize-controller compares these exactly (case matters) and ignores anything else without a warning.
ALLOWED = {
    "force": {"enabled"},
    "prune": {"disabled"},
    "reconcile": {"disabled"},
    "substitute": {"disabled"},
    "ssa": {"Ignore", "IfNotPresent", "Merge"},
}
KEY = r"kustomize\.toolkit\.fluxcd\.io/(force|prune|reconcile|substitute|ssa)"
LINE = re.compile(KEY + r"""["']?\s*:\s*["']?([^\s"'#,}]*)""")

failures, checked = [], 0
for path in sorted((ROOT / "kubernetes").rglob("*.y*ml")):
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue
        for key, value in LINE.findall(line):
            checked += 1
            if value not in ALLOWED[key]:
                failures.append(f"{path.relative_to(ROOT)}:{number}: kustomize.toolkit.fluxcd.io/{key}: {value!r} "
                                f"is ignored by Flux (honoured: {sorted(ALLOWED[key])})")
if not checked:
    failures.append("kubernetes/: found no kustomize.toolkit.fluxcd.io/* annotations; the walker is broken")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
