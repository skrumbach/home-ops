# SSIDs. The read-only role cannot read passphrases, so the API never reports
# them: 1Password owns the value and ignore_changes keeps a plan from rewriting
# it (a passphrase write reprovisions every AP). Skill `unifi-network`.

resource "terrifi_wlan" "u7_secure" {
  name            = "U7-Secure"
  passphrase      = var.wlan_passphrase_secure
  network_id      = terrifi_network.security_cams.id
  wpa3_support    = true
  wpa3_transition = true

  lifecycle {
    ignore_changes = [passphrase]
  }
}

resource "terrifi_wlan" "u7_guest" {
  name        = "U7-Guest"
  network_id  = "49a124e1-8f03-4591-a1c7-f9423f99e901" # unmanaged: Guest [Access]
  security    = "open"
  application = "hotspot"
}

resource "terrifi_wlan" "u7_iot" {
  name        = "U7-IOT"
  passphrase  = var.wlan_passphrase_iot
  network_id  = terrifi_network.iot_devices.id
  wifi_band   = "2g"
  application = "iot"

  lifecycle {
    ignore_changes = [passphrase]
  }
}

resource "terrifi_wlan" "u7_home" {
  name            = "U7-Home"
  passphrase      = var.wlan_passphrase_home
  network_id      = terrifi_network.home_default.id
  wpa3_support    = true
  wpa3_transition = true

  lifecycle {
    ignore_changes = [passphrase]
  }
}
