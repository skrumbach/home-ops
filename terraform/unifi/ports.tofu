# Switch port overrides, one resource per port. Each write reads the switch and
# merges this port's override by index, so other ports are untouched; removing
# a resource only stops managing the port (its settings stay). Any change
# re-provisions the switch.
#
# Pro Max 48 port 49 (SFP+ 1, LACP with 50) is the uplink to the Aggregation
# switch. Never change it without a console on the switch.
#
# The Talos bonds (Aggregation 5+6, 7+8, 9+10) are at the end of this file.
# USW Flex has no overrides. Skill `unifi-network`.

resource "unifi_device_port" "usw_pro_max_48_port_49" {
  aggregate_members      = [49, 50]
  autoneg                = true
  device_mac             = "9c:05:d6:af:79:45"
  forward                = "all"
  index                  = 49
  name                   = "SFP+ 1"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "aggregate"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "manual"
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_31" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 31
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 31"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "auto"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_28" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "customize"
  index     = 28
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 28"
  native_networkconf_id  = unifi_network.iot_devices.id
  op_mode                = "switch"
  poe_mode               = "auto"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_4" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 4
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 4"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_37" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 37
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 37"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_35" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 35
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 35"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_39" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 39
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 39"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "auto"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_1" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "customize"
  index     = 1
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 1"
  native_networkconf_id  = unifi_network.server_private.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_aggregation_port_13" {
  aggregate_members = [13, 14]
  autoneg           = false
  device_mac        = "28:70:4e:5b:41:2b"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  forward                = "customize"
  full_duplex            = true
  index                  = 13
  name                   = "SFP+ 13"
  native_networkconf_id  = unifi_network.server_private.id
  op_mode                = "aggregate"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  speed              = 10000
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_2" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "customize"
  index     = 2
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 2"
  native_networkconf_id  = unifi_network.server_private.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_15" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "customize"
  index     = 15
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 15"
  native_networkconf_id  = unifi_network.iot_devices.id
  op_mode                = "switch"
  poe_mode               = "auto"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "auto"
}

resource "unifi_device_port" "usw_pro_aggregation_port_3" {
  aggregate_members      = [3, 4]
  autoneg                = true
  device_mac             = "28:70:4e:5b:41:2b"
  forward                = "all"
  index                  = 3
  name                   = "SFP+ 3"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "aggregate"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "manual"
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_3" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 3
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 3"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "auto"
}

resource "unifi_device_port" "usw_pro_max_48_port_33" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "all"
  index     = 33
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 33"
  native_networkconf_id  = unifi_network.home_default.id
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "auto"
}

# Talos bond: LACP 5+6 to talos-1. k8s-01 untagged; `custom` tags every
# network NOT in excluded_networkconf_ids, which today leaves IoT [Devices]
# (VLAN 3) and VPN_Network (VLAN 90). A new network is tagged here too unless
# it is added to the list. Any change re-provisions the Aggregation switch and
# drops this node's bond. Skill `unifi-network`.
resource "unifi_device_port" "usw_pro_aggregation_port_5" {
  aggregate_members        = [5, 6]
  autoneg                  = true
  device_mac               = "28:70:4e:5b:41:2b"
  excluded_networkconf_ids = [unifi_network.home_ops_pods.id, unifi_network.guest_access.id, unifi_network.unifi_managment.id, unifi_network.managment.id, unifi_network.home_ops_lb.id, unifi_network.home_default.id, unifi_network.security_cams.id, unifi_network.server_private.id]
  forward                  = "customize"
  index                    = 5
  name                     = "SFP+ 5"
  native_networkconf_id    = unifi_network.k8s_01.id
  op_mode                  = "aggregate"
  port_keepalive_enabled   = false
  port_security = {
    enabled = false
  }
  setting_preference = "manual"
  tagged_vlan_mgmt   = "custom"
}

# Talos bond: LACP 7+8 to talos-2. k8s-01 untagged; `custom` tags every
# network NOT in excluded_networkconf_ids, which today leaves IoT [Devices]
# (VLAN 3) and VPN_Network (VLAN 90). A new network is tagged here too unless
# it is added to the list. Any change re-provisions the Aggregation switch and
# drops this node's bond. Skill `unifi-network`.
resource "unifi_device_port" "usw_pro_aggregation_port_7" {
  aggregate_members        = [7, 8]
  autoneg                  = true
  device_mac               = "28:70:4e:5b:41:2b"
  excluded_networkconf_ids = [unifi_network.home_ops_pods.id, unifi_network.guest_access.id, unifi_network.unifi_managment.id, unifi_network.managment.id, unifi_network.home_ops_lb.id, unifi_network.home_default.id, unifi_network.security_cams.id, unifi_network.server_private.id]
  forward                  = "customize"
  index                    = 7
  name                     = "SFP+ 7"
  native_networkconf_id    = unifi_network.k8s_01.id
  op_mode                  = "aggregate"
  port_keepalive_enabled   = false
  port_security = {
    enabled = false
  }
  setting_preference = "manual"
  tagged_vlan_mgmt   = "custom"
}

