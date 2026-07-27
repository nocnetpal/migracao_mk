# M1 HubSoft + Zabbix — MESMA madrugada (RB750 + RB3011 ether10)
# Ordem: (A) RB750-WIREGUARD → (B) RB3011 ether10 → validar → M2 hosts
# IPs alvo: HubSoft .13 · Zabbix .10 · GW .1
# Nomes confirmados 2026-07-27.

# =============================================================================
# (A) No RB750-WIREGUARD
# =============================================================================
# Impacto: HubSoft + Zabbix + NE8000 mgmt + .19 VPN no mesmo bridge.
# Mover .19 para vlan16 ANTES de vlan-filtering efetivo no uplink.

/interface vlan add name=vlan16-wg vlan-id=16 interface="bridge1 - Servidores" \
  comment="IP PUBLICO .19 WireGuard"
/interface vlan add name=vlan100-wg vlan-id=100 interface="bridge1 - Servidores" \
  comment="GERENCIA (L2 only; GW fica no RB3011 .1)"

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
  tagged="ether5 - Uplink GW Servidores","bridge1 - Servidores"
add bridge="bridge1 - Servidores" vlan-ids=16 \
  tagged="ether3 - Proxmox Zabbix","ether4 - Proxmox HubSoft","ether5 - Uplink GW Servidores","bridge1 - Servidores"

# ether2 NE8000: so 100 (untagged) — sem tag 16 a menos que precise publico
# Conferir:
# /ip address print where address~"177.72.104.19"
# /ping 177.72.104.1 count=5
# /interface wireguard peers print

# =============================================================================
# (B) No RB3011 — ether10 = "ether10 - RB750 Bridge" (confirmado 2026-07-27)
# Pré: bridge-servidores + .1 já existem
# =============================================================================

/interface bridge port remove [find interface~"ether10"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether10 - RB750 Bridge" pvid=1
# uplink: tagged 100+16 (sem untagged util)
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  tagged="ether10 - RB750 Bridge"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether10 - RB750 Bridge"

# Transicao /30 HubSoft se existir:
:do {
  /ip address set [find address="192.168.115.209/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.254.1 count=2
/ping 177.72.104.19 count=5
/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
/interface bridge vlan print where bridge=bridge-servidores
/interface bridge port print where bridge=bridge-servidores
