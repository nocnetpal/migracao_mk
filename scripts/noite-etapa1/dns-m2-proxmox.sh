#!/bin/bash
# M2 DNS — proxmox-dns (DEPOIS M1 OK)
# Alvo gerencia: 192.168.254.12/24  GW 192.168.254.1
# Hoje: 192.168.115.138/30
set -euo pipefail

echo "=== VLAN-aware vmbr0 + IP .12 em paralelo; remover .138 depois ==="
grep -A20 'iface vmbr0' /etc/network/interfaces || true

if [[ "$(cat /sys/class/net/vmbr0/bridge/vlan_filtering)" != "1" ]]; then
  echo "ERRO: vmbr0 ainda nao esta VLAN-aware; parar sem alterar as VMs" >&2
  exit 1
fi

if ! ip -4 addr show dev vmbr0 | grep -q '192\.168\.254\.12/24'; then
  echo "ERRO: IP paralelo 192.168.254.12/24 ainda nao esta ativo; parar" >&2
  exit 1
fi

qm set 101 -net0 e1000e,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:89:AD:23
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:50:14:F9
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:BF:0B:B5
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:E7:B0:75

for id in 101 102 103 105; do echo "=== $id ==="; qm config $id | grep ^net; done
ping -c 3 192.168.254.1 || true
for ip in 177.72.104.24 177.72.104.26 177.72.104.29 \
  177.72.104.28 177.72.104.58 177.72.104.59; do
  ping -c 3 "$ip" || true
done
