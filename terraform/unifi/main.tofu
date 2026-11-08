# Provider wiring for the UDM Pro SE (Network app 11.x).
#
# Credentials never live in this tree. UNIFI_USERNAME and UNIFI_PASSWORD come
# from 1Password through `vals` (secrets.vals.yaml) and the provider reads them
# from the environment. Skill `unifi-network`.

terraform {
  required_version = "~> 1.12"

  required_providers {
    terrifi = {
      source = "alexklibisz/terrifi"
      # 0.x: every minor can change a schema. Renovate opens the PR, nothing
      # automerges terraform-provider updates. Re-plan before merging a bump.
      version = "~> 0.12.0"
    }
  }
}

provider "terrifi" {
  api_url = var.unifi_url
  # The UDM serves its own self-signed certificate.
  allow_insecure = true
  # One run reads every zone and policy; caching keeps it to one list call each.
  response_caching = true
}
