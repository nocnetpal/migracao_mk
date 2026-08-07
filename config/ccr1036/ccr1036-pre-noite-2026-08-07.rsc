# 2026-08-06 11:29:51 by RouterOS 7.23.3
# software id = 298D-CXEC
#
# model = CCR1036-8G-2S+
# serial number = 968E0A898BCE
/interface ethernet
set [ find default-name=ether1 ] comment="GERENCIA BANCADA" name=ether1-MGMT
set [ find default-name=ether2 ] comment=RESERVA disabled=yes
set [ find default-name=ether3 ] comment=RESERVA disabled=yes
set [ find default-name=ether4 ] comment=RESERVA disabled=yes
set [ find default-name=ether5 ] comment=RESERVA disabled=yes
set [ find default-name=ether6 ] comment=RESERVA disabled=yes
set [ find default-name=ether7 ] comment=RESERVA disabled=yes
set [ find default-name=ether8 ] comment=RESERVA disabled=yes
set [ find default-name=sfp-sfpplus1 ] comment=\
    "TRUNK DM4170 - VLAN 16 + REDES PRIVADAS" name=sfp1-TRUNK-DM
set [ find default-name=sfp-sfpplus2 ] comment=RESERVA disabled=yes name=\
    sfp2-RESERVA
/interface vlan
add comment="NTP container 192.168.116.10" interface=sfp1-TRUNK-DM name=\
    vlan15-NTP vlan-id=15
add comment="IP PUBLICO - GW NE8000 .1" interface=sfp1-TRUNK-DM name=\
    vlan16-PUBLICA vlan-id=16
add comment="TS SIX 192.168.66.14/28 (era ether6 RB3011)" interface=\
    sfp1-TRUNK-DM name=vlan66-TS-SIX vlan-id=66
add comment="GW PRIVADO PROXMOX" interface=sfp1-TRUNK-DM name=vlan100-PRIVADA \
    vlan-id=100
add comment="OLT CPV 192.168.115.42/30 (era ether9 RB3011)" interface=\
    sfp1-TRUNK-DM name=vlan109-OLT-CPV vlan-id=109
add comment="DUDE/legado 192.168.116.30/30 (era Bridge IP Publico RB3011)" \
    interface=sfp1-TRUNK-DM name=vlan116-DUDE vlan-id=116
/interface list
add comment="Interfaces autorizadas para gerencia" name=MGMT
add comment="Uplink para o DM4170" name=UPLINK
/interface lte apn
set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/port
set 0 baud-rate=auto
set 1 baud-rate=auto
/routing ospf instance
add disabled=no name=ospf1 router-id=177.72.104.15
/routing ospf area
add area-id=0.0.0.1 instance=ospf1 name=area0.0.0.1
/ip firewall connection tracking
set udp-timeout=10s
/ip neighbor discovery-settings
set discover-interface-list=MGMT
/ip settings
set max-neighbor-entries=8192
/ipv6 settings
set disable-ipv6=yes max-neighbor-entries=8192 soft-max-neighbor-entries=8191
/interface list member
add interface=ether1-MGMT list=MGMT
add interface=sfp1-TRUNK-DM list=UPLINK
/interface ovpn-server server
add auth=sha1,md5 mac-address=FE:90:C3:6E:2B:34 name=ovpn-server1
/ip address
add address=192.168.88.1/24 comment="GERENCIA TEMPORARIA BANCADA" interface=\
    ether1-MGMT network=192.168.88.0
add address=177.72.104.15/27 comment="IP PUBLICO NAT CCR" interface=\
    vlan16-PUBLICA network=177.72.104.0
add address=192.168.254.1/24 comment="GW VLAN 100" interface=vlan100-PRIVADA \
    network=192.168.254.0
add address=192.168.116.9/30 comment="GW NTP" interface=vlan15-NTP network=\
    192.168.116.8
add address=192.168.66.1/28 comment="GW TS SIX" interface=vlan66-TS-SIX \
    network=192.168.66.0
add address=192.168.115.41/30 comment="GW OLT CPV" interface=vlan109-OLT-CPV \
    network=192.168.115.40
add address=192.168.116.29/30 comment="GW DUDE/legado" interface=vlan116-DUDE \
    network=192.168.116.28
/ip firewall address-list
add address=192.168.254.0/24 comment="VLAN 100" list=NAT-PRIVADAS
add address=177.72.104.19 comment="SERVIDOR WIREGUARD" list=ORIGENS-GERENCIA
add address=177.93.244.165 comment=NOC list=ORIGENS-GERENCIA
add address=10.150.150.0/24 comment="CLIENTES WIREGUARD" list=\
    ORIGENS-GERENCIA
add address=192.168.254.0/24 comment="VLAN 100" list=REDES-PRIVADAS
add address=192.168.66.0/28 comment="VLAN 66 - TS SIX" list=REDES-PRIVADAS
add address=192.168.115.40/30 comment="VLAN 109 - OLT CPV" list=\
    REDES-PRIVADAS
