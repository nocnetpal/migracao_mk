# M1 DNS — RB3011 ether8 (madrugada)
# Pré: bridge-servidores + .1 já existem (noite Docker)
# ether8 = "ether8 - Proxmox DNS"
# Depois M2: host → 192.168.254.12/24 GW .1

/interface bridge port remove [find interface="ether8 - Proxmox DNS"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether8 - Proxmox DNS" pvid=100
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  untagged="ether8 - Proxmox DNS"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether8 - Proxmox DNS"

:do {
  /ip address set [find address="192.168.115.137/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.115.138 count=5
/ping 192.168.254.1 count=2
/interface bridge port print where bridge=bridge-servidores
