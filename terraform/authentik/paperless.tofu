# Paperless-ngx single sign-on (django-allauth openid_connect). CREATED by this stack (no import block).
# Confidential client: client_id is a plain literal the Paperless ExternalSecret repeats; the secret is
# generated here and copied once into 1Password Homelab/paperless-oidc (field client-secret, never Git).
# Kubernetes side: kubernetes/apps/base/selfhosted/paperless-ngx/app/externalsecret.yaml.

locals {
  # Public identifier. Must match client_id in PAPERLESS_SOCIALACCOUNT_PROVIDERS.
  paperless_client_id = "paperless"
}

resource "random_password" "paperless_client_secret" {
  length  = 64
  special = false
  # Alphanumeric: it is embedded in the PAPERLESS_SOCIALACCOUNT_PROVIDERS JSON.
}

resource "authentik_provider_oauth2" "paperless" {
  name          = "Paperless-ngx"
  client_id     = local.paperless_client_id
  client_secret = random_password.paperless_client_secret.result
  client_type   = "confidential"
  sub_mode      = "hashed_user_id"
  issuer_mode   = "per_provider"
  logout_method = "backchannel"

  authorization_flow = data.authentik_flow.provider_authorization_implicit_consent.id
  invalidation_flow  = data.authentik_flow.provider_invalidation.id

  # MUST be declared on a CREATED provider, see litellm.tofu. allauth only uses the code once at
  # login and keeps its own Django session, so no refresh_token.
  grant_types = ["authorization_code"]

  include_claims_in_id_token = true
  signing_key                = data.authentik_certificate_key_pair.self_signed.id
  # openid, email, profile: allauth signs users up from email and preferred_username.
  property_mappings = data.authentik_property_mapping_provider_scope.oauth2_default.ids

  access_code_validity    = "minutes=1"
  access_token_validity   = "minutes=5"
  refresh_token_validity  = "days=30"
  refresh_token_threshold = "seconds=0"

  # allauth builds /accounts/oidc/<provider_id>/login/callback/; provider_id is "authentik" in
  # PAPERLESS_SOCIALACCOUNT_PROVIDERS. Change both together.
  allowed_redirect_uris = [
    {
      matching_mode     = "strict"
      redirect_uri_type = "authorization"
      url               = "https://docs.${var.cluster_domain}/accounts/oidc/authentik/login/callback/"
    }
  ]
}

resource "authentik_application" "paperless" {
  name               = "Paperless-ngx"
  slug               = "paperless"
  protocol_provider  = authentik_provider_oauth2.paperless.id
  meta_launch_url    = "https://docs.${var.cluster_domain}"
  group              = ""
  open_in_new_tab    = false
  policy_engine_mode = "any"
}
