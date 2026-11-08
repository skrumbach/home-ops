# One-time migration from alexklibisz/terrifi to ubiquiti-community/unifi.
# Each block drops a terrifi object from state without touching the
# controller; imports.tofu adopts the same object under the new provider.
# Delete this file and the terrifi provider once the apply has run.
# The 3 policy orders and 7 client groups have no equivalent and go back to
# the UI unchanged. Skill `unifi-network`.

removed {
  from = terrifi_network.home_default

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.iot_devices

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.unifi_managment

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.server_private

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.security_cams

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.managment

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.vpn_network

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.home_ops_lb

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_network.home_ops_pods

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_wlan.u7_secure

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_wlan.u7_guest

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_wlan.u7_iot

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_wlan.u7_home

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_zone.iot

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_zone.server_private

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_zone.vpn_network

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_zone.k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_all

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_all_traffic

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_all_2

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.aviator_s_pc

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.vpn_allow_server

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.internal_to_k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.server_private_to_k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.k8s_to_internal_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.k8s_to_server_private_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.all

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.k8s_allow_https_route

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_pods_to_internal_gateway

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_pods_to_external_gateway

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.vpn_to_cluster

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.allow_k8s

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.k8s_loadbalancer

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.vpn_network_external

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.vpn_network_gateway

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.block_traffic_to_itorrents_net

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.block_traffic_to_104_21_48_100

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy.block_traffic_from_104_21_48_100

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.ms_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.talos_1

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.ms01_02

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.minisforum_ms01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.ms01_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_group.ms01_03

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.desktop_pc_sascha

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.voron_3d_printer

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.hubitat

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.hp_printer

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.true_nas_enp7s0

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_03_talos_1_2

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device._1c_f6_4c_60_b4_42

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device._40_91_51_2a_df_47

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_02_vpro

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_03_vpro

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_01_vpro

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_01_talos_1_2

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_client_device.ms01_02_talos_1_2

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_dns_record.nas_sklab_dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_dns_record.media_sklab_dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_dns_record.mgnt_sklab_local

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_dns_record.pbs_server_sklab_dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy_order.internal_to_k8s_01

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy_order.vpn_to_internal

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_firewall_policy_order.k8s_01_to_external

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_device_ports.usw_pro_max_48_poe

  lifecycle {
    destroy = false
  }
}

removed {
  from = terrifi_device_ports.usw_pro_aggregation

  lifecycle {
    destroy = false
  }
}
