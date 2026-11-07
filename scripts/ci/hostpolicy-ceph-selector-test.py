#!/usr/bin/env python3
# ci: gate
"""Semantic regression test for the Ceph LAN-isolation host CCNP selector.

Prevents: a host-firewall CiliumClusterwideNetworkPolicy that locks out all three nodes
(default-deny ingress) or never attaches to its host endpoints.

Background (measured 2026-08-24 on talos-1/2/3): Cilium's default label filter
strips several well-known node labels from the *host endpoint* label set. A
CCNP nodeSelector that only matches stripped labels is accepted (VALID:True)
but never attaches to the host endpoint (policy-enabled:none, zero Deny rows).
The first stage-1 policy used kubernetes.io/os=linux and was inert on every node.

This test does not grep source text (except the Jinja Talos template in step 5). It:
  1. Loads the rendered CCNP as a structured object (via kubectl kustomize, or
     the source manifest if kustomize is unavailable).
  2. Implements Kubernetes label-selector matching against the *measured* host
     endpoint label sets (and the fuller node label sets for contrast).
  3. Asserts the shipped selector matches every host endpoint, while the known-
     broken selector matches none of them (and would have matched the nodes).
  4. Asserts the subtractive safety contract: enableDefaultDeny ingress/egress
     are false, ingressDeny is world-only, and stage-2 enforcement is on
     (policyAuditMode false with hostFirewall still enabled).
  5. Asserts every denied non-Ceph metrics port is pinned explicitly where its
     listener is configured (cilium and kube-prometheus-stack HelmRelease values,
     the Talos etcd template) and every pin is a denied port. A chart bump that
     changes a default port cannot move a pinned listener, and a deliberate port
     change has to update the deny list too. It checks the values key, not the
     rendered listener: a chart that renames the key shows up as flate's "values
     not used by the chart" and in the Renovate PR's render diff, not here.

Live BPF verification (cilium-dbg bpf policy get) remains the post-merge gate in
.agents/skills/cilium-host-policy/references/gates.md; this test catches the silent-open
selector class of failure offline.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
CILIUM_APP = ROOT / "kubernetes/apps/base/kube-system/cilium/app"
POLICY_PATH = CILIUM_APP / "hostpolicy-ceph.yaml"
HELMRELEASE_PATH = CILIUM_APP / "helmrelease.yaml"
KPS_HELMRELEASE_PATH = (
    ROOT / "kubernetes/apps/base/monitoring/kube-prometheus-stack/app/helmrelease.yaml"
)
TALOS_MACHINECONFIG_PATH = ROOT / "talos/machineconfig.yaml.j2"

# Labels Cilium's default filter drops from the host endpoint (measured).
HOST_ENDPOINT_DROPPED_LABELS = frozenset(
    {
        "beta.kubernetes.io/arch",
        "beta.kubernetes.io/os",
        "kubernetes.io/arch",
        "kubernetes.io/hostname",
        "kubernetes.io/os",
    }
)

# Measured host-endpoint label sets (identical shape on talos-1/2/3; hostname
# differs on the *node* but is stripped before it reaches the host endpoint).
# Values that survive were measured live.
HOST_ENDPOINT_LABELS: dict[str, dict[str, str]] = {
    "talos-1": {
        "node-role.kubernetes.io/control-plane": "",
        "topology.kubernetes.io/region": "home",
        "topology.kubernetes.io/zone": "home",
        "extensions.talos.dev/schematic": "present",
    },
    "talos-2": {
        "node-role.kubernetes.io/control-plane": "",
        "topology.kubernetes.io/region": "home",
        "topology.kubernetes.io/zone": "home",
        "extensions.talos.dev/schematic": "present",
    },
    "talos-3": {
        "node-role.kubernetes.io/control-plane": "",
        "topology.kubernetes.io/region": "home",
        "topology.kubernetes.io/zone": "home",
        "extensions.talos.dev/schematic": "present",
    },
}

# Full node label sets include the dropped labels. Used only to show the old
# selector would have matched nodes (and therefore looked correct on paper).
NODE_LABELS: dict[str, dict[str, str]] = {
    name: {
        **labels,
        "kubernetes.io/os": "linux",
        "kubernetes.io/arch": "amd64",
        "kubernetes.io/hostname": name,
        "beta.kubernetes.io/os": "linux",
        "beta.kubernetes.io/arch": "amd64",
    }
    for name, labels in HOST_ENDPOINT_LABELS.items()
}

# The selector that shipped inert in stage 1.
BROKEN_SELECTOR: dict[str, Any] = {
    "matchLabels": {"kubernetes.io/os": "linux"},
}

CEPH_DENY_PORTS = {
    ("3300", None),
    ("6789", None),
    ("80", None),
    ("9283", None),
    ("9926", None),
    ("8003", None),
    ("7000", None),
    ("8443", None),
    ("6800", 7568),
}
# Non-Ceph unauthenticated host-netns metrics: etcd, node-exporter, Cilium/Hubble.
METRICS_DENY_ENTRIES = {
    ("2381", None),
    ("9100", None),
    ("9962", 9965),
}
EXPECTED_DENY_PORTS = CEPH_DENY_PORTS | METRICS_DENY_ENTRIES

# METRICS_DENY_ENTRIES expanded. Each port needs exactly one explicit pin below
# (never a chart default), and each pin must be a denied port.
METRICS_DENY_PORTS = {
    port
    for start, end in METRICS_DENY_ENTRIES
    for port in range(int(start), (end or int(start)) + 1)
}

# (HelmRelease, path under spec.values) for each host-netns metrics listener.
PINNED_HELM_PORTS: list[tuple[Path, tuple[str, ...]]] = [
    (HELMRELEASE_PATH, ("prometheus", "port")),  # cilium-agent 9962
    (HELMRELEASE_PATH, ("operator", "prometheus", "port")),  # cilium-operator 9963
    (HELMRELEASE_PATH, ("envoy", "prometheus", "port")),  # agent/envoy proxy 9964
    (HELMRELEASE_PATH, ("hubble", "metrics", "port")),  # hubble metrics 9965
    (KPS_HELMRELEASE_PATH, ("prometheus-node-exporter", "service", "port")),  # 9100
]

# Talos etcd metrics listener (a Jinja template, so matched as text).
ETCD_METRICS_RE = re.compile(r"^\s*listen-metrics-urls:\s*http://[^\s:/]+:(\d+)\s*$", re.M)


class Failure(Exception):
    pass


def load_policy() -> dict[str, Any]:
    """Load the ceph-lan-isolation CCNP as a structured object."""
    # Prefer the kustomize-built object (what Flux applies).
    try:
        built = subprocess.run(
            ["kubectl", "kustomize", str(CILIUM_APP)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        for doc in yaml.safe_load_all(built):
            if (
                isinstance(doc, dict)
                and doc.get("kind") == "CiliumClusterwideNetworkPolicy"
                and (doc.get("metadata") or {}).get("name") == "ceph-lan-isolation"
            ):
                return doc
    except (FileNotFoundError, subprocess.CalledProcessError):
        pass

    doc = yaml.safe_load(POLICY_PATH.read_text())
    if not isinstance(doc, dict) or doc.get("kind") != "CiliumClusterwideNetworkPolicy":
        raise Failure(f"could not load CCNP from {POLICY_PATH}")
    return doc


def load_helm_values(path: Path = HELMRELEASE_PATH) -> dict[str, Any]:
    hr = yaml.safe_load(path.read_text())
    return ((hr or {}).get("spec") or {}).get("values") or {}


def pinned_metrics_ports(cilium_values: dict[str, Any]) -> dict[str, int]:
    """Return {source: port} for every explicit metrics-port pin; fail if one is unset."""
    pins: dict[str, int] = {}
    values_by_path: dict[Path, dict[str, Any]] = {HELMRELEASE_PATH: cilium_values}
    for path, keys in PINNED_HELM_PORTS:
        if path not in values_by_path:
            values_by_path[path] = load_helm_values(path)
        node: Any = values_by_path[path]
        for key in keys:
            node = node.get(key) if isinstance(node, dict) else None
        source = f"{path.relative_to(ROOT)}: spec.values.{'.'.join(keys)}"
        assert_true(
            node is not None,
            f"{source} is unset: pin it at the port the host policy denies "
            "(a chart default can move on a bump and reopen the port to the LAN)",
        )
        try:
            pins[source] = int(node)
        except (TypeError, ValueError):
            raise Failure(f"{source} is not a port number: {node!r}") from None

    talos_rel = TALOS_MACHINECONFIG_PATH.relative_to(ROOT)
    etcd = ETCD_METRICS_RE.findall(TALOS_MACHINECONFIG_PATH.read_text())
    assert_true(len(etcd) == 1, f"expected one etcd listen-metrics-urls in {talos_rel}, got {etcd}")
    pins[f"{talos_rel}: etcd listen-metrics-urls"] = int(etcd[0])
    return pins


def is_denied(port: int, deny: set[tuple[str, int | None]]) -> bool:
    return any(int(start) <= port <= (end or int(start)) for start, end in deny)


def match_labels(selector: dict[str, Any] | None, labels: dict[str, str]) -> bool:
    """Evaluate a Kubernetes label selector against a label map."""
    if not selector:
        # Empty selector matches everything. Host-policy docs do not document
        # this for CCNP nodeSelector; the shipped policy must not rely on it.
        return True

    for key, value in (selector.get("matchLabels") or {}).items():
        if labels.get(key) != value:
            return False

    for expr in selector.get("matchExpressions") or []:
        key = expr["key"]
        op = expr["operator"]
        values = list(expr.get("values") or [])
        present = key in labels
        label_value = labels.get(key)

        if op == "Exists":
            if not present:
                return False
        elif op == "DoesNotExist":
            if present:
                return False
        elif op == "In":
            if not present or label_value not in values:
                return False
        elif op == "NotIn":
            if present and label_value in values:
                return False
        else:
            raise Failure(f"unsupported selector operator: {op}")
    return True


def selector_keys(selector: dict[str, Any]) -> set[str]:
    keys = set((selector.get("matchLabels") or {}).keys())
    for expr in selector.get("matchExpressions") or []:
        keys.add(expr["key"])
    return keys


def port_key(port: dict[str, Any]) -> tuple[str, int | None]:
    return (str(port["port"]), port.get("endPort"))


def assert_true(cond: bool, msg: str) -> None:
    if not cond:
        raise Failure(msg)


def main() -> int:
    findings: list[str] = []
    evidence: dict[str, Any] = {"nodes": {}}

    try:
        policy = load_policy()
        spec = policy.get("spec") or {}
        selector = spec.get("nodeSelector")
        assert_true(isinstance(selector, dict) and bool(selector),
                    "nodeSelector must be an explicit non-empty selector")

        keys = selector_keys(selector)
        stripped = keys & HOST_ENDPOINT_DROPPED_LABELS
        assert_true(
            not stripped,
            f"nodeSelector uses host-endpoint-stripped label(s): {sorted(stripped)}",
        )
        assert_true(
            "node-role.kubernetes.io/control-plane" in keys,
            "expected control-plane Exists selector covering this all-CP cluster",
        )

        # Regression: broken selector matches nodes, matches zero host endpoints.
        broken_node_hits = [
            n for n, labels in NODE_LABELS.items() if match_labels(BROKEN_SELECTOR, labels)
        ]
        broken_host_hits = [
            n
            for n, labels in HOST_ENDPOINT_LABELS.items()
            if match_labels(BROKEN_SELECTOR, labels)
        ]
        assert_true(
            broken_node_hits == sorted(NODE_LABELS),
            "precondition failed: broken selector should match all nodes",
        )
        assert_true(
            broken_host_hits == [],
            "precondition failed: broken selector must match no host endpoints "
            f"(got {broken_host_hits})",
        )

        # Shipped selector must match every host endpoint and every node.
        shipped_host_hits = []
        shipped_node_hits = []
        for name in sorted(HOST_ENDPOINT_LABELS):
            host_ok = match_labels(selector, HOST_ENDPOINT_LABELS[name])
            node_ok = match_labels(selector, NODE_LABELS[name])
            evidence["nodes"][name] = {
                "host_endpoint_match": host_ok,
                "node_match": node_ok,
                "broken_host_endpoint_match": match_labels(
                    BROKEN_SELECTOR, HOST_ENDPOINT_LABELS[name]
                ),
                "broken_node_match": match_labels(BROKEN_SELECTOR, NODE_LABELS[name]),
            }
            if host_ok:
                shipped_host_hits.append(name)
            if node_ok:
                shipped_node_hits.append(name)

        assert_true(
            shipped_host_hits == sorted(HOST_ENDPOINT_LABELS),
            f"shipped selector missed host endpoints: matched {shipped_host_hits}",
        )
        assert_true(
            shipped_node_hits == sorted(NODE_LABELS),
            f"shipped selector missed nodes: matched {shipped_node_hits}",
        )

        # Subtractive safety contract - stage 2 enforcing.
        # Anti-lockout comes from enableDefaultDeny false/false (NOT from audit
        # mode). Only enumerated (world, port) pairs can be dropped.
        edd = spec.get("enableDefaultDeny") or {}
        assert_true(edd.get("ingress") is False, "enableDefaultDeny.ingress must be false")
        assert_true(edd.get("egress") is False, "enableDefaultDeny.egress must be false")

        ingress = spec.get("ingress") or []
        egress = spec.get("egress") or []
        ingress_deny = spec.get("ingressDeny") or []
        assert_true(ingress == [], "no ingress allow rules (would risk default-deny OR)")
        assert_true(egress == [], "no egress rules expected on this deny-only policy")
        assert_true(len(ingress_deny) == 1, "expected a single ingressDeny rule")
        entities = set(ingress_deny[0].get("fromEntities") or [])
        assert_true(entities == {"world"}, f"fromEntities must be only world, got {entities}")

        ports = {
            port_key(p)
            for tp in ingress_deny[0].get("toPorts") or []
            for p in tp.get("ports") or []
        }
        assert_true(
            ports == EXPECTED_DENY_PORTS,
            f"deny port set mismatch:\n  got {sorted(ports)}\n  want {sorted(EXPECTED_DENY_PORTS)}",
        )

        # Metrics listeners: every pin denied, every denied metrics port pinned once.
        values = load_helm_values()
        pins = pinned_metrics_ports(values)
        open_pins = {src: p for src, p in pins.items() if not is_denied(p, ports)}
        assert_true(
            not open_pins,
            f"metrics port pinned outside the world-deny list (LAN-exposed): {open_pins}; "
            "change hostpolicy-ceph.yaml and METRICS_DENY_ENTRIES together",
        )
        assert_true(
            sorted(pins.values()) == sorted(METRICS_DENY_PORTS),
            f"metrics pins {sorted(pins.values())} != denied metrics ports "
            f"{sorted(METRICS_DENY_PORTS)} (each needs exactly one explicit pin)",
        )

        assert_true(
            values.get("policyAuditMode") is False,
            "stage-2 requires policyAuditMode: false (enforcing after audit evidence)",
        )
        host_fw = values.get("hostFirewall") or {}
        assert_true(
            host_fw.get("enabled") is True,
            "hostFirewall.enabled must remain true for the CCNP to matter",
        )

        evidence.update(
            {
                "policy": policy["metadata"]["name"],
                "nodeSelector": selector,
                "enableDefaultDeny": edd,
                "fromEntities": sorted(entities),
                "denyPorts": sorted(
                    [{"port": p, "endPort": e} for p, e in ports],
                    key=lambda x: (x["port"], x["endPort"] or -1),
                ),
                "metricsPortPins": pins,
                "policyAuditMode": values.get("policyAuditMode"),
                "hostFirewall.enabled": host_fw.get("enabled"),
                "brokenSelectorHostMatches": broken_host_hits,
                "brokenSelectorNodeMatches": broken_node_hits,
                "shippedSelectorHostMatches": shipped_host_hits,
                "result": "PASS",
            }
        )
        print(json.dumps(evidence, indent=2, sort_keys=True))
        print(
            "OK: shipped selector matches all 3 host endpoints; "
            "broken kubernetes.io/os selector matches 0; "
            "enableDefaultDeny false/false; policyAuditMode false (enforcing); "
            f"{len(pins)} metrics port pins all denied",
            file=sys.stderr,
        )
        return 0
    except Failure as exc:
        findings.append(str(exc))
        evidence["result"] = "FAIL"
        evidence["findings"] = findings
        print(json.dumps(evidence, indent=2, sort_keys=True))
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
