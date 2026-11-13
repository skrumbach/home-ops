# renovate

mogenius `renovate-operator` with one hourly `RenovateJob` (`home-ops`). The
GitHub Actions workflow is rollback only (manual dispatch). UI at
`renovate.sklab.dev`, internal route, Pocket ID OIDC (`renovate-operator/app/pocketidoidcclient.yaml`; the client
secret is generated in the cluster by `renovate-operator/app/externalsecret.yaml`, not kept in 1Password).

## Rollback

1. Set `spec.suspend: true` on `renovate-operator/jobs/renovatejob.yaml` and merge.
2. Dispatch `.github/workflows/renovate.yaml` (or add a `schedule` to it).

GitHub App fields: 1Password `Homelab/renovate` (`BOT_APP_ID`,
`BOT_APP_PRIVATE_KEY`); the installation ID is in `renovate-operator/jobs/externalsecret.yaml`.
Alerts use the operator's own metrics (`RenovateRunFailed`, `RenovateRunMissing`,
`RenovateDiscoveryEmpty`, `RenovateJobSuspended`, `RenovateOperatorAbsent`).
