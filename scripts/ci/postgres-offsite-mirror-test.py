#!/usr/bin/env python3
"""Contract for the postgres-18 off-site (R2) archive mirror and its alert.

The mirror copies the live barman archive to Cloudflare R2. It can go silently
useless in ways no other check sees: a restore bumps the Cluster's archiver
serverName (skill `databases`) while the CronJob keeps copying the old path and
still succeeds, or an edit turns `rclone copy` into a deleting `sync`.

Static checks:
  - the CronJob is live (suspend: false);
  - SERVER_NAME is the Cluster's WAL-archiver serverName, ARCHIVE_BUCKET and the
    LAN endpoint match the ObjectStore the archiver writes to;
  - the script runs under `set -eu`, copies (never sync/move/purge/--delete-*),
    exits 1 on a source with no base backup and on a prune over PRUNE_CEILING
    (checked before `rclone delete`), and prunes by R2 upload time
    (--use-server-modtime);
  - every shell `${`/`$(` is Flux-escaped (`$${`/`$$(`);
  - every R2 secretKeyRef key is produced by the ExternalSecret;
  - prometheusrule.yaml is wired into the kustomization.

Behaviour (`promtool test rules`) of PostgresOffsiteMirrorStale:
  - never succeeded (no series)          -> fires after for: 2h
  - hourly successes                     -> silent
  - successes stop                       -> pending from 4h, firing from 6h
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
CNPG = ROOT / "kubernetes/apps/base/database/cloudnative-pg"
MIRROR = CNPG / "offsite-mirror"
ALERT = "PostgresOffsiteMirrorStale"
LABELS = {"namespace": "database", "cronjob": "postgres-offsite-mirror"}


class Failure(Exception):
    pass


def check(cond: bool, msg: str) -> None:
    if not cond:
        raise Failure(msg)


def load(path: Path) -> list[dict]:
    return [d for d in yaml.safe_load_all(path.read_text()) if d]


def promtool() -> str:
    found = shutil.which("promtool")
    if found and subprocess.run([found, "--version"], capture_output=True).returncode == 0:
        return found
    mise = shutil.which("mise")
    if mise:
        proc = subprocess.run([mise, "which", "promtool"], capture_output=True, text=True)
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout.strip()
    raise Failure("promtool not found (mise aqua:prometheus/prometheus)")


def static_checks() -> dict:
    (cronjob,) = load(MIRROR / "cronjob.yaml")
    check(cronjob["spec"].get("suspend") is False, "CronJob postgres-offsite-mirror must be suspend: false")
    pod = cronjob["spec"]["jobTemplate"]["spec"]["template"]["spec"]
    (container,) = pod["containers"]
    env = {e["name"]: e for e in container["env"]}

    (cluster,) = load(CNPG / "cluster-18/cluster-18.yaml")
    archivers = [p for p in cluster["spec"].get("plugins", []) if p.get("isWALArchiver")]
    check(len(archivers) == 1, "cluster-18 must have exactly one isWALArchiver plugin")
    params = archivers[0]["parameters"]
    check(
        env["SERVER_NAME"]["value"] == params["serverName"],
        f"mirror SERVER_NAME {env['SERVER_NAME']['value']!r} != archiver serverName {params['serverName']!r}: "
        "bump the mirror in the same commit as the Cluster",
    )
    stores = {d["metadata"]["name"]: d for d in load(CNPG / "cluster-18/objectstore.yaml")}
    store = stores[params["barmanObjectName"]]["spec"]["configuration"]
    bucket = re.fullmatch(r"s3://([^/]+)/?", store["destinationPath"])
    check(bucket is not None, f"unexpected destinationPath {store['destinationPath']!r}")
    check(
        env["ARCHIVE_BUCKET"]["value"] == bucket.group(1),
        f"ARCHIVE_BUCKET {env['ARCHIVE_BUCKET']['value']!r} != ObjectStore bucket {bucket.group(1)!r}",
    )
    check(
        env["RCLONE_CONFIG_LAN_ENDPOINT"]["value"] == store["endpointURL"],
        "RCLONE_CONFIG_LAN_ENDPOINT must equal the ObjectStore endpointURL",
    )

    script = container["command"][-1]
    code = "\n".join(line for line in script.splitlines() if not line.lstrip().startswith("#"))
    check(re.search(r"\brclone copy\b", code) is not None, "script must `rclone copy`")
    for banned in (r"\brclone sync\b", r"\brclone move\b", r"\brclone purge\b", r"--delete-"):
        check(re.search(banned, code) is None, f"script must not use {banned!r}")
    check(code.lstrip().startswith("set -eu"), "script must start with `set -eu` (a failed copy must stop the prune)")
    # The guard: list base/*/backup.info into a file, then `exit 1` when it is empty.
    guard = re.search(
        r'rclone lsf [^\n]*--include "/\*/backup\.info" \\\n\s*"\$\$\{SRC\}/base" >(\S+)\n'
        r"\s*if \[ ! -s \1 \]; then\n[^\n]*\n\s*exit 1\n",
        code,
    )
    check(guard is not None, "script must exit 1 when the source lists no base/*/backup.info")
    ceiling = re.search(r'if \[ "\$\$\{CANDIDATES\}" -gt "\$\$\{PRUNE_CEILING\}" \]; then\n[^\n]*\n\s*exit 1\n', code)
    check(ceiling is not None, "script must exit 1 when prune candidates exceed PRUNE_CEILING")
    check(
        guard.start() < code.find("rclone copy") and ceiling.start() < code.find("rclone delete"),
        "the source guard must precede the copy and the ceiling check must precede rclone delete",
    )
    # Each rclone invocation including its `\`-continued lines.
    calls = [m.group(0) for m in re.finditer(r"rclone (?:[^\n]*\\\n)*[^\n]*", code)]
    prunes = [c for c in calls if "--min-age" in c]
    check(
        any(c.startswith("rclone lsf") for c in prunes) and any(c.startswith("rclone delete") for c in prunes),
        "script must count (lsf) and prune (delete) by --min-age",
    )
    for c in prunes:
        check("--use-server-modtime" in c, f"prune call must use --use-server-modtime: {c.splitlines()[0]}")
    check(
        re.search(r"(?<!\$)\$[{(]", code) is None,
        "unescaped shell `${`/`$(` in the script: Flux substitutes it (skill flux-substitution)",
    )

    (es,) = load(MIRROR / "externalsecret.yaml")
    produced = {d["secretKey"] for d in es["spec"]["data"]}
    wanted = {
        e["valueFrom"]["secretKeyRef"]["key"]
        for e in container["env"]
        if e.get("valueFrom", {}).get("secretKeyRef", {}).get("name") == es["spec"]["target"]["name"]
    }
    check(wanted and wanted <= produced, f"secretKeyRef keys {sorted(wanted - produced)} not in the ExternalSecret")

    (kust,) = load(MIRROR / "kustomization.yaml")
    check("./prometheusrule.yaml" in kust["resources"], "prometheusrule.yaml not wired into offsite-mirror")
    (rule,) = load(MIRROR / "prometheusrule.yaml")
    return rule


def series(metric: str, values: str) -> dict:
    labels = ", ".join(f'{k}="{v}"' for k, v in LABELS.items())
    return {"series": f"{metric}{{{labels}}}", "values": values}


def case(name: str, inputs: list[dict], at: list[tuple[str, bool]], exp: dict) -> dict:
    return {
        "name": name,
        "interval": "1m",
        "input_series": inputs,
        "alert_rule_test": [
            {"eval_time": t, "alertname": ALERT, "exp_alerts": [exp] if fires else []} for t, fires in at
        ],
    }


def main() -> int:
    rule = static_checks()
    alerts = {r["alert"]: r for g in rule["spec"]["groups"] for r in g["rules"] if "alert" in r}
    check(ALERT in alerts and alerts[ALERT]["labels"].get("severity") == "warning", f"{ALERT} missing or not warning")
    exp = {"exp_labels": {"severity": "warning", **LABELS}, "exp_annotations": alerts[ALERT]["annotations"]}
    unrelated = series("kube_cronjob_spec_suspend", "0x600")
    tests = [
        case("never_succeeded_fires", [unrelated], [("1h", False), ("3h", True)], exp),
        # last_successful_time tracks the clock: a success every hour (value ~= t).
        case(
            "hourly_success_silent",
            [series("kube_cronjob_status_last_successful_time", "0+60x1440")],
            [("3h", False), ("12h", False), ("23h", False)],
            exp,
        ),
        # Successes stop at 10h: age > 4h from 14h, firing after for: 2h (16h).
        case(
            "stopped_fires_after_6h",
            [series("kube_cronjob_status_last_successful_time", "0+60x600 36000x900")],
            [("12h", False), ("15h", False), ("17h", True)],
            exp,
        ),
    ]
    with tempfile.TemporaryDirectory(prefix="offsite-mirror-alert-") as tmp:
        work = Path(tmp)
        (work / "rules.yml").write_text(yaml.safe_dump({"groups": rule["spec"]["groups"]}, sort_keys=False))
        (work / "test.yml").write_text(
            yaml.safe_dump({"rule_files": ["rules.yml"], "evaluation_interval": "1m", "tests": tests}, sort_keys=False)
        )
        for args in (["check", "rules", "rules.yml"], ["test", "rules", "test.yml"]):
            proc = subprocess.run([promtool(), *args], cwd=work, capture_output=True, text=True)
            if proc.returncode != 0:
                raise Failure(f"promtool {' '.join(args)}:\n{proc.stdout}{proc.stderr}")
    print(f"[PASS] offsite mirror contract + {ALERT}: never/stopped fire, hourly silent")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Failure as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        sys.exit(1)
