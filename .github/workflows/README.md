# GitHub Actions workflows

`ci.yaml`'s `CI Success` is the one gate. Every job in it runs on
`ubuntu-latest`. `image-pull.yaml` needs the cluster
and is advisory. Every `scripts/ci` test blocks PRs through `ci.yaml`.

Renovate's live writer is the in-cluster renovate-operator; `renovate.yaml` is
manual-dispatch only.
