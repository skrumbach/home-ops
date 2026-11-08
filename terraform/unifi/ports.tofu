# Switch port overrides. Only listed ports are managed; every other port keeps
# what the UI set. Removing a port from `ports` deletes its whole override.
#
# Port 49 (SFP+ 1, LACP with 50) is the uplink to the Aggregation switch. It is
# listed exactly as the controller has it because import adopts every port
# terrifi can represent: leaving it out plans a deletion of its override, which
# breaks the uplink. Never drop or change it without a console on the switch.
#
# Not here, on purpose:
# - Ports 34, 36, 38: disabled; terrifi cannot represent forward mode "disabled"
#   and leaves them untouched.
# - USW Pro Aggregation: its 7 LACP groups are the Talos bonds and uplinks.
# - USW Flex: no overrides, nothing to manage.
# Each change re-provisions the switch. Skill `unifi-network`.

resource "terrifi_device_ports" "usw_pro_max_48_poe" {
  device_mac = "9c:05:d6:af:79:45"
  ports = {
    "1"  = { name = "Port 1", native_network_id = terrifi_network.server_private.id, tagged_vlan_mode = "allow_all" }
    "2"  = { name = "Port 2", native_network_id = terrifi_network.server_private.id, tagged_vlan_mode = "allow_all" }
    "3"  = { name = "Port 3", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "4"  = { name = "Port 4", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "15" = { name = "Port 15", native_network_id = terrifi_network.iot_devices.id, tagged_vlan_mode = "allow_all" }
    "28" = { name = "Port 28", native_network_id = terrifi_network.iot_devices.id, tagged_vlan_mode = "allow_all" }
    "31" = { name = "Port 31", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "33" = { name = "Port 33", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "35" = { name = "Port 35", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "37" = { name = "Port 37", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    "39" = { name = "Port 39", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
    # Uplink LAG, see header.
    "49" = { name = "SFP+ 1", native_network_id = terrifi_network.home_default.id, tagged_vlan_mode = "allow_all" }
  }
}
