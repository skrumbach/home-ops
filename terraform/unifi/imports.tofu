# Adoption of the live controller objects. Inert once an object is in state;
# kept so a lost state reattaches instead of creating duplicates. Networks and
# WLANs import as `name=<name>` (Network 11 IDs are UUIDs and the provider's ID
# path expects 24-hex); ports as `<switch mac>/<index>`; clients by MAC.
# Skill `unifi-network`.

import {
  to = unifi_network.home_default
  id = "name=Home [Default]"
}

import {
  to = unifi_network.iot_devices
  id = "name=IoT [Devices]"
}

import {
  to = unifi_network.unifi_managment
  id = "name=Unifi [Managment]"
}

import {
  to = unifi_network.server_private
  id = "name=Server [Private]"
}

import {
  to = unifi_network.security_cams
  id = "name=Security [Cams]"
}

import {
  to = unifi_network.k8s_01
  id = "name=k8s-01"
}

import {
  to = unifi_network.managment
  id = "name=Managment"
}

import {
  to = unifi_network.vpn_network
  id = "name=VPN_Network"
}

import {
  to = unifi_network.home_ops_lb
  id = "name=Home-Ops-LB"
}

import {
  to = unifi_network.home_ops_pods
  id = "name=Home-Ops-Pods"
}

import {
  to = unifi_wlan.u7_secure
  id = "name=U7-Secure"
}

import {
  to = unifi_wlan.u7_guest
  id = "name=U7-Guest"
}

import {
  to = unifi_wlan.u7_iot
  id = "name=U7-IOT"
}

import {
  to = unifi_wlan.u7_home
  id = "name=U7-Home"
}

import {
  to = unifi_firewall_zone.iot
  id = "19c5c467-16e2-453b-9e0c-de6a01b0a713"
}

import {
  to = unifi_firewall_zone.server_private
  id = "0993a852-a466-46f2-a438-a3b17c08ce41"
}

import {
  to = unifi_firewall_zone.vpn_network
  id = "627ac57b-b670-4588-8dc1-a80a8d1427cb"
}

import {
  to = unifi_firewall_zone.k8s_01
  id = "99e31282-ef3a-41c9-b516-8226ab2c65b1"
}

import {
  to = unifi_firewall_policy.allow_all
  id = "c0ddb526-3af5-4067-85b2-6b7e75c02156"
}

import {
  to = unifi_firewall_policy.allow_all_traffic
  id = "c489dc29-8a55-467d-baad-d8073046f551"
}

import {
  to = unifi_firewall_policy.allow_all_2
  id = "ec2ee2d3-a3a8-4c05-b2aa-709b70bfc312"
}

import {
  to = unifi_firewall_policy.aviator_s_pc
  id = "5f27a007-ec2a-42f8-9048-81a4bece6e33"
}

import {
  to = unifi_firewall_policy.vpn_allow_server
  id = "88e71652-7f95-4457-ae6e-a58351709455"
}

import {
  to = unifi_firewall_policy.internal_to_k8s_01
  id = "6ca55429-dd8d-493f-850e-8df7f635953e"
}

import {
  to = unifi_firewall_policy.server_private_to_k8s_01
  id = "dc469243-de93-4688-9f6d-5c143aaa3b66"
}

import {
  to = unifi_firewall_policy.k8s_to_internal_01
  id = "19416219-82d7-4ee2-b1fe-476018e48226"
}

import {
  to = unifi_firewall_policy.k8s_to_server_private_01
  id = "33492907-a1a8-442c-bd42-000fb527ea0f"
}

import {
  to = unifi_firewall_policy.all
  id = "9cfdf807-0a9c-45c8-9de7-fb4cf395fac2"
}

import {
  to = unifi_firewall_policy.k8s_allow_https_route
  id = "fa63aefd-7a63-4793-93a3-58fd483c46fd"
}

import {
  to = unifi_firewall_policy.allow_pods_to_internal_gateway
  id = "9ad7d2f7-bf9f-452a-9390-97523f592621"
}

import {
  to = unifi_firewall_policy.allow_pods_to_external_gateway
  id = "076ca585-966c-4e26-a04b-87f9ee0de182"
}

import {
  to = unifi_firewall_policy.allow
  id = "05e07205-310a-49b7-988f-7be8531b2060"
}

import {
  to = unifi_firewall_policy.vpn_to_cluster
  id = "7f1b6689-040d-4726-bec2-fa5b41a54399"
}

import {
  to = unifi_firewall_policy.allow_k8s
  id = "322db0e5-0872-40d5-a3bb-8262a77fe574"
}

