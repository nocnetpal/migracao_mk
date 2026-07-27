#!/bin/bash
# M2 Zabbix — proxmox3 (DEPOIS M1 HubSoft+Zabbix OK; mesma noite que HubSoft)
# Alvo gerencia: 192.168.254.10/24  GW 192.168.254.1
# Hoje: 177.72.104.5/27 no vmbr0 — OBRIGATORIO sair
set -euo pipefail

echo "=== 1) VLAN-aware vmbr0 ==="
grep -A20 'iface vmbr0' /etc/network/interfaces || true
echo "bridge-vlan-aware yes; ifreload -a"

echo "=== 2) IP .10/24 GW .1 EM PARALELO (manter .5 ate validar) ==="
echo "ping 192.168.254.1 && curl -k https://192.168.254.10:8006"
echo "Atualizar Dude .5 -> .10; so entao remover 177.72.104.5"

echo "=== 3) tag 16 VMs publicas ==="
qm set 110 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=4E:01:6C:C9:F0:78
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=B2:63:2D:95:56:FD
qm set 107 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=56:EC:57:EB:68:14
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=8A:26:35:E8:3A:BF
qm set 104 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=EE:2A:8A:5A:EE:E0
qm set 106 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=1A:97:C3:E0:DC:D3
qm set 108 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=16:8C:EF:D4:03:FD
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=F2:19:E1:4A:8C:8A
# 100/101/109 — privadas / later (sem tag 16)

for id in 102 103 104 105 106 107 108 110; do echo "=== $id ==="; qm config $id | grep ^net; done
ping -c 3 192.168.254.1 || true
ping -c 3 177.72.104.6 || true
echo "Pendencia: remover .5 do vmbr0 apos Dude/bookmarks OK"
