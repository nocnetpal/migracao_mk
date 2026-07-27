# M1 Docker — RB3011 ether7 (madrugada)
# Pré: 00-bridge-servidores-base.rsc já rodado (.1 up)
# ether7 = "ether7 - Proxmox Docker CDNTV"
# Depois M2: host → 192.168.254.11/24 GW .1

/interface bridge port remove [find interface="ether7 - Proxmox Docker CDNTV"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether7 - Proxmox Docker CDNTV" pvid=100
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  untagged="ether7 - Proxmox Docker CDNTV"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether7 - Proxmox Docker CDNTV"

# Transicao: manter /30 antigo ate M2 validar .11 (mesmo L2 VLAN100)
# Se .121 ainda estiver na Bridge IP Publico, mover para vlan100:
:do {
  /ip address set [find address="192.168.116.121/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.116.122 count=5
/ping 192.168.254.1 count=2
/interface bridge vlan print where bridge=bridge-servidores
/interface bridge port print where bridge=bridge-servidores
