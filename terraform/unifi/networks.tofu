# LAN networks on the UDM, plus the guest network. WANs are in wans.tofu and the
# One-Click VPN in vpn.tofu; the NordVPN clients stay in the UI. k8s-01 is the untagged network on
# the Talos bonds; IoT (VLAN 3) and VPN_Network (VLAN 90) are tagged on them too.
# Changing any of these three cuts the cluster off, and deleting a network
# really deletes it, so the networks the cluster or the NAS ride carry
# prevent_destroy. Zone membership is declared on the zone (firewall.tofu),
# never with firewall_zone_id here: managing it from both sides loops.

resource "unifi_network" "unifi_managment" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.0.10.100"
    stop                = "10.0.10.254"
    time_offset_enabled = false
  }
  domain_name     = "unifi.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Unifi [Managment]"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.0.10.1/24"
  third_party_gateway = false
  vlan                = 10
}

resource "unifi_network" "k8s_01" {
  auto_scale = false
  dhcp_server = {
    boot = {
      enabled  = true
      filename = "netboot.xyz.efi"
      server   = "10.10.0.40"
    }
    conflict_checking = true
    enabled           = true
    gateway_enabled   = false
    leasetime         = "24h0m0s"
    ntp = {
      enabled = true
      servers = ["10.10.10.1"]
    }
    start               = "10.10.10.200"
    stop                = "10.10.10.254"
    tftp_server         = "10.10.0.40"
    time_offset_enabled = false
  }
  domain_name     = "sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "k8s-01"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.10.10.1/24"
  third_party_gateway = false
  vlan                = 1010

  lifecycle {
    prevent_destroy = true
  }
}

resource "unifi_network" "home_ops_pods" {
  auto_scale = true
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.42.0.46"
    stop                = "10.42.255.254"
    time_offset_enabled = false
  }
  enabled         = false
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = false
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Home-Ops-Pods"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "auto"
  subnet              = "10.42.0.1/16"
  third_party_gateway = false
  vlan                = 7
}

resource "unifi_network" "vpn_network" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "192.168.90.6"
    stop                = "192.168.90.254"
    time_offset_enabled = false
  }
  domain_name     = "vpn.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = false
  name                = "VPN_Network"
  network_isolation   = true
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "192.168.90.1/24"
  third_party_gateway = false
  vlan                = 90

  lifecycle {
    prevent_destroy = true
  }
}

resource "unifi_network" "server_private" {
  auto_scale = false
  dhcp_server = {
    boot = {
      enabled  = true
      filename = "netboot.xyz.efi"
      server   = "10.10.0.40"
    }
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.10.0.210"
    stop                = "10.10.0.254"
    time_offset_enabled = false
  }
  domain_name     = "server.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    interface_type = "none"
    pd = {
      auto_prefixid_enabled = true
    }
    ra = {
      enabled = true
    }
    setting_preference = "manual"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Server [Private]"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.10.0.1/24"
  third_party_gateway = false
  vlan                = 1000

  lifecycle {
    prevent_destroy = true
  }
}

resource "unifi_network" "home_default" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.0.0.11"
    stop                = "10.0.1.100"
    time_offset_enabled = false
  }
  domain_name     = "home.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = false
  multicast_dns       = true
  name                = "Home [Default]"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.0.0.1/23"
  third_party_gateway = false
}

resource "unifi_network" "iot_devices" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.40.0.16"
    stop                = "10.40.3.254"
    time_offset_enabled = false
  }
  domain_name     = "iot.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = false
  name                = "IoT [Devices]"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.40.0.1/22"
  third_party_gateway = false
  vlan                = 3

  lifecycle {
    prevent_destroy = true
  }
}

resource "unifi_network" "managment" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.10.4.16"
    stop                = "10.10.7.254"
    time_offset_enabled = false
  }
  domain_name     = "sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Managment"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.10.4.1/22"
  third_party_gateway = false
  vlan                = 5
}

resource "unifi_network" "home_ops_lb" {
  auto_scale = true
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.50.0.6"
    stop                = "10.50.0.254"
    time_offset_enabled = false
  }
  enabled         = false
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = false
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Home-Ops-LB"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "auto"
  subnet              = "10.50.0.1/24"
  third_party_gateway = false
  vlan                = 6
}

resource "unifi_network" "security_cams" {
  auto_scale = true
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.0.20.6"
    stop                = "10.0.20.254"
    time_offset_enabled = false
  }
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = false
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = false
  name                = "Security [Cams]"
  network_isolation   = false
  purpose             = "corporate"
  setting_preference  = "manual"
  subnet              = "10.0.20.1/24"
  third_party_gateway = false
  vlan                = 4
}

resource "unifi_network" "guest_access" {
  auto_scale = false
  dhcp_server = {
    conflict_checking   = true
    enabled             = true
    gateway_enabled     = false
    leasetime           = "24h0m0s"
    start               = "10.0.2.6"
    stop                = "10.0.2.254"
    time_offset_enabled = false
  }
  domain_name     = "guest.sklab.dev"
  enabled         = true
  gateway_type    = "default"
  igmp_snooping   = false
  internet_access = true
  ipv6 = {
    client_address_assignment = "slaac"
    interface_type            = "none"
    pd = {
      auto_prefixid_enabled = true
      start                 = "::2"
      stop                  = "::7d1"
    }
    ra = {
      enabled            = true
      preferred_lifetime = "4h0m0s"
      priority           = "high"
    }
    setting_preference = "auto"
  }
  lte_lan             = true
  multicast_dns       = true
  name                = "Guest [Access]"
  network_isolation   = false
  purpose             = "guest"
  setting_preference  = "manual"
  subnet              = "10.0.2.1/24"
  third_party_gateway = false
  vlan                = 2
}
