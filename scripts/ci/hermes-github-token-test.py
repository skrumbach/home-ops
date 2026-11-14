#!/usr/bin/env python3
"""Hermes' HOMELAB_GH_TOKEN renders from the read-only GitHub token, never the write one.

Prevents: the agent's terminal (which sees this variable) gaining a token that can push to home-ops.
"""

import sys
from pathlib import Path

import yaml

FILE = "kubernetes/apps/base/ai/hermes/app/externalsecret.yaml"
docs = yaml.safe_load_all((Path(__file__).resolve().parents[2] / FILE).read_text())
(hermes,) = [d for d in docs if d and d["metadata"]["name"] == "hermes"]
token = hermes["spec"]["target"]["template"]["data"]["HOMELAB_GH_TOKEN"]
if "HOMELAB_GH_READ_TOKEN" not in token or ".HOMELAB_GH_TOKEN" in token:
    sys.exit(f"FAIL {FILE}: HOMELAB_GH_TOKEN must render from .HOMELAB_GH_READ_TOKEN, got {token!r}")
