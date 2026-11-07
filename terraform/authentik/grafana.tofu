# Grafana single sign-on (generic OAuth). CREATED by this stack (no import block). Confidential
# client: client_id is a plain literal the HelmRelease repeats; the secret is generated here and
# copied once into 1Password Homelab/grafana-oidc (never Git). Role mapping and the deny-by-default
# rule (role_attribute_strict) live on the Grafana side:
# kubernetes/apps/base/monitoring/grafana/app/helmrelease.yaml (skill `observability`).

locals {
  # Public identifier. Must match grafana.ini auth.generic_oauth.client_id in the HelmRelease.
  grafana_client_id = "grafana"
}

resource "random_password" "grafana_client_secret" {
  length  = 64
  special = false
  # Alphanumeric: it reaches Grafana through an environment variable.
}

resource "authentik_provider_oauth2" "grafana" {
  name          = "Grafana"
  client_id     = local.grafana_client_id
  client_secret = random_password.grafana_client_secret.result
  client_type   = "confidential"
  sub_mode      = "hashed_user_id"
  issuer_mode   = "per_provider"
  logout_method = "backchannel"

  authorization_flow = data.authentik_flow.provider_authorization_implicit_consent.id
  invalidation_flow  = data.authentik_flow.provider_invalidation.id

  # MUST be declared on a CREATED provider, see litellm.tofu. refresh_token is what Grafana's
  # use_refresh_token sends; without a refresh token Grafana logs the user out when the 5-minute
  # access token expires.
  grant_types = ["authorization_code", "refresh_token"]

  include_claims_in_id_token = true
  signing_key                = data.authentik_certificate_key_pair.self_signed.id
  # openid, email, profile (profile carries the `groups` claim role_attribute_path reads) plus
  # offline_access, without which Authentik issues no refresh token.
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.oauth2_default.ids,
    data.authentik_property_mapping_provider_scope.offline_access.ids,
  )

  access_code_validity    = "minutes=1"
  access_token_validity   = "minutes=5"
  refresh_token_validity  = "days=30"
  refresh_token_threshold = "seconds=0"

  # Grafana builds <root_url>/login/generic_oauth; root_url is GF_SERVER_ROOT_URL.
  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://grafana.${var.cluster_domain}/login/generic_oauth"
    }
  ]
}

resource "authentik_application" "grafana" {
  name               = "Grafana"
  slug               = "grafana"
  protocol_provider  = authentik_provider_oauth2.grafana.id
  meta_launch_url    = "https://grafana.${var.cluster_domain}"
  group              = ""
  open_in_new_tab    = false
  policy_engine_mode = "any"
}
