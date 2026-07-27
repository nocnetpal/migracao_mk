#!/bin/bash
# M2 Docker — proxmoxDockerCDNTV (DEPOIS M1 OK)
# Alvo gerencia: 192.168.254.11/24  GW 192.168.254.1
# Hoje: 192.168.116.122/30 em vmbr1
set -euo pipefail

echo "=== 1) VLAN-aware vmbr1 ==="
grep -A25 'iface vmbr1' /etc/network/interfaces || true
echo "Acrescentar no bloco vmbr1: bridge-vlan-aware yes + bridge-vids 2-4094"
echo "Depois: ifreload -a && cat /sys/class/net/vmbr1/bridge/vlan_filtering"

echo "=== 2) IP novo EM PARALELO (editar interfaces) ==="
echo "  address 192.168.254.11/24"
echo "  gateway 192.168.254.1"
echo "Manter .122 ate ping .1 e GUI 8006 no .11 OK; ai remover /30."

echo "=== 3) tag 16 VMs vmbr1 ==="
qm set 103 -net0 e1000,bridge=vmbr1,tag=16,firewall=1,macaddr=F6:C7:5C:8A:4A:A3
qm set 104 -net0 virtio,bridge=vmbr1,tag=16,firewall=0,macaddr=6E:26:1A:C9:19:CE
qm set 105 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=62:B2:A1:0A:B1:AE
qm set 106 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=0E:C8:34:76:59:4E
qm set 107 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=36:DC:89:9D:DA:5A
qm set 101 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,queues=8,macaddr=2A:B7:2D:D8:6E:A2

echo "=== Docker-Netpal macvlan 177: parent tag 16 (ajustar na VM) ==="
echo "NAO mexer net5/net6 (tags 18/38)"

for id in 101 103 104 105 106 107; do echo "=== $id ==="; qm config $id | grep ^net; done
ping -c 3 192.168.254.1 || true
ping -c 3 177.72.104.12 || true
