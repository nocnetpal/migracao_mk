#!/bin/bash
# M2 HubSoft — px-hubsoft (DEPOIS M1 HubSoft+Zabbix OK)
# Alvo gerencia: 192.168.254.13/24  GW 192.168.254.1
# Hoje: 192.168.115.210/30 · vlan-aware ja =1
# NAO EXECUTAR ISOLADAMENTE: o RB750 precisa transportar VLANs 100/16 sem
# quebrar Zabbix/WireGuard/gerencia NE8000, e o gateway RADIUS .213/30 deve
# estar na VLAN 100 antes de manter a VM 101 untagged.
set -euo pipefail

cat /sys/class/net/vmbr0/bridge/vlan_filtering

echo "=== IP .13/24 GW .1 em paralelo; remover .210 depois ==="

qm set 102 -net0 virtio,bridge=vmbr0,tag=16,macaddr=72:56:05:A7:29:E9
# 101 RADIUS: native VLAN 100 — SEM tag 16
qm config 102 | grep ^net
qm config 101 | grep ^net || true

ping -c 3 192.168.254.1 || true
ping -c 3 177.72.104.16 || true
ping -c 3 192.168.115.214 || true
