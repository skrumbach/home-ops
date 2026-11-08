# LAN networks on the UDM. WANs, the One-Click VPN server and the NordVPN
# clients are not managed here. k8s-01 is the untagged network on the Talos
# bonds; IoT (VLAN 3) and VPN_Network (VLAN 90) are tagged on them too.
# Changing any of these three cuts the cluster off. Skill `unifi-network`.

resource "terrifi_network" "home_default" {
  name         = "Home [Default]"
  purpose      = "corporate"
  subnet       = "10.0.0.1/23"
  dhcp_enabled = true
  dhcp_start   = "10.0.0.11"
  dhcp_stop    = "10.0.1.100"
}

resource "terrifi_network" "iot_devices" {
  name         = "IoT [Devices]"
  purpose      = "corporate"
  vlan_id      = 3
  subnet       = "10.40.0.1/22"
  dhcp_enabled = true
  dhcp_start   = "10.40.0.16"
  dhcp_stop    = "10.40.3.254"
}

resource "terrifi_network" "unifi_managment" {
  name         = "Unifi [Managment]"
  purpose      = "corporate"
  vlan_id      = 10
  subnet       = "10.0.10.1/24"
  dhcp_enabled = true
  dhcp_start   = "10.0.10.100"
  dhcp_stop    = "10.0.10.254"
}

resource "terrifi_network" "server_private" {
  name         = "Server [Private]"
  purpose      = "corporate"
  vlan_id      = 1000
  subnet       = "10.10.0.1/24"
  dhcp_enabled = true
  dhcp_start   = "10.10.0.210"
  dhcp_stop    = "10.10.0.254"
}

resource "terrifi_network" "security_cams" {
  name         = "Security [Cams]"
  purpose      = "corporate"
  vlan_id      = 4
  subnet       = "10.0.20.1/24"
  dhcp_enabled = true
  dhcp_start   = "10.0.20.6"
  dhcp_stop    = "10.0.20.254"
}

resource "terrifi_network" "k8s_01" {
  name         = "k8s-01"
  purpose      = "corporate"
  vlan_id      = 1010
  subnet       = "10.10.10.1/24"
  dhcp_enabled = true
  dhcp_start   = "10.10.10.200"
  dhcp_stop    = "10.10.10.254"
}

resource "terrifi_network" "managment" {
  name         = "Managment"
  purpose      = "corporate"
  vlan_id      = 5
  subnet       = "10.10.4.1/22"
  dhcp_enabled = true
  dhcp_start   = "10.10.4.16"
  dhcp_stop    = "10.10.7.254"
}

resource "terrifi_network" "vpn_network" {
  name         = "VPN_Network"
  purpose      = "corporate"
  vlan_id      = 90
  subnet       = "192.168.90.1/24"
  dhcp_enabled = true
  dhcp_start   = "192.168.90.6"
  dhcp_stop    = "192.168.90.254"
}

resource "terrifi_network" "home_ops_lb" {
  name         = "Home-Ops-LB"
  purpose      = "corporate"
  vlan_id      = 6
  subnet       = "10.50.0.1/24"
  dhcp_enabled = true
  dhcp_start   = "10.50.0.6"
  dhcp_stop    = "10.50.0.254"
}

resource "terrifi_network" "home_ops_pods" {
  name         = "Home-Ops-Pods"
  purpose      = "corporate"
  vlan_id      = 7
  subnet       = "10.42.0.1/16"
  dhcp_enabled = true
  dhcp_start   = "10.42.0.46"
  dhcp_stop    = "10.42.255.254"
}
