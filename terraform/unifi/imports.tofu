# Adoption of the live controller objects. Inert once an object is in state;
# kept so a lost state reattaches instead of creating duplicates.
# Generated with `terrifi generate-imports <type> --format=json`. Skill `unifi-network`.

import {
  to = terrifi_network.home_default
  id = "887ee482-6a42-42ed-84f3-d94838e85fce"
}

import {
  to = terrifi_network.iot_devices
  id = "4595eb29-5647-4ab6-a3af-99959bcf40a6"
}

import {
  to = terrifi_network.unifi_managment
  id = "57ed74f9-a7d0-41c7-9b5d-eabb33df9dd6"
}

import {
  to = terrifi_network.server_private
  id = "e4976ce2-7ce5-46f8-882e-bb305efe7b95"
}

import {
  to = terrifi_network.security_cams
  id = "dd5478e6-1033-4436-a0f4-d9e14f23f0a7"
}

import {
  to = terrifi_network.k8s_01
  id = "f2190ad7-28a8-4fef-bce1-b0a53c24e819"
}

import {
  to = terrifi_network.managment
  id = "672d3714-aa12-4ceb-9630-a561cfd72ecc"
}

import {
  to = terrifi_network.vpn_network
  id = "4be53126-def8-4489-bf11-d48beaea7d94"
}

import {
  to = terrifi_network.home_ops_lb
  id = "6a7c7755-d797-4809-b163-ee99bbae53dd"
}

import {
  to = terrifi_network.home_ops_pods
  id = "41a5623a-9757-4c1b-b40d-24462905c3a0"
}

import {
  to = terrifi_wlan.u7_secure
  id = "85c90035-9efe-40e1-baec-be387f75ccb1"
}

import {
  to = terrifi_wlan.u7_guest
  id = "693f47db-528e-47ec-9c9b-24505293961c"
}

import {
  to = terrifi_wlan.u7_iot
  id = "8145c28f-ef14-4c40-814e-306c7781d36a"
}

import {
  to = terrifi_wlan.u7_home
  id = "7568e7f1-c96e-49f3-9ba8-f88c767c8f04"
}

import {
  to = terrifi_firewall_zone.iot
  id = "19c5c467-16e2-453b-9e0c-de6a01b0a713"
}

import {
  to = terrifi_firewall_zone.server_private
  id = "0993a852-a466-46f2-a438-a3b17c08ce41"
}

import {
  to = terrifi_firewall_zone.server_talos
  id = "58669e45-e29e-48ce-a699-7a05dca7ac82"
}

import {
  to = terrifi_firewall_zone.vpn
  id = "f1c29eb8-1b2f-4068-a8d9-2bb46c9df3ef"
}

import {
  to = terrifi_firewall_zone.vpn_network
  id = "627ac57b-b670-4588-8dc1-a80a8d1427cb"
}

import {
  to = terrifi_firewall_zone.k8s_01
  id = "99e31282-ef3a-41c9-b516-8226ab2c65b1"
}

import {
  to = terrifi_firewall_policy.allow_all
  id = "c0ddb526-3af5-4067-85b2-6b7e75c02156"
}

import {
  to = terrifi_firewall_policy.allow_all_traffic
  id = "c489dc29-8a55-467d-baad-d8073046f551"
}

import {
  to = terrifi_firewall_policy.allow_all_2
  id = "ec2ee2d3-a3a8-4c05-b2aa-709b70bfc312"
}

import {
  to = terrifi_firewall_policy.aviator_s_pc
  id = "5f27a007-ec2a-42f8-9048-81a4bece6e33"
}

import {
  to = terrifi_firewall_policy.vpn_allow_server
  id = "88e71652-7f95-4457-ae6e-a58351709455"
}

import {
  to = terrifi_firewall_policy.pxe
  id = "0746563e-2919-4b70-a12a-7a74f8f6880b"
}

import {
  to = terrifi_firewall_policy.aviator
  id = "a4524ddd-76cf-40be-aa06-7841bcc0a07c"
}

import {
  to = terrifi_firewall_policy.nas
  id = "16d5450c-f651-4c89-8596-1524470f5503"
}

import {
  to = terrifi_firewall_policy.vpn_allow
  id = "7da1aa26-b732-422a-b029-6affa7cba446"
}

import {
  to = terrifi_firewall_policy.nas_allow_all
  id = "df1a22de-6f5f-4704-9771-5c4f933376ff"
}

