# M1 HubSoft + Zabbix — MESMA madrugada (RB750 + RB3011 ether10)
# Ordem: (A) RB750-WIREGUARD → (B) RB3011 ether10 → validar → M2 hosts
# IPs alvo: HubSoft .13 · Zabbix .10 · GW .1
# Nomes confirmados 2026-07-27.

# =============================================================================
# (A) No RB750-WIREGUARD
# =============================================================================
# Por que vlan16-wg?
# Hoje .19 esta no ether5 (L2 flat). Com vlan-filtering, publico = VLAN 16.
# WireGuard/NAT precisa do .19 no /27 → move IP para iface VLAN 16 no bridge.
# vlan100-wg NAO precisa: RB750 so encaminha L2 da 100; GW .1 fica no RB3011.

/interface vlan add name=vlan16-wg vlan-id=16 interface="bridge1 - Servidores" \
  comment="IP PUBLICO .19 WireGuard — obrigatorio apos vlan-filtering"

/ip address set [find address="177.72.104.19/27"] interface=vlan16-wg

/interface bridge set [find name="bridge1 - Servidores"] vlan-filtering=yes

/interface bridge port
set [find interface="ether1 - LIVRE"] pvid=100
set [find interface="ether2 - NE8000 Gerencia"] pvid=100
set [find interface="ether3 - Proxmox Zabbix"] pvid=100
set [find interface="ether4 - Proxmox HubSoft"] pvid=100
set [find interface="ether5 - Uplink GW Servidores"] pvid=100

/interface bridge vlan
add bridge="bridge1 - Servidores" vlan-ids=100 \
  untagged="ether1 - LIVRE","ether2 - NE8000 Gerencia","ether3 - Proxmox Zabbix","ether4 - Proxmox HubSoft" \
  tagged="ether5 - Uplink GW Servidores"
add bridge="bridge1 - Servidores" vlan-ids=16 \
  tagged="ether3 - Proxmox Zabbix","ether4 - Proxmox HubSoft","ether5 - Uplink GW Servidores","bridge1 - Servidores"

# Conferir:
# /ip address print where address~"177.72.104.19"
# /ping 177.72.104.1 count=5

# =============================================================================
# (B) No RB3011 — ether10 = "ether10 - RB750 Bridge" (confirmado 2026-07-27)
# Pré: bridge-servidores + .1 já existem
# =============================================================================

/interface bridge port remove [find interface~"ether10"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether10 - RB750 Bridge" pvid=1
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  tagged="ether10 - RB750 Bridge"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether10 - RB750 Bridge"

:do {
  /ip address set [find address="192.168.115.209/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.254.1 count=2
/ping 177.72.104.19 count=5
/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
/interface bridge vlan print where bridge=bridge-servidores
/interface bridge port print where bridge=bridge-servidores
