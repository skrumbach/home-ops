# SSIDs. The read-only role cannot read passphrases, so the API never reports
# them. 1Password owns the value and it goes in as `passphrase_wo`: write-only,
# never in state, sent only when the WLAN is created or `passphrase_wo_version`
# changes. Adding or bumping that version rewrites the passphrase and
# reprovisions every AP. Never use `passphrase`, which is stored in state.
# Skill `unifi-network`.

resource "unifi_wlan" "u7_guest" {
  ap_group = {
    ids  = [local.unmanaged_ids.ap_group_all]
    mode = "all"
  }
  bss_transition       = true
  dtim_6e              = 3
  dtim_mode            = "default"
  dtim_na              = 3
  dtim_ng              = 1
  enabled              = true
  enhanced_iot         = false
  fast_roaming_enabled = false
  hide_ssid            = false
  hotspot2conf_enabled = false
  iapp_enabled         = true
  is_guest             = true
  l2_isolation         = true
  mac_filter = {
    enabled = false
    policy  = "allow"
  }
  minimum_data_rate_2g_kbps      = 1000
  minimum_data_rate_5g_kbps      = 6000
  minrate_setting_preference     = "auto"
  mlo_enabled                    = false
  multicast_enhance              = true
  name                           = "U7-Guest"
  nas_identifier_type            = "bssid"
  network_id                     = unifi_network.guest_access.id
  no2ghz_oui                     = true
  pmf_mode                       = "disabled"
  private_preshared_keys_enabled = false
  proxy_arp                      = false
  radius = {
    mac_auth_enabled = false
    profile_id       = local.unmanaged_ids.radius_profile_default
  }
  roaming_assistant_6e = {
    enabled = true
    rssi    = -88
  }
  roaming_assistant_na = {
    enabled = false
    rssi    = -75
  }
  security      = "open"
  uapsd         = false
  user_group_id = local.unmanaged_ids.user_group_default
  vlan_enabled  = false
  wlan_band     = "both"
  wlan_bands    = ["2g", "5g", "6g"]
  wpa = {
    enc  = "ccmp"
    mode = "wpa2"
  }
  wpa3 = {
    enhanced_192 = false
    fast_roaming = false
    support      = false
    transition   = false
  }
}

resource "unifi_wlan" "u7_home" {
  ap_group = {
    ids  = [local.unmanaged_ids.ap_group_all]
    mode = "all"
  }
  bss_transition       = true
  dtim_6e              = 3
  dtim_mode            = "default"
  dtim_na              = 3
  dtim_ng              = 1
  enabled              = true
  enhanced_iot         = false
  fast_roaming_enabled = false
  group_rekey          = 0
  hide_ssid            = false
  hotspot2conf_enabled = false
  iapp_enabled         = true
  is_guest             = false
  l2_isolation         = false
  mac_filter = {
    enabled = false
    policy  = "allow"
  }
  minimum_data_rate_2g_kbps      = 1000
  minimum_data_rate_5g_kbps      = 6000
  minrate_setting_preference     = "auto"
  mlo_enabled                    = false
  multicast_enhance              = true
  name                           = "U7-Home"
  nas_identifier_type            = "bssid"
  network_id                     = unifi_network.home_default.id
  no2ghz_oui                     = true
  passphrase_wo                  = var.wlan_passphrase_home
  pmf_mode                       = "optional"
  private_preshared_keys_enabled = false
  proxy_arp                      = false
  radius = {
    mac_auth_enabled = false
  }
  roaming_assistant_6e = {
    enabled = true
    rssi    = -88
  }
  roaming_assistant_na = {
    enabled = false
    rssi    = -75
  }
  security      = "wpapsk"
  uapsd         = false
  user_group_id = local.unmanaged_ids.user_group_default
  vlan_enabled  = false
  wlan_band     = "both"
  wlan_bands    = ["2g", "5g", "6g"]
  wpa = {
    enc  = "ccmp"
    mode = "wpa2"
  }
  wpa3 = {
    enhanced_192 = false
    fast_roaming = false
    support      = true
    transition   = true
  }
}

resource "unifi_wlan" "u7_iot" {
  ap_group = {
    ids  = [local.unmanaged_ids.ap_group_all]
    mode = "all"
  }
  bss_transition       = false
  dtim_6e              = 3
  dtim_mode            = "default"
  dtim_na              = 3
  dtim_ng              = 1
  enabled              = true
  enhanced_iot         = true
  fast_roaming_enabled = false
  group_rekey          = 0
  hide_ssid            = false
  hotspot2conf_enabled = false
  iapp_enabled         = true
  is_guest             = false
  l2_isolation         = true
  mac_filter = {
    enabled = false
    policy  = "allow"
  }
  minimum_data_rate_2g_kbps      = 1000
  minimum_data_rate_5g_kbps      = 6000
  minrate_setting_preference     = "auto"
  mlo_enabled                    = false
  multicast_enhance              = true
  name                           = "U7-IOT"
  nas_identifier_type            = "bssid"
  network_id                     = unifi_network.iot_devices.id
  no2ghz_oui                     = false
  passphrase_wo                  = var.wlan_passphrase_iot
  pmf_mode                       = "disabled"
  private_preshared_keys_enabled = false
  proxy_arp                      = false
  radius = {
    mac_auth_enabled = false
  }
  roaming_assistant_6e = {
    enabled = false
  }
  roaming_assistant_na = {
    enabled = false
  }
  security      = "wpapsk"
  uapsd         = false
  user_group_id = local.unmanaged_ids.user_group_default
  vlan_enabled  = false
  wlan_band     = "2g"
  wlan_bands    = ["2g"]
  wpa = {
    enc  = "ccmp"
    mode = "wpa2"
  }
  wpa3 = {
    enhanced_192 = false
    fast_roaming = false
    support      = false
    transition   = false
  }
}

resource "unifi_wlan" "u7_secure" {
  ap_group = {
    ids  = [local.unmanaged_ids.ap_group_all]
    mode = "all"
  }
  bss_transition       = false
  dtim_6e              = 3
  dtim_mode            = "default"
  dtim_na              = 3
  dtim_ng              = 1
  enabled              = true
  enhanced_iot         = false
  fast_roaming_enabled = false
  group_rekey          = 0
  hide_ssid            = false
  hotspot2conf_enabled = false
  iapp_enabled         = true
  is_guest             = false
  l2_isolation         = false
  mac_filter = {
    enabled = false
    policy  = "allow"
  }
  minimum_data_rate_2g_kbps      = 1000
  minimum_data_rate_5g_kbps      = 6000
  minrate_setting_preference     = "auto"
  mlo_enabled                    = false
  multicast_enhance              = false
  name                           = "U7-Secure"
  nas_identifier_type            = "bssid"
  network_id                     = unifi_network.security_cams.id
  no2ghz_oui                     = false
  passphrase_wo                  = var.wlan_passphrase_secure
  pmf_mode                       = "optional"
  private_preshared_keys_enabled = false
  proxy_arp                      = false
  radius = {
    mac_auth_enabled = false
  }
  roaming_assistant_6e = {
    enabled = true
    rssi    = -88
  }
  roaming_assistant_na = {
    enabled = false
    rssi    = -75
  }
  security      = "wpapsk"
  uapsd         = false
  user_group_id = local.unmanaged_ids.user_group_default
  vlan_enabled  = false
  wlan_band     = "both"
  wlan_bands    = ["2g", "5g", "6g"]
  wpa = {
    enc  = "ccmp"
    mode = "wpa2"
  }
  wpa3 = {
    enhanced_192 = false
    fast_roaming = false
    support      = true
    transition   = true
  }
}
