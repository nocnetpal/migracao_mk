# Rollback DNS — RB3011

/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 untagged~"ether8"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether8"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether8"]

:do {
  /ip address set [find address="192.168.115.137/30"] interface="Bridge IP Publico"
} on-error={}

/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether8 - Proxmox DNS" hw=yes

/ping 192.168.115.138 count=5
