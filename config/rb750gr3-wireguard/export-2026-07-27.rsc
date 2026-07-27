# 2026-07-27 11:51:53 by RouterOS 7.21.5
# software id = 3UB9-5HEV
#
# model = RB750Gr3
# serial number = CC210F9A08D3
# identity = WIREGUARD
# NOTA (corrigido 2026-07-27): É o "RB BRIDGE 750" do rack — duplo papel:
# bridge L2 (HubSoft ether4 / Zabbix ether3 / NE8000 ether2 / uplink ether5)
# + VPN WireGuard/OpenVPN no 177.72.104.19. Ver bridge-host-2026-07-27.txt.
#
# Export colado pelo usuário 2026-07-27 — contém script de backup com
# credenciais FTP; não copiar senhas para docs.
/interface bridge
add name=bridge1
/interface wireguard
add listen-port=51820 mtu=1420 name=wg-mgmt
add listen-port=13231 mtu=1380 name=wireguard1
/ip smb users
set [ find default=yes ] disabled=yes
/routing id
add disabled=no id=177.72.104.19 name=id-1 select-dynamic-id=""
/routing ospf instance
add disabled=no in-filter-chain=OSPF-IN name=ospf-instance-1 \
    originate-default=never out-filter-chain=OSPF-OUT redistribute=\
    connected,static,ospf,vpn router-id=id-1 routing-table=main
/routing ospf area
add area-id=0.0.0.1 disabled=no instance=ospf-instance-1 name=ospf-area-1
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=ether3
add bridge=bridge1 interface=ether4
add bridge=bridge1 interface=ether5
/interface l2tp-server server
set enabled=yes
/interface ovpn-server server
add auth=sha1 certificate=SERVIDOR cipher=aes256-cbc disabled=no name=ovpn-server1 require-client-certificate=yes
/interface wireguard peers
add allowed-address=10.150.150.2/32 comment=Leonardo interface=wireguard1 name=peer1 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.4/32 comment="LEONARDO PC CASA" interface=wireguard1 name=peer3 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.5/32 comment="LEONARDO IPHONE" interface=wireguard1 name=peer6 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.6/32 comment=Bruno interface=wireguard1 name=peer7 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.7/32 comment=Leonardo interface=wireguard1 name=peer8 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.8/32 comment="PC Regis" interface=wireguard1 name=peer9 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.9/32 comment=Luann disabled=yes interface=wireguard1 name=peer10 responder=yes
add allowed-address=10.150.150.10/32 comment=Sabrina interface=wireguard1 name=peer11 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.11/32 comment=Isaac interface=wireguard1 name=peer12 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.12/32 comment="Bruno MAC" interface=wireguard1 name=peer13 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.13/32 comment="Bruno MAC Win" interface=wireguard1 name=peer14 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.3/32 comment=Leonardo2 interface=wireguard1 name=peer17 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.15/32 comment="RB RODEIO TVR" disabled=yes interface=wireguard1 name=peer19 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.14/32 comment="Sabrina iPad" interface=wireguard1 name=peer20 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.16/32 comment=AUTOBRAP interface=wireguard1 name=peer21 persistent-keepalive=25s responder=yes
add allowed-address=10.150.150.17/32 comment="Bruno Home" interface=wireguard1 name=peer22 persistent-keepalive=25s responder=yes
add allowed-address=10.99.0.2/32,10.90.0.0/22 comment="Condominio RARO" interface=wg-mgmt name=peer26
/ip address
add address=177.72.104.19/27 interface=ether5 network=177.72.104.0
add address=10.150.150.1/24 interface=wireguard1 network=10.150.150.0
add address=10.99.0.1/24 interface=wg-mgmt network=10.99.0.0
/ip dhcp-client
add interface=ether1
/ip dns
set servers=177.72.104.58,8.8.8.8
/ip firewall address-list
add address=10.150.150.0/24 list=NAT
/ip firewall nat
add action=src-nat chain=srcnat src-address-list=NAT to-addresses=177.72.104.19
/ip route
add dst-address=0.0.0.0/0 gateway=177.72.104.1
add dst-address=10.8.0.0/24 gateway=177.72.104.9
add dst-address=192.168.40.0/24 gateway=10.150.150.15
/routing ospf interface-template
add area=ospf-area-1 auth=md5 auth-id=1 interfaces=ether1 networks=177.72.104.0/27 type=ptp
add area=ospf-area-1 auth=md5 auth-id=0 interfaces=wireguard1 networks=10.150.150.0/24 type=ptp
/system identity
set name=WIREGUARD
# (peers public-keys e script backup omitidos/redigidos na copia sanitizada do chat;
#  arquivo completo do usuario permanece na sessao — re-exportar se precisar do .rsc bruto)
