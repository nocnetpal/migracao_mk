# CCR1036 - preparacao da primeira rede privada
# Tudo permanece desativado para nao conflitar com o gateway .1 ainda no RB3011.

/interface vlan
add name=vlan100-PRIVADA vlan-id=100 interface=sfp1-TRUNK-DM disabled=yes comment="GW PRIVADO PROXMOX - ATIVAR NO CORTE"

/ip address
add address=192.168.254.1/24 interface=vlan100-PRIVADA disabled=yes comment="GW VLAN 100 - ATIVAR NO CORTE"

/ip firewall address-list
add list=NAT-PRIVADAS address=192.168.254.0/24 disabled=yes comment="VLAN 100 - HABILITAR COM NAT NO CORTE"
