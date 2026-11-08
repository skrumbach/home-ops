#!/usr/bin/env python3
"""Seed the Paperless-ngx starter taxonomy from taxonomy.yaml through the Paperless REST API.

    PAPERLESS_URL=https://docs.<domain> uv run --with pyyaml scripts/paperless-seed/seed.py          # dry run
    PAPERLESS_URL=https://docs.<domain> uv run --with pyyaml scripts/paperless-seed/seed.py --apply  # write

Credentials: PAPERLESS_USER / PAPERLESS_PASSWORD from the environment, else the admin login from 1Password item
`paperless-ngx` (vault Homelab, read with the desktop app session). Values are never printed.

Contract: objects are matched by name. Missing ones are created; for existing ones only the fields declared in
taxonomy.yaml are converged. Nothing is ever deleted. An existing workflow that differs is reported, not rewritten
(its nested triggers/actions have no safe in-place update). Written against Paperless-ngx 3.4.2.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import pathlib
import subprocess
import sys

import yaml

HERE = pathlib.Path(__file__).resolve().parent

MATCH_NONE = 0
TRIGGER = {"consumption": 1, "document_added": 2, "document_updated": 3, "scheduled": 4}
SOURCES_ALL = [1, 2, 3, 4]  # consume folder, API upload, mail fetch, web UI
ACTION = {"assign": 1, "remove": 2, "ai": 8}
RULE = {"has_tag": 6, "has_custom_field": 39}


class Api:
    def __init__(self, url: str, user: str, password: str, apply: bool) -> None:
        self.base = url.rstrip("/") + "/api"
        self.auth = base64.b64encode(f"{user}:{password}".encode()).decode()
        self.apply = apply

    def _curl(self, method: str, path: str, body: dict | None = None) -> dict | list:
        # curl, not urllib: some macOS Python builds ship without a CA bundle.
        url = path if path.startswith("http") else f"{self.base}/{path}"
        cmd = ["curl", "-sS", "-m", "60", "-X", method, "-w", "\n%{http_code}",
               "-H", f"Authorization: Basic {self.auth}", "-H", "Accept: application/json"]
        if body is not None:
            cmd += ["-H", "Content-Type: application/json", "--data-binary", json.dumps(body)]
        out = subprocess.run(cmd + [url], capture_output=True, text=True, check=True).stdout
        text, code = out.rsplit("\n", 1)
        if not code.startswith("2"):
            raise SystemExit(f"{method} {path}: HTTP {code}: {text[:400]}")
        return json.loads(text) if text.strip() else {}

    def list(self, path: str) -> list[dict]:
        items, url = [], f"{path}?page_size=1000"
        while url:
            page = self._curl("GET", url)
            items += page["results"]
            # Paperless builds `next` from the proxied request, so it comes back as http://.
            nxt = page.get("next")
            url = nxt.replace("http://", "https://", 1) if nxt else None
        return items

    def write(self, method: str, path: str, body: dict, what: str) -> dict:
        print(f"  {'APPLY' if self.apply else 'would'} {method} {what}")
        if not self.apply:
            return {"id": f"<new {what}>", **body}
        return self._curl(method, path, body)


def credentials() -> tuple[str, str]:
    user, password = os.environ.get("PAPERLESS_USER"), os.environ.get("PAPERLESS_PASSWORD")
    if user and password:
        return user, password
    env = {k: v for k, v in os.environ.items() if k != "OP_SERVICE_ACCOUNT_TOKEN"}

    def op(field: str) -> str:
        return subprocess.run(["op", "read", f"op://Homelab/paperless-ngx/{field}"], capture_output=True,
                              text=True, env=env, check=True).stdout.strip()

    return op("PAPERLESS_ADMIN_USER"), op("PAPERLESS_ADMIN_PASSWORD")


def converge(api: Api, path: str, want: dict, have: dict | None, label: str) -> dict:
    """Create `want` if missing, else PATCH only the declared fields that differ."""
    if have is None:
        return api.write("POST", f"{path}/", want, f"{path} {label!r}")
    diff = {k: v for k, v in want.items() if have.get(k) != v}
    if diff:
        return {**have, **api.write("PATCH", f"{path}/{have['id']}/", diff, f"{path} {label!r} {sorted(diff)}")}
    return have


def seed(api: Api, spec: dict) -> None:
    print("tags")
    tags = {t["name"]: t for t in api.list("tags/")}
    for t in spec["tags"]:
        want = {"name": t["name"], "color": t["color"], "is_inbox_tag": bool(t.get("inbox")),
                "matching_algorithm": MATCH_NONE}
        tags[t["name"]] = converge(api, "tags", want, tags.get(t["name"]), t["name"])

    print("document types")
    types = {t["name"]: t for t in api.list("document_types/")}
    for name in spec["document_types"]:
        types[name] = converge(api, "document_types", {"name": name, "matching_algorithm": MATCH_NONE},
                               types.get(name), name)

    print("custom fields")
    fields = {f["name"]: f for f in api.list("custom_fields/")}
    for f in spec["custom_fields"]:
        have = fields.get(f["name"])
        if have and have.get("data_type") != f["data_type"]:
            raise SystemExit(f"custom field {f['name']!r} is {have['data_type']}, taxonomy says {f['data_type']}; "
                             "a data type cannot be changed, fix it by hand")
        fields[f["name"]] = converge(api, "custom_fields", {"name": f["name"], "data_type": f["data_type"]},
                                     have, f["name"])

    def tag_ids(names: list[str]) -> list:
        return [tags[n]["id"] for n in names]

    print("saved views")
    views = {v["name"]: v for v in api.list("saved_views/")}
    for v in spec["saved_views"]:
        rules = []
        for r in v["rules"]:
            ref = tags[r["tag"]]["id"] if "tag" in r else fields[r["field"]]["id"]
            rules.append({"rule_type": RULE[r["rule"]], "value": str(ref)})
        sort = (f"custom_field_{fields[v['sort_custom_field']]['id']}" if "sort_custom_field" in v else v["sort"])
        want = {"name": v["name"], "sort_field": sort, "sort_reverse": v["reverse"], "filter_rules": rules}
        have = views.get(v["name"])
        if have is None:
            api.write("POST", "saved_views/", want, f"saved view {v['name']!r}")
        elif ({(r["rule_type"], r["value"]) for r in have.get("filter_rules", [])} != {(r["rule_type"], r["value"]) for r in rules}
              or have.get("sort_field") != sort or have.get("sort_reverse") != v["reverse"]):
            print(f"  DRIFT saved view {v['name']!r}: differs from taxonomy.yaml, left as is")

    print("workflows")
    flows = {w["name"]: w for w in api.list("workflows/")}
    for w in spec["workflows"]:
        tr = w["trigger"]
        trigger = {"type": TRIGGER[tr["type"]], "sources": SOURCES_ALL, "matching_algorithm": MATCH_NONE,
                   "filter_has_tags": tag_ids(tr.get("has_tags", []))}
        if tr["type"] == "scheduled":
            trigger |= {"schedule_date_field": "custom_field",
                        "schedule_date_custom_field": fields[tr["date_custom_field"]]["id"],
                        "schedule_offset_days": tr["offset_days"], "schedule_is_recurring": False}
        actions = []
        for order, a in enumerate(w["actions"]):
            act = {"type": ACTION[a["type"]], "order": order}
            if a["type"] == "assign":
                act["assign_tags"] = tag_ids(a["tags"])
            elif a["type"] == "remove":
                act["remove_tags"] = tag_ids(a["tags"])
            else:
                act |= {"ai_suggestion_fields": a["fields"], "ai_create_missing": a["create_missing"],
                        "ai_overwrite_existing": a["overwrite"]}
            actions.append(act)
        want = {"name": w["name"], "order": w["order"], "enabled": True, "triggers": [trigger], "actions": actions}
        have = flows.get(w["name"])
        if have is None:
            api.write("POST", "workflows/", want, f"workflow {w['name']!r}")
            continue
        # The API does not return an action's `order`; the list comes back in execution order.
        def strip(a: dict) -> dict:
            return {k: v for k, v in a.items() if k != "order"}

        got = [{k: a.get(k) for k in strip(act)} for a, act in zip(have["actions"], actions)]
        if len(have["actions"]) != len(actions) or got != [strip(a) for a in actions] or have.get("order") != w["order"]:
            print(f"  DRIFT workflow {w['name']!r}: differs from taxonomy.yaml, left as is (edit it in the UI "
                  "or delete it and re-run --apply)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    ap.add_argument("--taxonomy", default=HERE / "taxonomy.yaml", type=pathlib.Path)
    args = ap.parse_args()
    url = os.environ.get("PAPERLESS_URL") or sys.exit("set PAPERLESS_URL, e.g. https://docs.<domain>")
    spec = yaml.safe_load(args.taxonomy.read_text())
    seed(Api(url, *credentials(), apply=args.apply), spec)
    print("done" if args.apply else "dry run only; re-run with --apply")


if __name__ == "__main__":
    main()
