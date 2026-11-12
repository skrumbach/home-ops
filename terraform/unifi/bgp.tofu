# BGP to the Cilium nodes (UDM ASN 64513, k8s ASN 64514). The FRR text lives
# in bgp.conf, the only git copy; Cilium's side is
# kubernetes/apps/base/kube-system/cilium/app/networking.yaml.
#
# The read-only role reads `config` back empty, so it is ignored: read-only
# plans stay clean, and bgp.conf is what a recreate uploads. A deliberate
# change means removing ignore_changes for one reviewed apply, and that apply
# re-uploads FRR and resets every Cilium BGP session (graceful restart 15s).
# Confirm the running config on the UDM with `vtysh` first.
resource "unifi_bgp" "home_ops" {
  enabled          = true
  description      = "home-ops"
  upload_file_name = "bgp.conf"
  config           = file("${path.module}/bgp.conf")

  lifecycle {
    ignore_changes = [config]
  }
}
