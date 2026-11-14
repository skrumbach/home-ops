# Routes. The traffic route sends VPN_Network (VLAN 90, tagged on the Talos
# bonds) out through the NordVpn-Public client with a kill switch: the
# cluster's VPN egress depends on it.
#
# No static route covers the LoadBalancer pool 10.50.0.0/24: Cilium announces
# each LB IP as a BGP /32. A pool-wide route to a node loops for every IP no
# node announces (UDM -> node -> UDM), which the removed `space-engineers`
# route did.

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
