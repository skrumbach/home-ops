# ai namespace

GitOps for this cluster's AI stack. Flux overlays: `kubernetes/apps/main/ai/`.

| Job | App |
| --- | --- |
| Agent runtime | `hermes/` |
| LLM gateway and governance | `litellm/`, `litellm-operator/`, `litellm-pgvector/` |
| MCP | `toolhive/` |
| Local chat and embeddings | `vllm/`, `embedding-gpu/` |
| GPU devices and telemetry | `gpu-node-dashboard/` plus the device plugins under `system/` |
| Coding consumers | `opencode/`, `repo-wiki/` |
| Subscription proxy | `cliproxyapi/` |
| Web search | `searxng/` |
| Shared files | `samba/`, `pvc/` |

kagent, kmcp, kgateway and agentgateway are not deployed (agentgateway was
retired 2026-10-25; LiteLLM is the only LLM gateway). Retained backups outlive
retired apps: kopiur Snapshot CRs in `ai` (agentmemory, comfyui-user) own their kopia
snapshots, so deleting a CR deletes the backup. Retired VolSync restic repos
(`scripts/volsync-retired-expiry/ledger.yaml`) hold agentmemory's older copy.
