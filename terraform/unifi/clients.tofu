# Fixed-IP reservations only; the other ~90 known clients stay out of Git.
# Client groups are not a resource in this provider: `groups` names them and
# they live in the UI. The MS01 entries are the Talos nodes and their vPro
# ports: keep them stable. Destroying a unifi_client makes the controller
# forget the client (skip_forget_on_destroy = false).

resource "unifi_client" "ms01_01_vpro" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.4.31"
  groups                 = ["k8s-01", "MinisForum-MS01", "MS01-01"]
  local_dns_record       = "ms01-01-mgt.sklab.dev"
  mac                    = "58:47:ca:78:c3:09"
  name                   = "MS01-01 [VPro]"
  skip_forget_on_destroy = false
}

resource "unifi_client" "ms01_01_talos_1_2" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.10.11"
  groups                 = ["k8s-01", "MinisForum-MS01", "MS01-01"]
  local_dns_record       = "talos-1.sklab.dev"
  mac                    = "58:47:ca:78:c3:06"
  name                   = "MS01-01 [Talos 1/2]"
  note                   = "bond0 / enp2s0f0np0"
  skip_forget_on_destroy = false
}

resource "unifi_client" "ms01_03_talos_1_2" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.10.13"
  local_dns_record       = "talos-3.sklab.dev"
  mac                    = "58:47:ca:77:f4:3e"
  name                   = "MS01-03 [Talos 1/2]"
  note                   = "bond0 / enp2s0f0np0"
  skip_forget_on_destroy = false
}

resource "unifi_client" "hp_printer" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.0.1.5"
  local_dns_record       = "printer.sklab.dev"
  mac                    = "f0:4e:a4:7b:e0:b3"
  name                   = "HP-Printer"
  skip_forget_on_destroy = false
}

resource "unifi_client" "desktop_pc_sascha" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.0.1.49"
  local_dns_record       = "win.sklab.dev"
  mac                    = "04:d9:f5:81:13:44"
  name                   = "Desktop-PC [Sascha]"
  skip_forget_on_destroy = false
}

resource "unifi_client" "_1c_f6_4c_60_b4_42" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.0.0.150"
  local_dns_record       = "mac-mini.sklab.dev"
  mac                    = "1c:f6:4c:60:b4:42"
  skip_forget_on_destroy = false
}

resource "unifi_client" "ms01_02_talos_1_2" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.10.12"
  groups                 = ["k8s-01", "MS01-02", "MinisForum-MS01"]
  local_dns_record       = "talos-2.sklab.dev"
  mac                    = "58:47:ca:78:c8:9a"
  name                   = "MS01-02 [Talos 1/2]"
  note                   = "bond0 / enp2s0f0np0"
  skip_forget_on_destroy = false
}

resource "unifi_client" "ms01_03_vpro" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.4.33"
  groups                 = ["k8s-01", "MinisForum-MS01", "MS01-03"]
  local_dns_record       = "ms01-03-mgt.sklab.dev"
  mac                    = "58:47:ca:77:f4:41"
  name                   = "MS01-03 [VPro]"
  skip_forget_on_destroy = false
}

resource "unifi_client" "true_nas_enp7s0" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.0.41"
  mac                    = "d0:50:99:c3:c9:4e"
  name                   = "True Nas [enp7s0]"
  skip_forget_on_destroy = false
}

resource "unifi_client" "voron_3d_printer" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.0.1.120"
  local_dns_record       = "voron.sklab.dev"
  mac                    = "48:8f:4c:61:94:25"
  name                   = "Voron 3D Printer"
  skip_forget_on_destroy = false
}

resource "unifi_client" "hubitat" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.40.0.40"
  local_dns_record       = "hub.iot.sklab.dev"
  mac                    = "34:e1:d1:81:ea:4e"
  name                   = "Hubitat"
  skip_forget_on_destroy = false
}

resource "unifi_client" "_40_91_51_2a_df_47" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.40.2.101"
  local_dns_record       = "zigbee.sklab.dev"
  mac                    = "40:91:51:2a:df:47"
  skip_forget_on_destroy = false
}

resource "unifi_client" "ms01_02_vpro" {
  allow_existing         = true
  blocked                = false
  fixed_ip               = "10.10.4.32"
  groups                 = ["k8s-01", "MS01-02", "MinisForum-MS01"]
  local_dns_record       = "ms01-02-mgt.sklab.dev"
  mac                    = "58:47:ca:78:c8:9d"
  name                   = "MS01-02 [VPro]"
  skip_forget_on_destroy = false
}
