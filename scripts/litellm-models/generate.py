#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Generate one LiteLLMModel per upstream model, with USD prices, from a provider's public model list.

LiteLLM cannot list or price Venice (its cost map has no entries and `check_provider_endpoint` does not
support it), and a key's maxBudget only bounds priced models. This reads the provider's public catalog
(no API key) and writes `<out>/<provider>.yaml`, a multi-document file of LiteLLMModel CRs named
`<prefix>/<upstream id>` (`venice/<id>`, `openrouter/<id>`), which can never collide with a hand-curated
alias in `app/models/`. Output is a pure function of the catalog (sorted, no timestamps) apart from
dropping models whose retirement date has passed.

Refuses to write when the fetch fails or the catalog shrinks below half of the existing file, so an
upstream outage can never turn into a PR that deletes every model. Hand-rolled YAML keeps the output
byte-stable and yamlfmt-clean. Usage: scripts/litellm-models/generate.py --provider venice|openrouter [--out DIR]
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import re
import sys
import urllib.request
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = ROOT / "kubernetes/apps/base/ai/litellm/app/models-generated"
SCHEMA = "https://kubernetes-schemas.pages.dev/litellm.home-operations.com/litellmmodel_v1alpha1.json"

# Ids reach YAML and a Kubernetes name: allow-list the characters, never `$` (Flux substitution).
ID_RE = re.compile(r"^[A-Za-z0-9._:/@+-]+$")
PLAIN_RE = re.compile(r"^[A-Za-z0-9._/-]+$")
# A catalog this small means a broken response, not a real catalog.
MIN_MODELS = {"venice": 50, "openrouter": 100}


