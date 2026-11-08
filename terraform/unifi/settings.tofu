# Site-wide settings: country, DPI, global switch (jumbo frames, RSTP, DHCP
# snooping), IGMP snooping, IPS/IDS and its suppressions, management (auto
# upgrade, SSH), NTP, RADIUS ports, syslog and USG timeouts. One singleton per
# site. A change re-provisions every device it touches; jumbo frames carry the
# MTU 9000 Talos bonds. Skill `unifi-network`.

resource "unifi_setting" "site" {
  connectivity = {
    enabled          = false
    mlo_mesh_enabled = false
    uplink_type      = "gateway"
  }
  country = {
    code = 840
  }
  doh = {
    custom_servers = []
    server_names   = []
    state          = "off"
  }
  dpi = {
    enabled                = true
    fingerprinting_enabled = true
  }
  global_switch = {
    acl_device_isolation   = []
    dhcp_snoop             = true
    dot1x_portctrl_enabled = false
    jumboframe_enabled     = true
    stp_version            = "rstp"
  }
  igmp_snooping = {
    enabled     = true
    network_ids = [unifi_network.home_default.id, unifi_network.guest_access.id, unifi_network.iot_devices.id, unifi_network.unifi_managment.id, unifi_network.server_private.id, unifi_network.security_cams.id]
  }
  ips = {
    advanced_filtering_preference           = "manual"
    content_filtering_blocking_page_enabled = true
    enabled_categories                      = ["emerging-activex", "emerging-attackresponse", "botcc", "ciarmy", "compromised", "emerging-dns", "emerging-dos", "dshield", "emerging-exploit", "emerging-ftp", "emerging-imap", "emerging-malware", "emerging-mobile", "emerging-netbios", "emerging-p2p", "emerging-pop3", "emerging-rpc", "emerging-scan", "emerging-shellcode", "emerging-smtp", "emerging-snmp", "emerging-sql", "emerging-telnet", "emerging-tftp", "tor", "emerging-useragent", "emerging-voip", "emerging-webclient", "emerging-webserver", "emerging-webapps", "emerging-worm", "emerging-misc", "dark-web-blocker-list", "malicious-hosts"]
    enabled_networks                        = [unifi_network.home_default.id, unifi_network.guest_access.id, unifi_network.iot_devices.id, unifi_network.unifi_managment.id, unifi_network.server_private.id, unifi_network.k8s_01.id, unifi_network.security_cams.id, unifi_network.managment.id]
    honeypot                                = []
    honeypot_enabled                        = false
    ips_mode                                = "ips"
    memory_optimized                        = true
    restrict_torrents                       = false
    suppression = {
      alerts = [
        {
          category  = "emerging-useragent"
          gid       = 1
          signature = "ET USER_AGENTS Node XMLHTTP User-Agent"
          tracking = [
            {
              direction = "both"
              mode      = "ip"
              value     = "10.0.0.232"
            },
            {
              direction = "both"
              mode      = "ip"
              value     = "10.50.0.54"
            },
          ]
          type = "track"
        },
      ]
      whitelist = [
        {
          direction = "both"
          mode      = "ip"
          value     = "10.0.0.232"
        },
      ]
    }
  }
  lcm = {
    brightness   = 80
    enabled      = true
    idle_timeout = 300
    sync         = true
    touch_event  = true
  }
  mgmt = {
    advanced_feature_enabled = true
    auto_upgrade = {
      enabled = true
      hour    = 3
    }
    debug_tools_enabled    = false
    direct_connect_enabled = false
    ssh = {
      auth_password_enabled = false
      enabled               = false
    }
    unifi_idp_enabled = true
    wifiman_enabled   = true
  }
  network_optimization = {
    enabled = false
  }
  ntp = {
    ntp_server_1       = "0.ubnt.pool.ntp.org"
    ntp_server_2       = "1.ubnt.pool.ntp.org"
    ntp_server_3       = "2.ubnt.pool.ntp.org"
    ntp_server_4       = "3.ubnt.pool.ntp.org"
    setting_preference = "auto"
  }
  radius = {
    accounting_enabled      = false
    acct_port               = 1813
    auth_port               = 1812
    interim_update_interval = "1h0m0s"
  }
  syslog = {
    debug            = false
    enabled          = true
    log_all_contents = true
    netconsole = {
      enabled = false
    }
    this_controller = {
      enabled        = true
      encrypted_only = true
    }
  }
  usg = {
    broadcast_ping = false
    dns_verification = {
      domain               = "ui.com"
      primary_dns_server   = "1.1.1.1"
      secondary_dns_server = "8.8.8.8"
      setting_preference   = "auto"
    }
    ftp_module = true
    geo_ip_filtering = {
      block             = "block"
      enabled           = false
      traffic_direction = "both"
    }
    gre_module   = true
    h323_module  = true
    icmp_timeout = "30s"
    mss_clamp    = "auto"
    offload = {
      accounting  = true
      l2_blocking = true
      sch         = true
    }
    other_timeout     = "10m0s"
    pptp_module       = true
    receive_redirects = false
    send_redirects    = true
    sip_module        = false
    syn_cookies       = true
    tcp = {
      close_timeout       = "10s"
      close_wait_timeout  = "1m0s"
      established_timeout = "2h4m0s"
      fin_wait_timeout    = "2m0s"
      last_ack_timeout    = "30s"
      syn_recv_timeout    = "1m0s"
      syn_sent_timeout    = "2m0s"
      time_wait_timeout   = "2m0s"
    }
    tftp_module                = true
    timeout_setting_preference = "auto"
    udp = {
      other_timeout  = "30s"
      stream_timeout = "3m0s"
    }
    unbind_wan_monitors = false
    upnp = {
      enabled         = false
      nat_pmp_enabled = false
      secure_mode     = false
    }
  }
}
