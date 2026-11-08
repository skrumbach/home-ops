# Hand-made local DNS records only. external-dns (network/unifi-dns, owner
# `main`, TXT prefix k8s.main.) owns every app record; never declare one here.
# Skill `unifi-network`.

resource "terrifi_dns_record" "nas_sklab_dev" {
  name        = "nas.sklab.dev"
  value       = "10.10.0.40"
  record_type = "A"
}

resource "terrifi_dns_record" "media_sklab_dev" {
  name        = "media.sklab.dev"
  value       = "10.10.0.32"
  record_type = "A"
  ttl         = 300
}

resource "terrifi_dns_record" "mgnt_sklab_local" {
  name        = "mgnt.sklab.local"
  value       = "10.10.0.31"
  record_type = "A"
  ttl         = 300
}

resource "terrifi_dns_record" "pbs_server_sklab_dev" {
  name        = "pbs.server.sklab.dev"
  value       = "10.10.0.48"
  record_type = "A"
}
