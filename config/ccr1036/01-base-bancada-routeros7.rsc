# CCR1036 - configuracao base de bancada
# RouterOS 7.23.3 - 2026-08-06
# Nao habilita VLAN 16, NAT, DST-NAT ou WireGuard.

/system identity set name="CCR-GW_PRIV_SERVIDORES-VPN_WG"
/system note set show-at-login=yes note="Gateway da rede privada dos servidores | NAT | WireGuard"
/system clock set time-zone-name=America/Sao_Paulo

# Portas: um unico uplink no desenho final, pelo DM4170.
/interface ethernet
set [find default-name=ether1] name=ether1-MGMT comment="GERENCIA BANCADA"
set [find default-name=ether2] disabled=yes comment="RESERVA"
set [find default-name=ether3] disabled=yes comment="RESERVA"
set [find default-name=ether4] disabled=yes comment="RESERVA"
set [find default-name=ether5] disabled=yes comment="RESERVA"
set [find default-name=ether6] disabled=yes comment="RESERVA"
set [find default-name=ether7] disabled=yes comment="RESERVA"
set [find default-name=ether8] disabled=yes comment="RESERVA"
set [find default-name=sfp-sfpplus1] name=sfp1-TRUNK-DM comment="TRUNK DM4170 - VLAN 16 + REDES PRIVADAS"
set [find default-name=sfp-sfpplus2] name=sfp2-RESERVA disabled=yes comment="RESERVA"

/interface list
add name=MGMT comment="Interfaces autorizadas para gerencia"
add name=UPLINK comment="Uplink para o DM4170"

/interface list member
add interface=ether1-MGMT list=MGMT
add interface=sfp1-TRUNK-DM list=UPLINK

# IP temporario exclusivamente para a bancada. Remover/substituir antes da instalacao.
/ip address
add address=192.168.88.1/24 interface=ether1-MGMT comment="GERENCIA TEMPORARIA BANCADA"

# A VLAN publica e o IP de NAT ficam preparados, mas desativados.
/interface vlan
add name=vlan16-PUBLICA vlan-id=16 interface=sfp1-TRUNK-DM disabled=yes comment="177.72.104.0/27 - GW NE8000 .1"

/ip address
add address=177.72.104.4/27 interface=vlan16-PUBLICA disabled=yes comment="IP PUBLICO NAT CCR - ATIVAR NO CORTE"

/ip route
add dst-address=0.0.0.0/0 gateway=177.72.104.1 disabled=yes comment="DEFAULT NE8000 - ATIVAR NO CORTE"

# Dupla protecao: regra desativada e lista NAT-PRIVADAS ainda vazia/inexistente.
/ip firewall nat
add chain=srcnat action=src-nat to-addresses=177.72.104.4 src-address-list=NAT-PRIVADAS out-interface=vlan16-PUBLICA disabled=yes comment="NAT GERAL - ATIVAR SOMENTE NO CORTE"

# Gerencia local de bancada. Reavaliar a origem permitida antes de instalar no rack.
/ip service
set [find name=telnet] disabled=yes
set [find name=ftp] disabled=yes
set [find name=www] disabled=yes
set [find name=www-ssl] disabled=yes
set [find name=reverse-proxy] disabled=yes
set [find name=api] disabled=yes
set [find name=api-ssl] disabled=yes
set [find name=ssh] disabled=no address=192.168.88.0/24
set [find name=winbox] disabled=no address=192.168.88.0/24

/ip ssh set strong-crypto=yes
/ip dns set allow-remote-requests=no
/tool bandwidth-server set enabled=no
/tool romon set enabled=no

/ip neighbor discovery-settings set discover-interface-list=MGMT
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/tool mac-server ping set enabled=no

/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="INPUT - ESTABLISHED RELATED"
add chain=input action=drop connection-state=invalid comment="INPUT - DROP INVALID"
add chain=input action=accept protocol=icmp comment="INPUT - ICMP"
add chain=input action=accept in-interface-list=MGMT src-address=192.168.88.0/24 comment="INPUT - GERENCIA BANCADA"
add chain=input action=drop comment="INPUT - DROP FINAL"

# WireGuard sera configurado somente depois de toda a migracao concluida e validada.