import {
  to = terrifi_firewall_policy.allow_all_nas
  id = "51755811-3e41-407d-95aa-48b01b037cc5"
}

import {
  to = terrifi_firewall_policy.allow_bgp
  id = "188ebe23-4ff7-4403-b314-d66b590a9c9f"
}

import {
  to = terrifi_firewall_policy.allow_bgp_2
  id = "ef858d94-14a9-4c55-8b88-4dc6b0c993b7"
}

import {
  to = terrifi_firewall_policy.allow_bgp_3
  id = "1b8abf65-580c-4726-843b-5f8e4532a38d"
}

import {
  to = terrifi_firewall_policy.allow_all_3
  id = "201756c1-1c33-424b-bd1f-a1491e401af6"
}

import {
  to = terrifi_firewall_policy.allow_all_talos
  id = "8ac52bd5-e585-456a-bc2e-873c74a0ebae"
}

import {
  to = terrifi_firewall_policy.internal_to_k8s_01
  id = "6ca55429-dd8d-493f-850e-8df7f635953e"
}

import {
  to = terrifi_firewall_policy.server_private_to_k8s_01
  id = "dc469243-de93-4688-9f6d-5c143aaa3b66"
}

import {
  to = terrifi_firewall_policy.k8s_to_internal_01
  id = "19416219-82d7-4ee2-b1fe-476018e48226"
}

import {
  to = terrifi_firewall_policy.k8s_to_server_private_01
  id = "33492907-a1a8-442c-bd42-000fb527ea0f"
}

import {
  to = terrifi_firewall_policy.allow_bgp_4
  id = "4443a63f-79e6-46bc-9868-ada75e570aa9"
}

import {
  to = terrifi_firewall_policy.all
  id = "9cfdf807-0a9c-45c8-9de7-fb4cf395fac2"
}

import {
  to = terrifi_firewall_policy.k8s_allow_https_route
  id = "fa63aefd-7a63-4793-93a3-58fd483c46fd"
}

import {
  to = terrifi_firewall_policy.allow_pods_to_internal_gateway
  id = "9ad7d2f7-bf9f-452a-9390-97523f592621"
}

import {
  to = terrifi_firewall_policy.allow_pods_to_external_gateway
  id = "076ca585-966c-4e26-a04b-87f9ee0de182"
}

import {
  to = terrifi_firewall_policy.test
  id = "0fef9229-c84a-44a8-91b4-3ab4ef7114f5"
}

import {
  to = terrifi_firewall_policy.space_engineers
  id = "74fe42de-f607-4a36-a236-aa10367a9c0b"
}

import {
  to = terrifi_firewall_policy.allow
  id = "05e07205-310a-49b7-988f-7be8531b2060"
}

import {
  to = terrifi_firewall_policy.vpn_to_cluster
  id = "7f1b6689-040d-4726-bec2-fa5b41a54399"
}

import {
  to = terrifi_firewall_policy.allow_k8s
  id = "322db0e5-0872-40d5-a3bb-8262a77fe574"
}

import {
  to = terrifi_firewall_policy.k8s_loadbalancer
  id = "f1259377-6ee6-416e-92a4-117cb06490fd"
}

import {
  to = terrifi_firewall_policy.allow_iot
  id = "111bf134-b3ed-4a87-90c7-afa01dc5f8bc"
}

import {
  to = terrifi_firewall_policy.vpn_network_external
  id = "9445e628-38e0-4873-a31a-35b724de1feb"
}

import {
  to = terrifi_firewall_policy.vpn_network_gateway
  id = "246efc91-f9d3-49bc-b46a-967cce3abb24"
}

import {
  to = terrifi_firewall_policy.block_traffic_to_itorrents_net
  id = "cae6fb63-fc4d-4c8f-a7b9-92f363062596"
}

import {
  to = terrifi_firewall_policy.block_traffic_to_104_21_48_100
  id = "142592f8-5621-4d85-9ae5-4e925f7c058a"
}

import {
  to = terrifi_firewall_policy.block_traffic_from_104_21_48_100
  id = "d6b6cbf3-e54d-460c-9607-ef3fcae6513f"
}

import {
  to = terrifi_client_group.ms_01
  id = "a486f090-6341-449f-b126-ca81b5e7291f"
}

import {
  to = terrifi_client_group.talos_1
  id = "027d509e-af9c-4013-a266-39cf9d2edff5"
}

import {
  to = terrifi_client_group.k8s_01
  id = "564ecd69-56cc-4ad2-9958-fc90d1ca4c9a"
}