def fetch(url: str) -> Any:
    req = urllib.request.Request(url, headers={"User-Agent": "home-ops-litellm-models/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310 (fixed https URLs)
        return json.load(resp)


def dec(value: Any) -> Decimal | None:
    try:
        d = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return d if d.is_finite() else None


def num(d: Decimal) -> str:
    """Plain decimal, never scientific notation (YAML 1.1 loaders read 1e-06 as a string)."""
    return format(d.normalize(), "f")


def scalar(value: str) -> str:
    return value if PLAIN_RE.match(value) else json.dumps(value)


def past(stamp: Any, today: datetime.date) -> bool:
    if not isinstance(stamp, str) or len(stamp) < 10:
        return False
    try:
        return datetime.date.fromisoformat(stamp[:10]) <= today
    except ValueError:
        return False


def venice_models(today: datetime.date) -> list[dict[str, Any]]:
    data = fetch("https://api.venice.ai/api/v1/models?type=text")["data"]
    out = []
    for m in data:
        spec = m.get("model_spec") or {}
        pricing = spec.get("pricing") or {}
        # Venice quotes USD per 1M tokens.
        pin = dec((pricing.get("input") or {}).get("usd"))
        pout = dec((pricing.get("output") or {}).get("usd"))
        if not ID_RE.match(m.get("id", "")) or spec.get("offline") or pin is None or pout is None:
            continue
        if pin <= 0 or pout <= 0 or past((spec.get("deprecation") or {}).get("removesAt"), today):
            continue
        cap = spec.get("capabilities") or {}
        per_m = Decimal(1_000_000)
        extra = {"input_cost_per_token": pin / per_m, "output_cost_per_token": pout / per_m}
        cache = dec((pricing.get("cache_input") or {}).get("usd"))
        if cache is not None and cache > 0:
            extra["cache_read_input_token_cost"] = cache / per_m
        write = dec((pricing.get("cache_write") or {}).get("usd"))
        if write is not None and write > 0:
            extra["cache_creation_input_token_cost"] = write / per_m
        out.append(
            {
                "id": m["id"],
                "model": f"veniceai/{m['id']}",
                "api_key": "os.environ/VENICE_API_KEY",
                "context": spec.get("availableContextTokens") or m.get("context_length"),
                "max_output": spec.get("maxCompletionTokens"),
                "tools": bool(cap.get("supportsFunctionCalling")),
                "vision": bool(cap.get("supportsVision")),
                "reasoning": bool(cap.get("supportsReasoning")),
                "extra": extra,
            }
        )
    return out


def openrouter_models(today: datetime.date) -> list[dict[str, Any]]:
    out = []
    for m in fetch("https://openrouter.ai/api/v1/models")["data"]:
        arch = m.get("architecture") or {}
        pricing = m.get("pricing") or {}
        # OpenRouter quotes USD per token. Router meta-models carry a negative price.
        pin, pout = dec(pricing.get("prompt")), dec(pricing.get("completion"))
        if not ID_RE.match(m.get("id", "")) or m["id"].endswith(":free"):
            continue
        if arch.get("output_modalities") != ["text"] or "text" not in (arch.get("input_modalities") or []):
            continue
        if pin is None or pout is None or pin <= 0 or pout <= 0 or past(m.get("expiration_date"), today):
            continue
        params = m.get("supported_parameters") or []
        extra = {"input_cost_per_token": pin, "output_cost_per_token": pout}
        for key, field in (("input_cache_read", "cache_read_input_token_cost"), ("input_cache_write", "cache_creation_input_token_cost")):
            d = dec(pricing.get(key))
            if d is not None and d > 0:
                extra[field] = d
        out.append(
            {
                "id": m["id"],
                "model": f"openrouter/{m['id']}",
                "api_key": "os.environ/OPENROUTER_API_KEY",
                "context": m.get("context_length"),
                "max_output": (m.get("top_provider") or {}).get("max_completion_tokens"),
                "tools": "tools" in params,
                "vision": "image" in (arch.get("input_modalities") or []),
                "reasoning": "reasoning" in params,
                "extra": extra,
            }
        )
    return out


PROVIDERS = {
    "venice": (venice_models, "venice", "https://docs.venice.ai/api-reference/endpoint/models/list"),
    "openrouter": (openrouter_models, "openrouter", "https://openrouter.ai/docs/api-reference/list-available-models"),
}


def names(models: list[dict[str, Any]], prefix: str) -> dict[str, str]:
    """metadata.name per id: a DNS-1123 slug; ids whose slugs collide all get a short hash suffix."""

    def slug(model_id: str) -> str:
        labels = []
        for label in re.sub(r"[^a-z0-9.]+", "-", model_id.lower()).split("."):
            label = label.strip("-")[:63].strip("-")
            if label:
                labels.append(label)
        return f"{prefix}-" + ".".join(labels)

    slugs = {m["id"]: slug(m["id"]) for m in models}
    count: dict[str, int] = {}
    for s in slugs.values():
        count[s] = count.get(s, 0) + 1
    out = {}
    for model_id, s in slugs.items():
        out[model_id] = s if count[s] == 1 else f"{s[:240]}-{hashlib.sha1(model_id.encode()).hexdigest()[:6]}"
    return out


def render(provider: str, models: list[dict[str, Any]]) -> str:
    _, prefix, source = PROVIDERS[provider]
    ordered = sorted(models, key=lambda m: m["id"])
    named = names(ordered, prefix)
    lines = [
        "---",
        f"# yaml-language-server: $schema={SCHEMA}",
        f"# GENERATED by scripts/litellm-models/generate.py --provider {provider} from {source}.",
        "# Never edit by hand: .github/workflows/litellm-models.yaml regenerates it and opens a PR.",
        "# One LiteLLMModel per text model, named `" + prefix + "/<upstream id>`, priced in USD so a key's maxBudget",
        "# bounds it. Registration only: a key must allow-list a model to call it (nothing here grants access).",
    ]
    for i, m in enumerate(ordered):
        if i:
            lines.append("---")
        lines += [
            "apiVersion: litellm.home-operations.com/v1alpha1",
            "kind: LiteLLMModel",
            "metadata:",
            f"  name: {named[m['id']]}",
            "spec:",
            f"  modelName: {scalar(prefix + '/' + m['id'])}",
            "  proxyRef: litellm",
            "  params:",
            f"    model: {scalar(m['model'])}",
            f"    apiKey: {m['api_key']}",
            "  info:",
            "    mode: chat",
        ]
        if m["context"]:
            lines.append(f"    maxInputTokens: {int(m['context'])}")
        if m["max_output"]:
            lines.append(f"    maxOutputTokens: {int(m['max_output'])}")
        if m["tools"]:
            lines.append("    supportsFunctionCalling: true")
        if m["vision"]:
            lines.append("    supportsVision: true")
        lines.append("    extra:")
        lines += [f"      {k}: {num(v)}" for k, v in m["extra"].items()]
        if m["reasoning"]:
            lines.append("      supports_reasoning: true")
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--provider", required=True, choices=sorted(PROVIDERS))
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args()

    models = PROVIDERS[args.provider][0](datetime.datetime.now(datetime.timezone.utc).date())
    if len(models) < MIN_MODELS[args.provider]:
        print(f"refusing to write: only {len(models)} {args.provider} models (minimum {MIN_MODELS[args.provider]})", file=sys.stderr)
        return 1
    target = args.out / f"{args.provider}.yaml"
    if target.exists():
        before = target.read_text().count("\nkind: LiteLLMModel")
        if len(models) * 2 < before:
            print(f"refusing to write: {len(models)} models is under half of the existing {before}", file=sys.stderr)
            return 1
    args.out.mkdir(parents=True, exist_ok=True)
    target.write_text(render(args.provider, models))
    print(f"{args.provider}: {len(models)} models -> {target.relative_to(ROOT) if target.is_relative_to(ROOT) else target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