add address=192.168.116.28/30 comment="VLAN 116 - DUDE" list=REDES-PRIVADAS
add address=192.168.66.0/28 comment="VLAN 66 - TS SIX" list=NAT-PRIVADAS
add address=192.168.116.28/30 comment="VLAN 116 - DUDE" list=NAT-PRIVADAS
/ip firewall filter
add action=accept chain=input comment="INPUT - ESTABLISHED RELATED" \
    connection-state=established,related,untracked
add action=drop chain=input comment="INPUT - DROP INVALID" connection-state=\
    invalid
add action=accept chain=input comment="INPUT - ICMP" protocol=icmp
add action=accept chain=input comment="INPUT - GERENCIA BANCADA" \
    in-interface-list=MGMT src-address=192.168.88.0/24
add action=accept chain=input comment="INPUT - OSPF NE8000" in-interface=\
    vlan16-PUBLICA protocol=ospf src-address=177.72.104.1
add action=accept chain=input comment="INPUT - GERENCIA REMOTA WG" \
    src-address-list=ORIGENS-GERENCIA
add action=accept chain=input comment="INPUT - GERENCIA /27" src-address=\
    177.72.104.0/27
add action=accept chain=input comment="INPUT - GERENCIA NOC" src-address=\
    177.93.244.165
add action=drop chain=input comment="INPUT - DROP FINAL"
add action=accept chain=forward comment="FORWARD - ESTABLISHED RELATED" \
    connection-state=established,related,untracked
add action=drop chain=forward comment="FORWARD - DROP INVALID" \
    connection-state=invalid
add action=accept chain=forward comment="FORWARD - DSTNAT" \
    connection-nat-state=dstnat
add action=accept chain=forward comment="FORWARD - PRIVADAS PARA INTERNET" \
    out-interface=vlan16-PUBLICA src-address-list=NAT-PRIVADAS
add action=accept chain=forward comment=\
    "FORWARD - GERENCIA PARA REDES PRIVADAS" dst-address-list=REDES-PRIVADAS \
    src-address-list=ORIGENS-GERENCIA
add action=accept chain=forward comment="NTP - LIBERA CONSULTA UDP 123" \
    dst-address=192.168.116.10 dst-port=123 protocol=udp
add action=drop chain=forward comment="FORWARD - DROP FINAL"
/ip firewall nat
add action=src-nat chain=srcnat comment="NAT GERAL" out-interface=\
    vlan16-PUBLICA src-address-list=NAT-PRIVADAS to-addresses=177.72.104.15
add action=dst-nat chain=dstnat comment="DUDE - era .1:18291" dst-address=\
    177.72.104.15 dst-port=18291 protocol=tcp to-addresses=192.168.116.30 \
    to-ports=8291
add action=dst-nat chain=dstnat comment="TS SIX - era .1:15389" dst-address=\
    177.72.104.15 dst-port=15389 protocol=tcp to-addresses=192.168.66.14 \
    to-ports=15389
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route
add comment="DEFAULT NE8000" disabled=no dst-address=0.0.0.0/0 gateway=\
    177.72.104.1
/ip service
set ftp disabled=yes
set ssh address=192.168.88.0/24,177.72.104.0/27,177.93.244.165/32
set telnet disabled=yes
set www disabled=yes
set reverse-proxy disabled=yes
set winbox address=192.168.88.0/24,177.72.104.0/27,177.93.244.165/32
set api disabled=yes
set api-ssl disabled=yes
/ip ssh
set strong-crypto=yes
/routing bfd configuration
add disabled=no interfaces=all min-rx=200ms min-tx=200ms multiplier=5
/routing ospf interface-template
add area=area0.0.0.1 auth=md5 auth-id=1 comment="OSPF NE8000" interfaces=\
    vlan16-PUBLICA type=ptp
add area=area0.0.0.1 comment="OSPF PASSIVA VLAN 100" interfaces=\
    vlan100-PRIVADA passive
add area=area0.0.0.1 comment="OSPF PASSIVA VLAN 15" interfaces=vlan15-NTP \
    passive
add area=area0.0.0.1 comment="OSPF PASSIVA VLAN 66" interfaces=vlan66-TS-SIX \
    passive
add area=area0.0.0.1 comment="OSPF PASSIVA VLAN 109" interfaces=\
    vlan109-OLT-CPV passive
add area=area0.0.0.1 comment="OSPF PASSIVA VLAN 116" interfaces=vlan116-DUDE \
    passive
/system clock
set time-zone-name=America/Sao_Paulo
/system identity
set name=CCR-GW_PRIV_SERVIDORES-VPN_WG
/system note
set note="Gateway da rede privada dos servidores | NAT | WireGuard"
/system ntp client
set enabled=yes
/system ntp client servers
add address=192.168.116.10
/tool bandwidth-server
set enabled=no
/tool mac-server
set allowed-interface-list=MGMT
/tool mac-server mac-winbox
set allowed-interface-list=MGMT
/tool mac-server ping
set enabled=no