import {
  to = terrifi_client_group.ms01_02
  id = "fff0892f-f21c-4cc8-9d8a-f1cecce2ffa7"
}

import {
  to = terrifi_client_group.minisforum_ms01
  id = "590961a7-b90b-45a5-ae74-201ce85c6dfc"
}

import {
  to = terrifi_client_group.ms01_01
  id = "989f76e7-d55e-47be-bf39-6631ec4cb247"
}

import {
  to = terrifi_client_group.ms01_03
  id = "59635ba9-1106-43a7-8355-ed9470910ae9"
}

import {
  to = terrifi_client_device.desktop_pc_sascha
  id = "4969a7ae-7050-4527-bddc-2892de298f39"
}

import {
  to = terrifi_client_device.voron_3d_printer
  id = "2fb98b96-9c59-4c63-b773-1aa2adda279c"
}

import {
  to = terrifi_client_device.hubitat
  id = "12e9072c-344b-4ea0-a7c4-2e678170c606"
}

import {
  to = terrifi_client_device.hp_printer
  id = "cf25ef63-3807-42f7-98ab-89cad01fcc16"
}

import {
  to = terrifi_client_device.true_nas_enp7s0
  id = "8bc46674-6218-499a-a55e-dc5719ec9390"
}

import {
  to = terrifi_client_device.ms01_03_talos_1_2
  id = "f218581e-0e4c-43d4-b44b-da99f5c7a82c"
}

import {
  to = terrifi_client_device._1c_f6_4c_60_b4_42
  id = "733013ce-9dba-4ef9-87d0-fd9c72ffd35a"
}

import {
  to = terrifi_client_device._40_91_51_2a_df_47
  id = "e030d40f-2b13-4160-bfcb-b36f8efd13f2"
}

import {
  to = terrifi_client_device.ms01_02_vpro
  id = "85c8b339-5c19-48c6-b8c4-bef7de5a3c70"
}

import {
  to = terrifi_client_device.ms01_03_vpro
  id = "50de4777-55af-4ad0-9fc9-502e07d5978f"
}

import {
  to = terrifi_client_device.ms01_01_vpro
  id = "df4576f1-87eb-4332-b825-c4e733b229f3"
}

import {
  to = terrifi_client_device.ms01_01_talos_1_2
  id = "cfbf44b0-a1e1-4e8e-91e0-e672892d366b"
}

import {
  to = terrifi_client_device.ms01_02_talos_1_2
  id = "bf53cf37-69dc-4233-b002-e38dc09284ba"
}

import {
  to = terrifi_dns_record.nas_sklab_dev
  id = "3ffb2e79-f664-4b79-aeff-45c8d1f43eda"
}

import {
  to = terrifi_dns_record.media_sklab_dev
  id = "dc88e02a-0791-410d-9462-c7a424a2b8ae"
}

import {
  to = terrifi_dns_record.mgnt_sklab_local
  id = "924d196c-8460-48a8-afdb-075acad2ac3a"
}

import {
  to = terrifi_dns_record.pbs_server_sklab_dev
  id = "270125bd-024d-4a0d-b67a-717c330d973c"
}

import {
  to = terrifi_firewall_policy_order.external_to_k8s_01
  id = "ac40fe17-3454-4085-924e-25584b09948a:99e31282-ef3a-41c9-b516-8226ab2c65b1"
}

import {
  to = terrifi_firewall_policy_order.internal_to_k8s_01
  id = "4ef9a66f-f4e1-4442-a51a-1e636516b20d:99e31282-ef3a-41c9-b516-8226ab2c65b1"
}

import {
  to = terrifi_firewall_policy_order.vpn_to_internal
  id = "d43625d6-2373-490c-84b3-942adacb73c7:4ef9a66f-f4e1-4442-a51a-1e636516b20d"
}

import {
  to = terrifi_firewall_policy_order.k8s_01_to_external
  id = "99e31282-ef3a-41c9-b516-8226ab2c65b1:ac40fe17-3454-4085-924e-25584b09948a"
}

import {
  to = terrifi_firewall_policy_order.internal_to_server_talos
  id = "4ef9a66f-f4e1-4442-a51a-1e636516b20d:58669e45-e29e-48ce-a699-7a05dca7ac82"
}

import {
  to = terrifi_firewall_policy_order.internal_to_server_private
  id = "4ef9a66f-f4e1-4442-a51a-1e636516b20d:0993a852-a466-46f2-a438-a3b17c08ce41"
}
