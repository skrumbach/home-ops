# State lives in Cloudflare R2, outside the cluster, next to the UniFi stack: the
# NAS must stay manageable when the cluster (and its Ceph RGW) is not.
# One bucket for every stack outside Flux that wants off-cluster state; this
# stack owns the `truenas/` key. Credentials and the account endpoint come from
# 1Password through vals (AWS_*), so the account ID stays out of Git.
# Skill `truenas-nas`.
terraform {
  backend "s3" {
    bucket = "home-ops-tfstate"
    key    = "truenas/terraform.tfstate"
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
