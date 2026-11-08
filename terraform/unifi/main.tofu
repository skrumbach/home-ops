# Provider wiring for the UDM Pro SE (Network app 11.x).
#
# Credentials never live in this tree. UNIFI_USERNAME and UNIFI_PASSWORD come
# from 1Password through `vals` (secrets.vals.yaml) and both providers read
# them from the environment. UNIFI_API_KEY must stay unset: the provider
# prefers it, and the 1Password field of that name is a cloud key that
# returns 401 on the console. Skill `unifi-network`.

terraform {
  required_version = "~> 1.12"

  required_providers {
    unifi = {
      source = "ubiquiti-community/unifi"
      # 0.x: every minor can change a schema. Renovate opens a PR; no automerge.
      version = "0.65.0"
    }
    # Only for the removed blocks in migration.tofu; drop it with that file.
    terrifi = {
      source  = "alexklibisz/terrifi"
      version = "~> 0.12.0"
    }
  }
}

provider "unifi" {
  api_url        = var.unifi_url
  allow_insecure = true # the UDM serves a self-signed certificate
}

provider "terrifi" {
  api_url        = var.unifi_url
  allow_insecure = true
}

# Controller objects referenced here but managed elsewhere (UI defaults and the
# unmanaged guest network).
locals {
  unmanaged_ids = {
    guest_network          = "49a124e1-8f03-4591-a1c7-f9423f99e901" # Guest [Access]
    ap_group_all           = "8b483984-4bfa-4c92-a26c-a98843865d0e" # All APs
    user_group_default     = "63465ffb-c97c-4cb5-8a08-7885791a2cb0" # Default
    radius_profile_default = "2c2eb642-ffee-414b-bb7a-8f5d60436479" # Default
  }
}
