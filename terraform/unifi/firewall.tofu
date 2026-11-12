# Zone-based firewall. Built-in zones cannot be created or deleted, so they are
# referenced by controller ID. Built-in (predefined) policies are not managed.
# Nothing is published from the WAN: no port forwards, no IPv6 on any LAN, and
# Cloudflare Tunnel dials out. So the only External-sourced user policy is a
# block; an ALLOW from `external` needs a reviewed reason.
#
# Policy order is not managed: `index` is read-only in this provider. Every
# zone pair with more than one policy holds a single action (all ALLOW or all
# BLOCK), so the order changes nothing today. A pair that mixes ALLOW and
# BLOCK needs its order set in the UI. Updates are a full PUT from this
# config: check `matching_target` (WEB, APP, REGION) is modelled before
# adopting a policy.

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

resource "unifi_firewall_zone" "iot" {
  name        = "IoT"
  network_ids = [unifi_network.iot_devices.id]
}

resource "unifi_firewall_zone" "k8s_01" {
  name        = "k8s-01"
  network_ids = [unifi_network.k8s_01.id]

  lifecycle {
    prevent_destroy = true
  }
}

resource "unifi_firewall_zone" "vpn_network" {
  name        = "VPN_Network"
  network_ids = [unifi_network.vpn_network.id]
}

resource "unifi_firewall_zone" "server_private" {
  name        = "Server [Private]"
  network_ids = [unifi_network.server_private.id]
}

resource "unifi_firewall_policy" "internal_to_k8s_01" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Internal_To_K8s-01"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "vpn_network_gateway" {
  action                = "BLOCK"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.gateway
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "VPN_Network_Gateway"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.vpn_network.id
  }
}

resource "unifi_firewall_policy" "vpn_network_external" {
  action                = "BLOCK"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.external
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "VPN_Network_External"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.vpn_network.id
  }
}

resource "unifi_firewall_policy" "allow" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.external
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "allow"
  protocol   = "tcp_udp"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "vpn_allow_server" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "VPN - Allow Server"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
    time = {
      all_day = false
    }
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.vpn
  }
}

resource "unifi_firewall_policy" "block_traffic_to_itorrents_net" {
  action                = "BLOCK"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "WEB"
    port_matching_type = "ANY"
    web_domains        = ["itorrents.net"]
    zone_id            = local.builtin_zone_ids.external
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Block Traffic to itorrents.net"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
}

resource "unifi_firewall_policy" "allow_pods_to_external_gateway" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow-Pods-to-External-Gateway"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "k8s_loadbalancer" {
  action                = "ALLOW"
  connection_state_type = "RESPOND_ONLY"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "k8s-loadbalancer"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    ips                = ["10.50.0.0/24"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.vpn
  }
}

resource "unifi_firewall_policy" "all" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "all"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
}

resource "unifi_firewall_policy" "block_traffic_to_104_21_48_100" {
  action                = "BLOCK"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    ips                = ["104.21.48.100"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.external
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Block Traffic to 104.21.48.100"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
}

resource "unifi_firewall_policy" "k8s_to_internal_01" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "k8s_To_Internal-01"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
}

resource "unifi_firewall_policy" "k8s_allow_https_route" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    ips                = ["10.50.0.0/24"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "k8s_allow_https_route"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    ips                = ["10.42.0.0/16"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "server_private_to_k8s_01" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Server_Private_To_K8s-01"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
}

resource "unifi_firewall_policy" "allow_all" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow All"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
    time = {
      all_day = false
    }
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
}

resource "unifi_firewall_policy" "allow_all_traffic" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.iot.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow All Traffic"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
    time = {
      all_day = false
    }
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
}

resource "unifi_firewall_policy" "aviator_s_pc" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Aviator's PC"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "vpn_to_cluster" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "VPN-To-Cluster"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.vpn
  }
}

resource "unifi_firewall_policy" "allow_k8s" {
  action                = "ALLOW"
  connection_state_type = "RESPOND_ONLY"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow K8s"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    ips                = ["10.42.0.0/16"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.vpn
  }
}

resource "unifi_firewall_policy" "k8s_to_server_private_01" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.server_private.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "k8s_To_Server_Private-01"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
}

resource "unifi_firewall_policy" "block_traffic_from_104_21_48_100" {
  action                = "BLOCK"
  connection_state_type = "ALL"
  create_allow_respond  = false
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.k8s_01.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Block Traffic from 104.21.48.100"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    ips                = ["104.21.48.100"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.external
  }
}

resource "unifi_firewall_policy" "allow_all_2" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = unifi_firewall_zone.iot.id
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow All"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
    time = {
      all_day = false
    }
  }
  source = {
    matching_target    = "ANY"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

resource "unifi_firewall_policy" "allow_pods_to_internal_gateway" {
  action                = "ALLOW"
  connection_state_type = "ALL"
  create_allow_respond  = true
  destination = {
    ips                = ["10.50.0.0/24"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
  enabled    = true
  ip_version = "BOTH"
  name       = "Allow-Pods-to-Internal-Gateway"
  protocol   = "all"
  schedule = {
    mode           = "ALWAYS"
    repeat_on_days = []
  }
  source = {
    ips                = ["10.42.0.0/16"]
    matching_target    = "IP"
    port_matching_type = "ANY"
    zone_id            = local.builtin_zone_ids.internal
  }
}

# Address groups. Nothing in firewall.tofu references them.

resource "unifi_firewall_group" "home_ops_lb" {
  members = ["10.50.0.0/24"]
  name    = "Home-Ops-LB"
  type    = "address-group"
}

resource "unifi_firewall_group" "home_ops_pod_cidr" {
  members = ["10.42.0.0/16"]
  name    = "Home-Ops-PodCidr"
  type    = "address-group"
}
