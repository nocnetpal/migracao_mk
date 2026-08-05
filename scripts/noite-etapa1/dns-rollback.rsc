# Rollback DNS — RB3011

# Preservar as entradas VLAN usadas pelo Docker; retirar somente ether8 das listas.
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=100] \
  tagged=bridge-servidores untagged="ether7 - Proxmox Docker CDNTV"
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=16] \
  tagged="bridge-servidores,ether7 - Proxmox Docker CDNTV" untagged=""
/interface bridge port remove [find bridge=bridge-servidores interface~"ether8"]

:do {
  /ip address set [find address="192.168.115.137/30"] interface="Bridge IP Publico"
} on-error={}

/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether8 - Proxmox DNS" hw=yes

/ping 192.168.115.138 count=5
