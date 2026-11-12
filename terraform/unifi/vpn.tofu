# The One-Click VPN WireGuard server. Its private key is not in this config:
# the read-only role cannot read it, and setting `private_key_wo` would rotate
# it and break every paired client. A recreate generates a new key, so clients
# re-pair. The NordVPN clients (2 WireGuard, 1 OpenVPN) stay in the UI: this
# provider models WireGuard only and their peer settings are vendor configs.

resource "unifi_vpn_server" "one_click_vpn" {
  dns = {
    enabled = false
  }
  enabled = true
  name    = "One-Click VPN"
  subnet  = "192.168.4.1/24"
  wan = {
    interface = "wan"
    ip        = "any"
  }
  wireguard = {
    ip_version = "v4"
    port       = 51820
  }
}
