# Rollback Docker — RB3011
# Volta ether7 pra Bridge IP Publico; nao remove bridge-servidores se DNS/RB750 ja usam

/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 untagged~"ether7"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether7"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether7"]

:do {
  /ip address set [find address="192.168.116.121/30"] interface="Bridge IP Publico"
} on-error={}

/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether7 - Proxmox Docker CDNTV" hw=yes

/ping 192.168.116.122 count=5
