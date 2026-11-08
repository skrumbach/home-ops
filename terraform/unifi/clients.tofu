# Client groups and fixed-IP reservations only; the other ~90 known clients stay
# out of Git. Network 11 stores no network_id on a reservation but the provider
# requires one, so it is derived from the subnet and ignore_changes.
# The MS01 entries are the Talos nodes and their vPro ports: keep them stable.
# Skill `unifi-network`.

resource "terrifi_client_group" "ms_01" {
  name = "MS-01"
}

resource "terrifi_client_group" "talos_1" {
  name = "Talos-1"
}

resource "terrifi_client_group" "k8s_01" {
  name = "k8s-01"
}

resource "terrifi_client_group" "ms01_02" {
  name = "MS01-02"
}

resource "terrifi_client_group" "minisforum_ms01" {
  name = "MinisForum-MS01"
}

resource "terrifi_client_group" "ms01_01" {
  name = "MS01-01"
}

resource "terrifi_client_group" "ms01_03" {
  name = "MS01-03"
}

resource "terrifi_client_device" "desktop_pc_sascha" {
  mac              = "04:d9:f5:81:13:44"
  name             = "Desktop-PC [Sascha]"
  fixed_ip         = "10.0.1.49"
  local_dns_record = "win.sklab.dev"
  device_type_id   = 2663
  network_id       = terrifi_network.home_default.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "voron_3d_printer" {
  mac              = "48:8f:4c:61:94:25"
  name             = "Voron 3D Printer"
  fixed_ip         = "10.0.1.120"
  local_dns_record = "voron.sklab.dev"
  network_id       = terrifi_network.home_default.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "hubitat" {
  mac              = "34:e1:d1:81:ea:4e"
  name             = "Hubitat"
  fixed_ip         = "10.40.0.40"
  local_dns_record = "hub.iot.sklab.dev"
  network_id       = terrifi_network.iot_devices.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "hp_printer" {
  mac              = "f0:4e:a4:7b:e0:b3"
  name             = "HP-Printer"
  fixed_ip         = "10.0.1.5"
  local_dns_record = "printer.sklab.dev"
  network_id       = terrifi_network.home_default.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "true_nas_enp7s0" {
  mac            = "d0:50:99:c3:c9:4e"
  name           = "True Nas [enp7s0]"
  fixed_ip       = "10.10.0.41"
  device_type_id = 4995
  network_id     = terrifi_network.server_private.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_03_talos_1_2" {
  mac              = "58:47:ca:77:f4:3e"
  name             = "MS01-03 [Talos 1/2]"
  note             = "bond0 / enp2s0f0np0"
  fixed_ip         = "10.10.10.13"
  local_dns_record = "talos-3.sklab.dev"
  device_type_id   = 5587
  network_id       = terrifi_network.k8s_01.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "_1c_f6_4c_60_b4_42" {
  mac              = "1c:f6:4c:60:b4:42"
  fixed_ip         = "10.0.0.150"
  local_dns_record = "mac-mini.sklab.dev"
  network_id       = terrifi_network.home_default.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "_40_91_51_2a_df_47" {
  mac              = "40:91:51:2a:df:47"
  fixed_ip         = "10.40.2.101"
  local_dns_record = "zigbee.sklab.dev"
  network_id       = terrifi_network.iot_devices.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_02_vpro" {
  mac              = "58:47:ca:78:c8:9d"
  name             = "MS01-02 [VPro]"
  fixed_ip         = "10.10.4.32"
  local_dns_record = "ms01-02-mgt.sklab.dev"
  client_group_ids = [terrifi_client_group.k8s_01.id, terrifi_client_group.ms01_02.id, terrifi_client_group.minisforum_ms01.id]
  device_type_id   = 5587
  network_id       = terrifi_network.managment.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_03_vpro" {
  mac              = "58:47:ca:77:f4:41"
  name             = "MS01-03 [VPro]"
  fixed_ip         = "10.10.4.33"
  local_dns_record = "ms01-03-mgt.sklab.dev"
  client_group_ids = [terrifi_client_group.k8s_01.id, terrifi_client_group.minisforum_ms01.id, terrifi_client_group.ms01_03.id]
  device_type_id   = 5587
  network_id       = terrifi_network.managment.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_01_vpro" {
  mac              = "58:47:ca:78:c3:09"
  name             = "MS01-01 [VPro]"
  fixed_ip         = "10.10.4.31"
  local_dns_record = "ms01-01-mgt.sklab.dev"
  client_group_ids = [terrifi_client_group.k8s_01.id, terrifi_client_group.minisforum_ms01.id, terrifi_client_group.ms01_01.id]
  device_type_id   = 5587
  network_id       = terrifi_network.managment.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_01_talos_1_2" {
  mac              = "58:47:ca:78:c3:06"
  name             = "MS01-01 [Talos 1/2]"
  note             = "bond0 / enp2s0f0np0"
  fixed_ip         = "10.10.10.11"
  local_dns_record = "talos-1.sklab.dev"
  client_group_ids = [terrifi_client_group.k8s_01.id, terrifi_client_group.minisforum_ms01.id, terrifi_client_group.ms01_01.id]
  device_type_id   = 5587
  network_id       = terrifi_network.k8s_01.id

  lifecycle {
    ignore_changes = [network_id]
  }
}

resource "terrifi_client_device" "ms01_02_talos_1_2" {
  mac              = "58:47:ca:78:c8:9a"
  name             = "MS01-02 [Talos 1/2]"
  note             = "bond0 / enp2s0f0np0"
  fixed_ip         = "10.10.10.12"
  local_dns_record = "talos-2.sklab.dev"
  client_group_ids = [terrifi_client_group.k8s_01.id, terrifi_client_group.ms01_02.id, terrifi_client_group.minisforum_ms01.id]
  device_type_id   = 5587
  network_id       = terrifi_network.k8s_01.id

  lifecycle {
    ignore_changes = [network_id]
  }
}
