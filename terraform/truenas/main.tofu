# Provider wiring for the TrueNAS SCALE NAS (25.10 Goldeye) through the official
# iXsystems provider over the versioned JSON-RPC API.
#
# TRUENAS_API_KEY comes from 1Password through `vals` (secrets.vals.yaml) and
# the provider reads it from the environment.

terraform {
  required_version = "~> 1.12"

  required_providers {
    truenas = {
      source = "truenas/truenas"
      # Fully tested on 25.10 and 26.0. Re-plan after every TrueNAS upgrade.
      version = "~> 1.8"
    }
  }
}

provider "truenas" {
  endpoint = var.truenas_endpoint
}
