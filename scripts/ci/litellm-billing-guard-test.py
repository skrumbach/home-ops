#!/usr/bin/env python3
"""A budgetless LiteLLM virtual key reaches only free-credential models; provider pass-throughs stay admin-only.

Prevents: an uncapped key (or a config fallback it inherits) spending a household-metered provider credential.
"""

import sys
from pathlib import Path

import yaml

APP = "kubernetes/apps/base/ai/litellm/app"
ROOT = Path(__file__).resolve().parents[2] / APP
FREE = ("not-needed", "sk-ant-oat", "os.environ/CLIPROXYAPI_API_KEY")  # local, client's own token, subscription


def docs(pattern, kind):
    found = [d for p in sorted(ROOT.glob(pattern)) for d in yaml.safe_load_all(p.read_text())]
    return [d for d in found if d and d.get("kind") == kind]


models = {}  # modelName -> params of every CR with that name (LiteLLM load-balances them)
for d in docs("models/*.yaml", "LiteLLMModel"):
    models.setdefault(d["spec"]["modelName"], []).append(d["spec"]["params"])
keys = {d["metadata"]["name"]: d["spec"] for d in docs("virtualkeys/*.yaml", "LiteLLMVirtualKey")}
(proxy,) = docs("litellmproxy.yaml", "LiteLLMProxy")
router = proxy["spec"]["routerSettings"]
fallbacks = {}  # a config fallback bypasses the caller's allow-list
for entry in (router.get("fallbacks") or []) + (router.get("context_window_fallbacks") or []):
    for primary, targets in entry.items():
        fallbacks.setdefault(primary, set()).update([targets] if isinstance(targets, str) else targets)


def free(name):  # unknown name, missing apiKey (env fallback) and auto_router/* all count as billed
    return all(not p["model"].startswith("auto_router/") and str(p.get("apiKey", "")).startswith(FREE)
               for p in models.get(name) or [{"model": "auto_router/"}])


modelled = {("routerSettings", "fallbacks"), ("routerSettings", "context_window_fallbacks")}
failures = [f"{APP}/litellmproxy.yaml: {s}.{k} is a fallback map this test does not model" for s in
            ("routerSettings", "litellmSettings") for k in proxy["spec"].get(s) or {}
            if k.endswith("fallbacks") and (s, k) not in modelled]
if not models or not keys:
    failures.append(f"{APP}: found no LiteLLMModel or LiteLLMVirtualKey documents")
for name, spec in sorted(keys.items()):
    if spec.get("maxBudget") is not None:
        continue
    if spec.get("aliases"):
        failures.append(f"{APP}/virtualkeys: budgetless key {name} sets aliases, which can map to billed models")
    reach = set(spec.get("models") or models)  # an empty or missing allow-list means every model
    while more := {t for m in reach for t in fallbacks.get(m, ())} - reach:
        reach |= more
    if billed := sorted(m for m in reach if not free(m)):
        failures.append(f"{APP}/virtualkeys: budgetless key {name} can reach billed models {billed}; set maxBudget")
passthrough = proxy["spec"]["generalSettings"]["pass_through_endpoints"]
for prefix in ("/openrouter", "/anthropic"):
    entries = [e for e in passthrough if e["path"].startswith(prefix)]
    failures += [f"{APP}/litellmproxy.yaml: pass-through {e['path']} must set auth: true" for e in entries
                 if e.get("auth") is not True]
    if not any(e["path"] == prefix and e.get("include_subpath") is True for e in entries):
        failures.append(f"{APP}/litellmproxy.yaml: {prefix} needs an include_subpath: true catch-all entry")
for failure in failures:
    print(f"FAIL {failure}")
sys.exit(1 if failures else 0)
