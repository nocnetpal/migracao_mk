# M1 HubSoft + Zabbix — ADIADO (usuario 2026-07-27)
# NAO APLICAR: nao mexer no bridge do RB750.
# HubSoft/Zabbix migram na troca pra CCR/Datacom.
# Conteudo antigo preservado abaixo so como referencia — NAO COLAR.
# Pre-check 2026-08-05 confirmou dois bloqueios adicionais:
# 1. ativar vlan-filtering tambem muda Zabbix, WireGuard e gerencia do NE8000;
# 2. HUBSOFT-RADIUS .214 usa gateway .213/30, que tambem precisa viajar na VLAN 100.
# Captura final: segundo handoff entre Bridge IP Publico e bridge-servidores
# empilha QinQ 16,100. Este desenho nao deve ser repetido.

:error "BLOQUEADO: caminho RB750/RB3011 produz QinQ 16,100; migrar somente no novo L2 DM4170"

# =============================================================================
# (A) No RB750-WIREGUARD — NAO USAR AGORA
# =============================================================================

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
:do {
  /ip address set [find address="192.168.115.213/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.254.1 count=2
/ping 177.72.104.19 count=5
/ping 192.168.115.210 count=3
/ping 192.168.115.214 count=3
/ping 177.72.104.5 count=3
/interface bridge vlan print where bridge=bridge-servidores
/interface bridge port print where bridge=bridge-servidores
