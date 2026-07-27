# Rollback HubSoft+Zabbix — RB750 depois RB3011
# Ordem inversa do M1. Cuidado: .19 precisa voltar pro ether5.

# --- RB750-WIREGUARD ---
/interface bridge set [find name="bridge1 - Servidores"] vlan-filtering=no
/interface bridge vlan remove [find bridge="bridge1 - Servidores"]
/ip address set [find address="177.72.104.19/27"] interface="ether5 - Uplink GW Servidores"
/interface vlan remove [find name=vlan16-wg]
/interface vlan remove [find name=vlan100-wg]
/ping 177.72.104.1 count=5

# --- RB3011 ---
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 tagged~"ether10"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether10"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether10"]

:do {
  /ip address set [find address="192.168.115.209/30"] interface="Bridge IP Publico"
} on-error={}

# Conferir nome exato do ether10:
/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether10 - RB750 Bridge" hw=yes

/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
/ping 177.72.104.19 count=3
