# Switch port overrides, one resource per port. Each write reads the switch and
# merges this port's override by index, so other ports are untouched; removing
# a resource only stops managing the port (its settings stay). Any change
# re-provisions the switch.
#
# Pro Max 48 port 49 (SFP+ 1, LACP with 50) is the uplink to the Aggregation
# switch. Never change it without a console on the switch.
#
# Not here yet: the Talos bonds (Aggregation 5+6, 7+8, 9+10), Aggregation 11
# and 15+16, and the disabled Pro Max 48 ports 34, 36, 38. USW Flex has no
# overrides. Skill `unifi-network`.

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