# Talos bond: LACP 9+10 to talos-3. k8s-01 untagged; `custom` tags every
# network NOT in excluded_networkconf_ids, which today leaves IoT [Devices]
# (VLAN 3) and VPN_Network (VLAN 90). A new network is tagged here too unless
# it is added to the list. Any change re-provisions the Aggregation switch and
# drops this node's bond. Skill `unifi-network`.
resource "unifi_device_port" "usw_pro_aggregation_port_9" {
  aggregate_members        = [9, 10]
  autoneg                  = false
  device_mac               = "28:70:4e:5b:41:2b"
  excluded_networkconf_ids = [unifi_network.home_ops_pods.id, unifi_network.guest_access.id, unifi_network.unifi_managment.id, unifi_network.managment.id, unifi_network.home_ops_lb.id, unifi_network.home_default.id, unifi_network.security_cams.id, unifi_network.server_private.id]
  forward                  = "customize"
  full_duplex              = true
  index                    = 9
  name                     = "SFP+ 9"
  native_networkconf_id    = unifi_network.k8s_01.id
  op_mode                  = "aggregate"
  port_keepalive_enabled   = false
  port_security = {
    enabled = false
  }
  setting_preference = "manual"
  speed              = 10000
  tagged_vlan_mgmt   = "custom"
}

# Disabled LAG.
resource "unifi_device_port" "usw_pro_aggregation_port_11" {
  aggregate_members      = [11, 12]
  autoneg                = false
  device_mac             = "28:70:4e:5b:41:2b"
  forward                = "disabled"
  full_duplex            = true
  index                  = 11
  name                   = "SFP+ 11"
  op_mode                = "aggregate"
  port_keepalive_enabled = false
  port_security = {
    enabled = true
  }
  setting_preference = "manual"
  speed              = 10000
  tagged_vlan_mgmt   = "block_all"
}

# LAG with no native network.
resource "unifi_device_port" "usw_pro_aggregation_port_15" {
  aggregate_members = [15, 16]
  autoneg           = false
  device_mac        = "28:70:4e:5b:41:2b"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  forward                = "customize"
  full_duplex            = true
  index                  = 15
  name                   = "SFP+ 15"
  op_mode                = "aggregate"
  port_keepalive_enabled = false
  port_security = {
    enabled = false
  }
  setting_preference = "auto"
  speed              = 10000
  tagged_vlan_mgmt   = "auto"
}

# Disabled.
resource "unifi_device_port" "usw_pro_max_48_port_34" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "disabled"
  index     = 34
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 34"
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = true
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "block_all"
}

# Disabled.
resource "unifi_device_port" "usw_pro_max_48_port_36" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  dot1x = {
    ctrl         = "force_authorized"
    idle_timeout = "5m0s"
  }
  egress_rate_limit = {
    enabled = false
  }
  forward   = "disabled"
  index     = 36
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 36"
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = true
  }
  setting_preference = "auto"
  stp_edge_state     = "auto"
  stp_port_mode      = true
  tagged_vlan_mgmt   = "block_all"
}

# Disabled.
resource "unifi_device_port" "usw_pro_max_48_port_38" {
  autoneg    = true
  device_mac = "9c:05:d6:af:79:45"
  egress_rate_limit = {
    enabled = false
  }
  forward   = "disabled"
  index     = 38
  isolation = false
  lldpmed = {
    enabled = true
  }
  name                   = "Port 38"
  op_mode                = "switch"
  poe_mode               = "off"
  port_keepalive_enabled = false
  port_security = {
    enabled = true
  }
  setting_preference = "auto"
  stormctrl = {
    bcast = {
      enabled = false
      rate    = 100
    }
    mcast = {
      enabled = false
      rate    = 100
    }
    ucast = {
      enabled = false
      rate    = 100
    }
  }
  stp_port_mode    = true
  tagged_vlan_mgmt = "block_all"
}
