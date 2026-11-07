# Authentik server upgrade

Chart and image move together. Tag is
`kubernetes/apps/base/security/authentik/app/helmrelease.yaml`
(`OCIRepository` `ref.tag`). Current line when this skill was written:
`2026.8.3`. Release lines are quarterly: 2026.2, 2026.5, 2026.8, 2026.11.
There is no 2026.6 or 2026.7.

One line forward is one Django migration set. Migrations are one-way. Confirm
CNPG `database/postgres-18` `Ready`, `ContinuousArchiving` and a recent
successful `Backup` before the bump. The bundled Bitnami postgres subchart is
disabled here. Its image bump is irrelevant.

## Before 2026.11

The Base URL system setting (API field `base_url`) is optional on 2026.8. On
upstream main (the 2026.11 line) a set-up instance with it empty refuses to
start (`ImproperlyConfigured`, `post_startup_require_base_url`). Value: `https://auth.${SECRET_DOMAIN}`, scheme and
host only, no path, no trailing slash.

Only while it is empty, every startup backfills it from
`AUTHENTIK_WEB__BASE_URL` (the HelmRelease's `authentik.web.base_url`), then
from the embedded outpost's `authentik_host` (live: the same URL). A value
set in the UI or API always wins.

OpenTofu cannot hold it: `authentik_system_settings` (provider 2026.8.2 and
upstream main) has no `base_url`. That resource is a singleton that writes
every field, so an undeclared field resets to its default. Do not add it.

The read-only `tofu-readonly` token gets 403 on `/api/v3/admin/settings/`.
Before the bump the owner confirms the value in Admin UI > System > Settings >
Base URL, or with an admin token:
`curl -s -H "Authorization: Bearer $TOKEN" https://auth.${SECRET_DOMAIN}/api/v3/admin/settings/ | jq -r .base_url`.
Empty means set it there and save.

Renovate never automerges an Authentik release line (`.renovate/autoMerge.json5`).

## Trusted proxies

`AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS` is unset, so the default applies
(`10.0.0.0/8` among others). The pod network `10.42.0.0/16` sits inside that
range, which is why Envoy's `X-Forwarded-*` headers stay trusted. A miss
shows up as HTTPS treated as HTTP (redirect loops, mixed content). Re-check
the default if the pod CIDR ever leaves `10.0.0.0/8`.

## After the pods are Ready

Read-only. Expect the same shape as before the bump.

| Surface | Check | Healthy |
|---|---|---|
| hass, kromgo, echo, opencode | `curl -sI` the hostname | 302 to `auth.${SECRET_DOMAIN}` authorize |
| coder | `GET /api/v2/users/authmethods` | `oidc.enabled=true` |
| coder discovery | `https://auth.${SECRET_DOMAIN}/application/o/coder/.well-known/openid-configuration` | issuer and endpoints present |
| authentik | `curl -sI https://auth.${SECRET_DOMAIN}/` | 302 to the default authentication flow |

A 401 or a non-redirect on the outpost apps, or `oidc.enabled=false`, is a
regression. The 302 alone does not prove a brand-new hostname is authorized.
See [inventory.md](inventory.md).

The embedded outpost Service selects the server pod. There is no separate
outpost Deployment to upgrade.

A provider-plugin bump (`terraform-provider-authentik`, often a Renovate PR
on `main.tofu` and `.terraform.lock.hcl`) is not the server upgrade. Re-run
its `tofu plan` after the server is on the line the provider requires. Apply
still needs the go-ahead in [apply-runbook.md](apply-runbook.md).
