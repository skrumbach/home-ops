# Zone-based firewall. Built-in zones cannot be created or deleted, so they are
# referenced by controller ID. Policy order is not managed yet: new policies land
# where the controller puts them. Built-in (predefined) policies are not managed.
# Skill `unifi-network`.

locals {
  builtin_zone_ids = {
    dmz      = "1a4da4a3-48a8-4913-8331-a242195ec250"
    external = "ac40fe17-3454-4085-924e-25584b09948a"
    gateway  = "5832849b-a073-40bb-8fca-7bd7c9022761"
    hotspot  = "bf5e5f87-4394-4fb2-9867-32b5b19f6277"
    internal = "4ef9a66f-f4e1-4442-a51a-1e636516b20d"
    vpn      = "d43625d6-2373-490c-84b3-942adacb73c7"
  }
}

resource "terrifi_firewall_zone" "iot" {
  name        = "IoT"
  network_ids = [terrifi_network.iot_devices.id]
}

resource "terrifi_firewall_zone" "server_private" {
  name        = "Server [Private]"
  network_ids = [terrifi_network.server_private.id]
}

resource "terrifi_firewall_zone" "server_talos" {
  name = "Server [Talos]"
}

resource "terrifi_firewall_zone" "vpn" {
  name = "VPN"
}

resource "terrifi_firewall_zone" "vpn_network" {
  name        = "VPN_Network"
  network_ids = [terrifi_network.vpn_network.id]
}

resource "terrifi_firewall_zone" "k8s_01" {
  name        = "k8s-01"
  network_ids = [terrifi_network.k8s_01.id]
}

resource "terrifi_firewall_policy" "allow_all" {
  name                 = "Allow All"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.server_private.id
  }

  destination {
    zone_id = local.builtin_zone_ids.internal
  }
}

resource "terrifi_firewall_policy" "allow_all_traffic" {
  name   = "Allow All Traffic"
  action = "ALLOW"

  source {
    zone_id = terrifi_firewall_zone.server_private.id
  }

  destination {
    zone_id = terrifi_firewall_zone.iot.id
  }
}

resource "terrifi_firewall_policy" "allow_all_2" {
  name                 = "Allow All"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = terrifi_firewall_zone.iot.id
  }
}

resource "terrifi_firewall_policy" "aviator_s_pc" {
  name                 = "Aviator's PC"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = terrifi_firewall_zone.server_private.id
  }
}

resource "terrifi_firewall_policy" "vpn_allow_server" {
  name                 = "VPN - Allow Server"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.vpn
  }

  destination {
    zone_id = terrifi_firewall_zone.server_private.id
  }
}

resource "terrifi_firewall_policy" "pxe" {
  name                 = "PXE"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id            = terrifi_firewall_zone.server_private.id
    port_matching_type = "SPECIFIC"
    port               = 69
  }
}

