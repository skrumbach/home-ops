# Hand-made local DNS records only. external-dns (network/unifi-dns, owner
# `main`, TXT prefix k8s.main.) owns every app record; never declare one here.
# The NAS is the only host outside the cluster that needs a LAN name.
# Skill `unifi-network`.

resource "unifi_dns_record" "nas_sklab_dev" {
  enabled     = true
  name        = "nas.sklab.dev"
  record_type = "A"
  value       = "10.10.0.40"
}
