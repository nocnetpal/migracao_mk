# Aplicado 2026-07-27 no equipamento (confirmado via print).
# Identity: RB750-WIREGUARD
# ether1 - LIVRE | ether2 - NE8000 Gerencia | ether3 - Proxmox Zabbix
# ether4 - Proxmox HubSoft | ether5 - Uplink GW Servidores
# bridge1 - Servidores | comments em wireguard1 / wg-mgmt
#
# Renomear portas WIREGUARD = RB BRIDGE 750 (2026-07-27)
# Seguro: só name/comment. Não mexe em bridge/IP/VPN.
# Colar no WIREGUARD; depois: /interface ethernet print

/system identity set name="RB750-WIREGUARD"

/interface ethernet
set [find default-name=ether1] \
  name="ether1 - LIVRE" \
  comment="porta livre"
set [find default-name=ether2] \
  name="ether2 - NE8000 Gerencia" \
  comment="Huawei NE8000 — gerencia"
set [find default-name=ether3] \
  name="ether3 - Proxmox Zabbix" \
  comment="HP DL360 G7 — cluster Zabbix/Zeus"
set [find default-name=ether4] \
  name="ether4 - Proxmox HubSoft" \
  comment="Dell R720 — HubSoft + Radius"
set [find default-name=ether5] \
  name="ether5 - Uplink GW Servidores" \
  comment="uplink RB3011 ether10 + IP 177.72.104.19/27"

/interface bridge set [find name=bridge1] \
  name="bridge1 - Servidores" \
  comment="HubSoft + Zabbix + NE8000 mgmt + uplink"

/interface wireguard
set [find name=wireguard1] comment="VPN usuarios 10.150.150.0/24 UDP 13231"
set [find name=wg-mgmt] comment="VPN mgmt condominio 10.99.0.0/24 UDP 51820"

# Conferir:
# /interface ethernet print
# /system identity print
