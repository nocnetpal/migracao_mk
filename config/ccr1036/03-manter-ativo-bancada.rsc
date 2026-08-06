# Decisao do usuario em 2026-08-06: manter VLANs, IPs, rota e NAT habilitados.
# Nao conectar o trunk ao dominio de producao enquanto o RB3011 ainda usar 192.168.254.1.

/interface vlan set [find name=vlan16-PUBLICA] disabled=no comment="IP PUBLICO - GW NE8000 .1"
/interface vlan set [find name=vlan100-PRIVADA] disabled=no comment="GW PRIVADO PROXMOX"

/ip address set [find address="177.72.104.4/27"] disabled=no comment="IP PUBLICO NAT CCR"
/ip address set [find address="192.168.254.1/24"] disabled=no comment="GW VLAN 100"

/ip firewall address-list set [find list=NAT-PRIVADAS address="192.168.254.0/24"] disabled=no comment="VLAN 100"
/ip route set [find dst-address="0.0.0.0/0" gateway="177.72.104.1"] disabled=no comment="DEFAULT NE8000"
/ip firewall nat set [find chain=srcnat to-addresses="177.72.104.4"] disabled=no comment="NAT GERAL"
