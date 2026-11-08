# The two DHCP uplinks. Internet 1 is weighted, Internet 2 failover-only.
# A change here re-provisions the WAN and can drop internet for the whole
# house and the cluster (Cloudflare Tunnel, image pulls). Skill `unifi-network`.

resource "unifi_wan" "internet_1" {
  dhcpv6 = {
    pd = {
      size_auto = false
    }
    wan_delegation_type = "pd"
  }
  dns = {
    ipv6 = {
      preference = "auto"
    }
    preference = "auto"
  }
  dslite = {
    remote_host_auto = false
  }
  enabled = true
  igmp_proxy = {
    downstream = "none"
    upstream   = false
  }
  interface_mtu_enabled   = false
  ipv6_setting_preference = "manual"
  load_balance = {
    failover_priority = 1
    type              = "weighted"
    weight            = 50
  }
  mac_override_enabled = false
  name                 = "Internet 1"
  networkgroup         = "WAN"
  provider_capabilities = {
    download_kilobits_per_second = 617000
    upload_kilobits_per_second   = 626000
  }
  report_wan_event   = false
  setting_preference = "auto"
  type               = "dhcp"
  type_v6            = "dhcpv6"
  vlan = {
    enabled = false
  }
}

resource "unifi_wan" "internet_2" {
  dhcpv6 = {
    pd = {
      size_auto = false
    }
    wan_delegation_type = "none"
  }
  dns = {
    ipv6 = {
      preference = "auto"
    }
    preference = "auto"
  }
  dslite = {
    remote_host_auto = false
  }
  enabled = true
  igmp_proxy = {
    downstream = "none"
    upstream   = false
  }
  interface_mtu_enabled   = false
  ipv6_setting_preference = "manual"
  load_balance = {
    failover_priority = 2
    type              = "failover-only"
    weight            = 50
  }
  mac_override_enabled = false
  name                 = "Internet 2"
  networkgroup         = "WAN2"
  provider_capabilities = {
    download_kilobits_per_second = 617000
    upload_kilobits_per_second   = 626000
  }
  report_wan_event   = false
  setting_preference = "auto"
  type               = "dhcp"
  type_v6            = "disabled"
  vlan = {
    enabled = false
  }
}
