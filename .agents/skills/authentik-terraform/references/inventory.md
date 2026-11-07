# What the stack owns

Blueprints own the flows, stages, policies, property mappings, groups, brand,
certificates and built-in source. Leave those as `data` sources.

OpenTofu resources:

| Object | How |
|---|---|
| Applications `coder`, `pg-admin`, `echo` and their providers | `import` blocks. Omit `client_secret`. Declare `property_mappings` |
| Proxy provider `sklab-externel-auth-provider` | imported. Live spelling is `externel`. Renaming it is a live rename of the ExtAuth provider. `mode = forward_domain`, `skip_path_regex = ""` |
| LiteLLM provider, application, `litellm_role` scope mapping, LiteLLM-only invalidation flow | created in `litellm.tofu`. `client_secret` is generated. `grant_types = ["authorization_code"]` |
| Home Assistant provider and application | created in `home-assistant.tofu`. Public client + PKCE, no secret, literal `client_id = home-assistant` repeated in the HA ConfigMap |

`open-webui` was removed from Authentik and from the stack (`tofu state rm`).
Do not re-import it.

`authentik_outpost.embedded` is a data source
(`managed = goauthentik.io/outposts/embedded`). Authentik reconciles that
outpost's config.

## ExtAuth surfaces

One provider, `forward_domain`, `external_host` `https://auth.${SECRET_DOMAIN}`,
`cookie_domain` `.${SECRET_DOMAIN}`. SecurityPolicies in git:

- `network/echo`
- `home-automation/home-assistant` (the `hass-code` browser terminal only; the Home Assistant
  route is not ExtAuth-gated, it signs in through the OIDC provider above)
- `home-automation/esphome` (dashboard and `/code/` editor), `home-automation/zigbee2mqtt`
  (rule `code` only; the frontend is not gated)
- `monitoring/alertmanager`
- `selfhosted/paperless-ngx`, `selfhosted/linkwarden` (rule `app` only; rule `api`, `/api`,
  stays on the app's own token auth for mobile apps and the browser extension)
- `ai/opencode`
- `ai/hermes` (the `hermes-code` browser terminal)
- `flux-system/headlamp`
- `kube-system/cilium` (Hubble UI)

ReferenceGrant `allow-authentik-access` allows `from` only the namespaces with a live
ExtAuth SecurityPolicy: `ai`, `flux-system`, `home-automation`, `kube-system`, `monitoring`,
`network`, `selfhosted` (the `database` entry was dropped, no consumer) to
Service `ak-outpost-authentik-embedded-outpost`. A SecurityPolicy in a new
namespace is accepted and then resolves its backend to nothing until the
grant lists that namespace.

The outpost's pre-auth check returns 302 to login for a Host that maps to no
route. Coverage of a new hostname is an authenticated login after merge, not
a curl.

## Created vs imported

| Field | Imported provider | Created provider |
|---|---|---|
| `client_secret` | omit (optional+computed, adopts live) | declare (nothing to adopt) |
| `grant_types` | omit | declare `["authorization_code"]` |
| `property_mappings` | declare | declare |
| flow ids | `.uuid`, never `.id` | `.uuid` |
