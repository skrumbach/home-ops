# Hand-made local DNS records only. external-dns (network/unifi-dns, owner
# `main`, TXT prefix k8s.main.) owns every app record; never declare one here.
# Skill `unifi-network`.

resource "unifi_dns_record" "media_sklab_dev" {
  enabled     = true
  name        = "media.sklab.dev"
  record_type = "A"
  ttl         = "5m0s"
  value       = "10.10.0.32"
}

resource "unifi_dns_record" "pbs_server_sklab_dev" {
  enabled     = true
  name        = "pbs.server.sklab.dev"
  record_type = "A"
  value       = "10.10.0.48"
}

resource "unifi_dns_record" "nas_sklab_dev" {
  enabled     = true
  name        = "nas.sklab.dev"
  record_type = "A"
  value       = "10.10.0.40"
}

resource "unifi_dns_record" "mgnt_sklab_local" {
  enabled     = true
  name        = "mgnt.sklab.local"
  record_type = "A"
  ttl         = "5m0s"
  value       = "10.10.0.31"
}