import {
  to = unifi_firewall_policy.k8s_loadbalancer
  id = "f1259377-6ee6-416e-92a4-117cb06490fd"
}

import {
  to = unifi_firewall_policy.vpn_network_external
  id = "9445e628-38e0-4873-a31a-35b724de1feb"
}

import {
  to = unifi_firewall_policy.vpn_network_gateway
  id = "246efc91-f9d3-49bc-b46a-967cce3abb24"
}

import {
  to = unifi_firewall_policy.block_traffic_to_itorrents_net
  id = "cae6fb63-fc4d-4c8f-a7b9-92f363062596"
}

import {
  to = unifi_firewall_policy.block_traffic_to_104_21_48_100
  id = "142592f8-5621-4d85-9ae5-4e925f7c058a"
}

import {
  to = unifi_firewall_policy.block_traffic_from_104_21_48_100
  id = "d6b6cbf3-e54d-460c-9607-ef3fcae6513f"
}

import {
  to = unifi_client.desktop_pc_sascha
  id = "04:d9:f5:81:13:44"
}

import {
  to = unifi_client.voron_3d_printer
  id = "48:8f:4c:61:94:25"
}

import {
  to = unifi_client.hubitat
  id = "34:e1:d1:81:ea:4e"
}

import {
  to = unifi_client.hp_printer
  id = "f0:4e:a4:7b:e0:b3"
}

import {
  to = unifi_client.true_nas_enp7s0
  id = "d0:50:99:c3:c9:4e"
}

import {
  to = unifi_client.ms01_03_talos_1_2
  id = "58:47:ca:77:f4:3e"
}

import {
  to = unifi_client._1c_f6_4c_60_b4_42
  id = "1c:f6:4c:60:b4:42"
}

import {
  to = unifi_client._40_91_51_2a_df_47
  id = "40:91:51:2a:df:47"
}

import {
  to = unifi_client.ms01_02_vpro
  id = "58:47:ca:78:c8:9d"
}

import {
  to = unifi_client.ms01_03_vpro
  id = "58:47:ca:77:f4:41"
}

import {
  to = unifi_client.ms01_01_vpro
  id = "58:47:ca:78:c3:09"
}

import {
  to = unifi_client.ms01_01_talos_1_2
  id = "58:47:ca:78:c3:06"
}

import {
  to = unifi_client.ms01_02_talos_1_2
  id = "58:47:ca:78:c8:9a"
}

import {
  to = unifi_dns_record.nas_sklab_dev
  id = "3ffb2e79-f664-4b79-aeff-45c8d1f43eda"
}

import {
  to = unifi_dns_record.media_sklab_dev
  id = "dc88e02a-0791-410d-9462-c7a424a2b8ae"
}

import {
  to = unifi_dns_record.mgnt_sklab_local
  id = "924d196c-8460-48a8-afdb-075acad2ac3a"
}

import {
  to = unifi_dns_record.pbs_server_sklab_dev
  id = "270125bd-024d-4a0d-b67a-717c330d973c"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_1
  id = "9c:05:d6:af:79:45/1"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_2
  id = "9c:05:d6:af:79:45/2"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_3
  id = "9c:05:d6:af:79:45/3"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_4
  id = "9c:05:d6:af:79:45/4"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_15
  id = "9c:05:d6:af:79:45/15"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_28
  id = "9c:05:d6:af:79:45/28"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_31
  id = "9c:05:d6:af:79:45/31"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_33
  id = "9c:05:d6:af:79:45/33"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_35
  id = "9c:05:d6:af:79:45/35"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_37
  id = "9c:05:d6:af:79:45/37"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_39
  id = "9c:05:d6:af:79:45/39"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_49
  id = "9c:05:d6:af:79:45/49"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_3
  id = "28:70:4e:5b:41:2b/3"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_13
  id = "28:70:4e:5b:41:2b/13"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_5
  id = "28:70:4e:5b:41:2b/5"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_7
  id = "28:70:4e:5b:41:2b/7"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_9
  id = "28:70:4e:5b:41:2b/9"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_11
  id = "28:70:4e:5b:41:2b/11"
}

import {
  to = unifi_device_port.usw_pro_aggregation_port_15
  id = "28:70:4e:5b:41:2b/15"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_34
  id = "9c:05:d6:af:79:45/34"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_36
  id = "9c:05:d6:af:79:45/36"
}

import {
  to = unifi_device_port.usw_pro_max_48_port_38
  id = "9c:05:d6:af:79:45/38"
}

import {
  to = unifi_bgp.home_ops
  id = "default" # the site: BGP is a per-site singleton
}