resource "terrifi_firewall_policy" "aviator" {
  name                 = "Aviator"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id    = local.builtin_zone_ids.internal
    device_ids = ["04:d9:f5:81:13:44", "52:ac:cd:e9:38:2f", "0e:2b:e9:78:0f:71", "5c:9b:a6:5f:88:84"]
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "nas" {
  name                 = "NAS"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.server_private.id
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "vpn_allow" {
  name                 = "VPN Allow"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.vpn
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "nas_allow_all" {
  name                 = "NAS-Allow-ALL"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.server_talos.id
  }

  destination {
    zone_id = terrifi_firewall_zone.server_private.id
  }
}

resource "terrifi_firewall_policy" "allow_all_nas" {
  name                 = "Allow-All-Nas"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id    = local.builtin_zone_ids.internal
    device_ids = ["58:47:ca:78:c3:09", "58:47:ca:78:c8:9d", "58:47:ca:77:f4:41", "58:47:ca:78:c3:06", "58:47:ca:78:c3:07", "58:47:ca:78:c8:9a", "58:47:ca:78:c8:9b", "58:47:ca:77:f4:3e", "58:47:ca:77:f4:3f", "04:d9:f5:81:13:44", "3c:f0:11:3e:08:87", "f0:4e:a4:7b:e0:b3", "5c:9b:a6:5f:88:84"]
  }

  destination {
    zone_id = terrifi_firewall_zone.server_private.id
  }
}

resource "terrifi_firewall_policy" "allow_bgp" {
  name   = "Allow BGP"
  action = "ALLOW"

  source {
    zone_id = local.builtin_zone_ids.internal
    # The controller stores an empty list here; omitting it plans a write.
    ips = []
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "allow_bgp_2" {
  name        = "Allow BGP"
  description = "Allow BGP Traffic to the Gateway"
  action      = "ALLOW"
  protocol    = "tcp"

  source {
    zone_id = local.builtin_zone_ids.external
  }

  destination {
    zone_id            = local.builtin_zone_ids.gateway
    port_matching_type = "SPECIFIC"
    port               = 179
  }
}

resource "terrifi_firewall_policy" "allow_bgp_3" {
  name   = "Allow bgp"
  action = "BLOCK"

  source {
    zone_id = local.builtin_zone_ids.external
  }

  destination {
    zone_id            = terrifi_firewall_zone.server_talos.id
    port_matching_type = "SPECIFIC"
    port               = 179
  }
}

resource "terrifi_firewall_policy" "allow_all_3" {
  name                 = "allow all"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "allow_all_talos" {
  name                 = "allow All talos"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.server_talos.id
  }

  destination {
    zone_id = terrifi_firewall_zone.server_talos.id
  }
}

resource "terrifi_firewall_policy" "internal_to_k8s_01" {
  name                 = "Internal_To_K8s-01"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "server_private_to_k8s_01" {
  name                 = "Server_Private_To_K8s-01"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.server_private.id
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "k8s_to_internal_01" {
  name                 = "k8s_To_Internal-01"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }

  destination {
    zone_id = local.builtin_zone_ids.internal
  }
}

resource "terrifi_firewall_policy" "k8s_to_server_private_01" {
  name                 = "k8s_To_Server_Private-01"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }

  destination {
    zone_id = terrifi_firewall_zone.server_private.id
  }
}

resource "terrifi_firewall_policy" "allow_bgp_4" {
  name                 = "Allow bgp"
  action               = "ALLOW"
  logging              = true
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.external
  }

  destination {
    zone_id            = terrifi_firewall_zone.k8s_01.id
    port_matching_type = "SPECIFIC"
    port               = 179
  }
}

resource "terrifi_firewall_policy" "all" {
  name                 = "all"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "k8s_allow_https_route" {
  name                 = "k8s_allow_https_route"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
    ips     = ["10.42.0.0/16"]
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
    ips     = ["10.50.0.0/24"]
  }
}

resource "terrifi_firewall_policy" "allow_pods_to_internal_gateway" {
  name                 = "Allow-Pods-to-Internal-Gateway"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.internal
    ips     = ["10.42.0.0/16"]
  }

  destination {
    zone_id = local.builtin_zone_ids.internal
    ips     = ["10.50.0.0/24"]
  }
}

resource "terrifi_firewall_policy" "allow_pods_to_external_gateway" {
  name   = "Allow-Pods-to-External-Gateway"
  action = "ALLOW"

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "test" {
  name                 = "test"
  action               = "ALLOW"
  logging              = true
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.external
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "space_engineers" {
  name                 = "space-engineers"
  action               = "ALLOW"
  logging              = true
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.external
  }

  destination {
    zone_id              = local.builtin_zone_ids.internal
    port_matching_type   = "SPECIFIC"
    match_opposite_ports = true
  }
}

resource "terrifi_firewall_policy" "allow" {
  name     = "allow"
  action   = "ALLOW"
  protocol = "tcp_udp"

  source {
    zone_id = local.builtin_zone_ids.internal
  }

  destination {
    zone_id = local.builtin_zone_ids.external
  }
}

resource "terrifi_firewall_policy" "vpn_to_cluster" {
  name                 = "VPN-To-Cluster"
  action               = "ALLOW"
  create_allow_respond = true

  source {
    zone_id = local.builtin_zone_ids.vpn
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}

resource "terrifi_firewall_policy" "allow_k8s" {
  name                  = "Allow K8s"
  action                = "ALLOW"
  connection_state_type = "RESPOND_ONLY"

  source {
    zone_id = local.builtin_zone_ids.vpn
    ips     = ["10.42.0.0/16"]
  }

  destination {
    zone_id = local.builtin_zone_ids.internal
  }
}

resource "terrifi_firewall_policy" "k8s_loadbalancer" {
  name                  = "k8s-loadbalancer"
  action                = "ALLOW"
  connection_state_type = "RESPOND_ONLY"

  source {
    zone_id = local.builtin_zone_ids.vpn
    ips     = ["10.50.0.0/24"]
  }

  destination {
    zone_id = local.builtin_zone_ids.internal
  }
}

resource "terrifi_firewall_policy" "allow_iot" {
  name   = "Allow IOT"
  action = "ALLOW"

  source {
    zone_id = terrifi_firewall_zone.server_talos.id
  }

  destination {
    zone_id = terrifi_firewall_zone.iot.id
  }
}

resource "terrifi_firewall_policy" "vpn_network_external" {
  name   = "VPN_Network_External"
  action = "BLOCK"

  source {
    zone_id = terrifi_firewall_zone.vpn_network.id
  }

  destination {
    zone_id = local.builtin_zone_ids.external
  }
}

resource "terrifi_firewall_policy" "vpn_network_gateway" {
  name   = "VPN_Network_Gateway"
  action = "BLOCK"

  source {
    zone_id = terrifi_firewall_zone.vpn_network.id
  }

  destination {
    zone_id = local.builtin_zone_ids.gateway
  }
}

resource "terrifi_firewall_policy" "block_traffic_to_itorrents_net" {
  name   = "Block Traffic to itorrents.net"
  action = "BLOCK"

  source {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }

  destination {
    zone_id = local.builtin_zone_ids.external
  }
}

resource "terrifi_firewall_policy" "block_traffic_to_104_21_48_100" {
  name   = "Block Traffic to 104.21.48.100"
  action = "BLOCK"

  source {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }

  destination {
    zone_id = local.builtin_zone_ids.external
    ips     = ["104.21.48.100"]
  }
}

resource "terrifi_firewall_policy" "block_traffic_from_104_21_48_100" {
  name   = "Block Traffic from 104.21.48.100"
  action = "BLOCK"

  source {
    zone_id = local.builtin_zone_ids.external
    ips     = ["104.21.48.100"]
  }

  destination {
    zone_id = terrifi_firewall_zone.k8s_01.id
  }
}
