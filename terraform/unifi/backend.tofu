# State lives in Cloudflare R2, outside the cluster: a UniFi mistake that cuts
# the network must not also lock out the state needed to roll it back.
# One bucket for every stack outside Flux that wants off-cluster state; this
# stack owns the `unifi/` key. Credentials and the account endpoint come from
# 1Password through vals (AWS_*), so the account ID stays out of Git.
# Skill `unifi-network`.
terraform {
  backend "s3" {
    bucket = "home-ops-tfstate"
    key    = "unifi/terraform.tfstate"
    region = "auto"

    # R2 supports the conditional writes S3-native locking needs.
    use_lockfile = true

    # R2 is not AWS: no STS, no IMDS, no account-id lookup, no AWS checksums.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }

  # Client-side encryption before anything leaves the machine. `enforced`
  # refuses to read or write plaintext state or plans. Losing the passphrase
  # loses the state; every object is adopted, so imports.tofu rebuilds it.
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
