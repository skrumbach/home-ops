# Routes. The traffic route sends VPN_Network (VLAN 90, tagged on the Talos
# bonds) out through the NordVpn-Public client with a kill switch: the
# cluster's VPN egress depends on it.
#
# `space-engineers` routes the whole LoadBalancer pool 10.50.0.0/24 to talos-1.
# Cilium's BGP /32s are more specific and win, so it only catches pool IPs no
# node announces. It is a leftover; removing it is its own change.
# Skill `unifi-network`.

resource "unifi_traffic_route" "nordvpn_public" {
  description         = "NordVpn-Public"
  enabled             = true
  kill_switch_enabled = true
  network_id          = local.unmanaged_ids.nordvpn_public_client
  source = {
    networks = [
      {
        id = unifi_network.vpn_network.id
      },
    ]
  }
}

resource "unifi_static_route" "space_engineers" {
  distance = 1
  enabled  = true
  gateway = {
    device = "60:22:32:7b:b8:45"
    type   = "default"
  }
  name     = "space-engineers"
  network  = "10.50.0.0/24"
  next_hop = "10.10.10.11"
  type     = "nexthop-route"
}
