# GitHub Actions runners

Image and chart pins live in the HelmReleases. Taskfile recipes cover
`skrumbach/home-ops` only. `task actions-runner:diagnose` is the status
entry.

An `image-pull` failure `remote error: tls: expired certificate` is the
runner client cert. Delete Secret `actions-runner` in `actions-runner-system`
so the controller reissues it.
