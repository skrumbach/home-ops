# Evaluation order of user policies, only for zone pairs with two or more of
# them (a single-policy pair has nothing to order). Built-in policies always run
# after these. terrifi does not read policy_ids back on import, so the first
# apply rewrites each order to the list below, which is the controller's
# current order as of 2026-11-07. Skill `unifi-network`.

resource "terrifi_firewall_policy_order" "external_to_k8s_01" {
  source_zone_id      = local.builtin_zone_ids.external
  destination_zone_id = terrifi_firewall_zone.k8s_01.id
  policy_ids = [
    terrifi_firewall_policy.allow_bgp_4.id,
    terrifi_firewall_policy.test.id,
    terrifi_firewall_policy.block_traffic_from_104_21_48_100.id,
  ]
}

resource "terrifi_firewall_policy_order" "internal_to_k8s_01" {
  source_zone_id      = local.builtin_zone_ids.internal
  destination_zone_id = terrifi_firewall_zone.k8s_01.id
  policy_ids = [
    terrifi_firewall_policy.internal_to_k8s_01.id,
    terrifi_firewall_policy.k8s_allow_https_route.id,
    terrifi_firewall_policy.allow_pods_to_external_gateway.id,
  ]
}

resource "terrifi_firewall_policy_order" "vpn_to_internal" {
  source_zone_id      = local.builtin_zone_ids.vpn
  destination_zone_id = local.builtin_zone_ids.internal
  policy_ids = [
    terrifi_firewall_policy.allow_k8s.id,
    terrifi_firewall_policy.k8s_loadbalancer.id,
  ]
}

resource "terrifi_firewall_policy_order" "k8s_01_to_external" {
  source_zone_id      = terrifi_firewall_zone.k8s_01.id
  destination_zone_id = local.builtin_zone_ids.external
  policy_ids = [
    terrifi_firewall_policy.block_traffic_to_itorrents_net.id,
    terrifi_firewall_policy.block_traffic_to_104_21_48_100.id,
  ]
}

resource "terrifi_firewall_policy_order" "internal_to_server_talos" {
  source_zone_id      = local.builtin_zone_ids.internal
  destination_zone_id = terrifi_firewall_zone.server_talos.id
  policy_ids = [
    terrifi_firewall_policy.aviator.id,
    terrifi_firewall_policy.allow_bgp.id,
    terrifi_firewall_policy.allow_all_3.id,
  ]
}

resource "terrifi_firewall_policy_order" "internal_to_server_private" {
  source_zone_id      = local.builtin_zone_ids.internal
  destination_zone_id = terrifi_firewall_zone.server_private.id
  policy_ids = [
    terrifi_firewall_policy.aviator_s_pc.id,
    terrifi_firewall_policy.pxe.id,
    terrifi_firewall_policy.allow_all_nas.id,
  ]
}
