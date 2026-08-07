# 2026-08-07 17:46:12 by RouterOS 7.21.5
# software id = 3UB9-5HEV
#
# model = RB750Gr3
# serial number = CC210F9A08D3
/interface bridge
add comment="HubSoft + Zabbix + NE8000 mgmt + uplink" name=\
    "bridge1 - Servidores"
/interface ethernet
set [ find default-name=ether1 ] comment="porta livre" name="ether1 - LIVRE"
set [ find default-name=ether2 ] comment="Huawei NE8000  gerencia" name=\
    "ether2 - NE8000 Gerencia"
set [ find default-name=ether3 ] comment="HP DL360 G7  cluster Zabbix/Zeus" \
    disabled=yes name="ether3 - Proxmox Zabbix"
set [ find default-name=ether4 ] comment="Dell R720  HubSoft + Radius" \
    disabled=yes name="ether4 - Proxmox HubSoft"
set [ find default-name=ether5 ] comment=\
    "uplink RB3011 ether10 + IP 177.72.104.19/27" name=\
    "ether5 - Uplink GW Servidores"
/interface wireguard
add comment="VPN mgmt condominio 10.99.0.0/24 UDP 51820" listen-port=51820 \
    mtu=1420 name=wg-mgmt
add comment="VPN usuarios 10.150.150.0/24 UDP 13231" listen-port=13231 mtu=\
    1380 name=wireguard1
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
/user group
add name=dude policy="local,ftp,read,winbox,!telnet,!ssh,!reboot,!write,!polic\
    y,!test,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api"
/interface bridge port
add bridge="bridge1 - Servidores" interface="ether1 - LIVRE"
add bridge="bridge1 - Servidores" interface="ether2 - NE8000 Gerencia"
add bridge="bridge1 - Servidores" interface="ether3 - Proxmox Zabbix"
add bridge="bridge1 - Servidores" interface="ether4 - Proxmox HubSoft"
add bridge="bridge1 - Servidores" interface="ether5 - Uplink GW Servidores"
/ip firewall connection tracking
set udp-timeout=5m
/ipv6 settings
set disable-ipv6=yes forward=no
/interface l2tp-server server
set enabled=yes
/interface ovpn-server server
add auth=sha1 certificate=SERVIDOR cipher=aes256-cbc disabled=no mac-address=\
    FE:15:E6:A1:59:3D name=ovpn-server1 require-client-certificate=yes
/interface wireguard peers
add allowed-address=10.150.150.2/32 comment=Leonardo interface=wireguard1 \
    name=peer1 persistent-keepalive=25s public-key=\
    "mvWRWGlj3cdrBewImwq8niCkCNbspk83tmRz8uUAdV4=" responder=yes
add allowed-address=10.150.150.4/32 comment="LEONARDO PC CASA" interface=\
    wireguard1 name=peer3 persistent-keepalive=25s public-key=\
    "dNj+KsZHildrXFRzYetyIgfgAoxl2W9jD833w4Ct0wM=" responder=yes
add allowed-address=10.150.150.5/32 comment="LEONARDO IPHONE" interface=\
    wireguard1 name=peer6 persistent-keepalive=25s public-key=\
    "WBlUhzu0h2ks7BrBwqnrvVVQvlHeBBmFQmCmP965Ry0=" responder=yes
add allowed-address=10.150.150.6/32 comment=Bruno interface=wireguard1 name=\
    peer7 persistent-keepalive=25s public-key=\
    "7RVka3AiZau5m8GTPCgCEHa/qxBOcZGbKpck6lYMX1I=" responder=yes
add allowed-address=10.150.150.7/32 comment=Leonardo interface=wireguard1 \
    name=peer8 persistent-keepalive=25s public-key=\
    "TE3+JnrHqE2COG25ALf1cnNd/vtsv3NQf0XzjMALJ3Q=" responder=yes
add allowed-address=10.150.150.8/32 comment="PC Regis" interface=wireguard1 \
    name=peer9 persistent-keepalive=25s public-key=\
    "mJXUlsvpDbbzU8OCVPDEId5pi3LQc7mncflLpiIQAwM=" responder=yes
add allowed-address=10.150.150.9/32 comment=Luann disabled=yes interface=\
    wireguard1 name=peer10 public-key=\
    "f8VD4aaXdm3UIu8Ilu86J0ekOQs3Mmq6WjoVm2CTYi4=" responder=yes
add allowed-address=10.150.150.10/32 comment=Sabrina interface=wireguard1 \
    name=peer11 persistent-keepalive=25s public-key=\
    "XHuVoEwRvfLVTrmZWunL7XQyYlJ7xt/eem6mr/rjc2Q=" responder=yes
add allowed-address=10.150.150.11/32 comment=Isaac interface=wireguard1 name=\
    peer12 persistent-keepalive=25s public-key=\
    "xcV6lJ9utyfR0KQfoAwtnkBKcfiPH1enTe0W7kID1F8=" responder=yes
add allowed-address=10.150.150.12/32 comment="Bruno MAC" interface=wireguard1 \
    name=peer13 persistent-keepalive=25s public-key=\
    "aqNrOCyI4qZtFUTNnLa9UK4t4aUGlgAivhh6tRtN8ws=" responder=yes
add allowed-address=10.150.150.13/32 comment="Bruno MAC Win" interface=\
    wireguard1 name=peer14 persistent-keepalive=25s public-key=\
    "IkCxksry5x5oXRLBoMvGm61xV7vruz/QM6eBxs0A/R4=" responder=yes
add allowed-address=10.150.150.3/32 comment=Leonardo2 interface=wireguard1 \
    name=peer17 persistent-keepalive=25s public-key=\
    "gvJUF7JxK+EsOExHQc28G4oN6ArOJHr1oFVCDDDgnUk=" responder=yes
add allowed-address=10.150.150.15/32 comment="RB RODEIO TVR" disabled=yes \
    endpoint-port=13231 interface=wireguard1 name=peer19 \
    persistent-keepalive=25s public-key=\
    "cT3nbbXuTTpDULU7o8cbhPk5QnWLjCVOzRIaRwkZE0E=" responder=yes
add allowed-address=10.150.150.14/32 comment="Sabrina iPad" interface=\
    wireguard1 name=peer20 persistent-keepalive=25s public-key=\
    "cPXBqeHLl1tuGiCedOXQQGwkW8E3fPOBmKhODCgx/kU=" responder=yes
add allowed-address=10.150.150.16/32 comment=AUTOBRAP endpoint-port=13231 \
    interface=wireguard1 name=peer21 persistent-keepalive=25s public-key=\
    "3c42hV+e49C3DKNNdECd+gI7M6YzonGqcuJo9WIFaEY=" responder=yes
add allowed-address=10.150.150.17/32 comment="Bruno Home" interface=\
    wireguard1 name=peer22 persistent-keepalive=25s public-key=\
    "HW4WDQ78ryk1X+W+5JVvloGQPZrN80Hhs5naeKyShjE=" responder=yes
add allowed-address=10.99.0.2/32,10.90.0.0/22 comment="Condominio RARO" \
    interface=wg-mgmt name=peer26 public-key=\
    "2GBneJPnh2VJWcXP7KrvOdtBl4ccLpHGoiFEXtLNvwU="
/ip address
add address=177.72.104.19/27 interface="ether5 - Uplink GW Servidores" \
    network=177.72.104.0
add address=10.150.150.1/24 interface=wireguard1 network=10.150.150.0
add address=10.99.0.1/24 interface=wg-mgmt network=10.99.0.0
/ip dhcp-client
# Interface not active
add interface="ether1 - LIVRE"
/ip dns
set servers=177.72.104.58,8.8.8.8
/ip firewall address-list
add address=10.150.150.0/24 list=NAT
/ip firewall filter
add action=accept chain=forward in-interface=wg-mgmt out-interface=wg-mgmt
add action=drop chain=forward dst-address=10.90.0.0/16 in-interface=!wg-mgmt
add action=accept chain=forward in-interface=wg-mgmt out-interface=wg-mgmt
add action=drop chain=forward dst-address=10.90.0.0/16 in-interface=!wg-mgmt
/ip firewall mangle
add action=change-mss chain=forward comment="WG MSS entrando 1340" \
    in-interface=wireguard1 new-mss=1340 protocol=tcp tcp-flags=syn
add action=change-mss chain=forward comment="WG MSS saindo 1340" new-mss=1340 \
    out-interface=wireguard1 protocol=tcp tcp-flags=syn
/ip firewall nat
add action=src-nat chain=srcnat src-address-list=NAT to-addresses=\
    177.72.104.19
/ip hotspot profile
set [ find default=yes ] html-directory=hotspot
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route
add disabled=no dst-address=0.0.0.0/0 gateway=177.72.104.1 routing-table=main
add disabled=no dst-address=10.8.0.0/24 gateway=177.72.104.9 routing-table=\
    main
add disabled=no dst-address=192.168.40.0/24 gateway=10.150.150.15 \
    routing-table=main
/ip service
set telnet disabled=yes
set www disabled=yes
set ftp port=2122
set winbox address=177.72.104.0/22,177.93.240.0/21,10.150.150.0/24,1.1.1.0/24
set api disabled=yes
set api-ssl disabled=yes
set ssh address=177.72.104.0/22,177.93.240.0/21,10.150.150.0/24,1.1.1.0/24 \
    port=15320
/ip ssh
set forwarding-enabled=both
/ipv6 nd
set [ find default=yes ] advertise-dns=yes
/routing filter rule
add chain=OSPF-OUT rule=\
    "if (dst in 10.99.0.0/24 || dst in 10.90.0.0/16) { reject }"
add chain=OSPF-OUT disabled=no rule=accept
add chain=OSPF-IN disabled=no rule=accept
/routing ospf interface-template
add area=ospf-area-1 auth=md5 auth-id=1 disabled=no interfaces=\
    "ether1 - LIVRE" networks=177.72.104.0/27 type=ptp
add area=ospf-area-1 auth=md5 auth-id=0 disabled=no interfaces=wireguard1 \
    networks=10.150.150.0/24 type=ptp
/system clock
set time-zone-name=America/Sao_Paulo
/system identity
set name=RB750-WIREGUARD
/system logging
add topics=ovpn
/system package update
set channel=long-term
/system scheduler
add interval=1w name=backup_ftp on-event="/system script run backup_ftp" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive \
    start-date=2019-12-17 start-time=12:00:00
/system script
add dont-require-permissions=yes name=backup_ftp owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    log warning \"***************************************\"\r\
    \n# Conex\E3o FTP\r\
    \n:global host 177.72.104.131\r\
    \n:global usuario mkbkp\r\
    \n:global senha mkbkp123\r\
    \n# Pega o nome do Router\r\
    \n:global identifica [/system identity get name ];\r\
    \n:global diretorio /Mikrotik\r\
    \n# Gera data no formato AAAA-MM-DD\r\
    \n:global data [/system clock get date]\r\
    \n:global meses (\"jan\",\"feb\",\"mar\",\"apr\",\"may\",\"jun\",\"jul\",\
    \"aug\",\"sep\",\"oct\",\"nov\",\"dec\");\r\
    \n:global ano ([:pick \$data 7 11])\r\
    \n:global mestxt ([:pick \$data 0 3])\r\
    \n:global mm ([ :find \$meses \$mestxt -1 ] + 1);\r\
    \n:if (\$mm < 10) do={ :set mm (\"0\" . \$mm); }\r\
    \n:global mes ([:pick \$ds 7 11] . \$mm . [:pick \$ds 4 6])\r\
    \n:global dia ([:pick \$data 4 6])\r\
    \n:log info \"Gerando backup: \$identifica-\$ano-\$mes-\$dia.backup\";\r\
    \n/system backup save name=\"\$identifica-\$ano-\$mes-\$dia\";\r\
    \n:log info \"Gerando export: \$identifica-\$ano-\$mes-\$dia.rsc\";\r\
    \n/export file=\"\$identifica-\$ano-\$mes-\$dia\"\r\
    \n:log info \"Processando...\";\r\
    \n:delay 5s\r\
    \n:log info \"Conectando FTP Server...\";\r\
    \n:log info \"Enviando Backup [\$identifica-\$ano-\$mes-\$dia.backup] ...\
    \";\r\
    \n/tool fetch address=\$host src-path=\"\$identifica-\$ano-\$mes-\$dia.bac\
    kup\" user=\"\$usuario\" password=\"\$senha\" port=21 upload=yes mode=ftp \
    dst-path=\"\$diretorio/\$identifica-\$ano-\$mes-\$dia.backup\"\r\
    \n:log info \"Enviando Export [\$identifica-\$ano-\$mes-\$dia.rsc] ...\";\
    \r\
    \n/tool fetch address=\$host src-path=\"\$identifica-\$ano-\$mes-\$dia.rsc\
    \" user=\"\$usuario\" password=\"\$senha\" port=21 upload=yes mode=ftp dst\
    -path=\"\$diretorio/\$identifica-\$ano-\$mes-\$dia.rsc\"\r\
    \n:delay 1\r\
    \n:log info \"Backup enviado com sucesso...\";\r\
    \n:log info \"Removendo arquivos .backup\";\r\
    \n:foreach i in=[/file find] do={:if ([:typeof [:find [/file get \$i name]\
    \_\".backup\"]]!=\"nil\") do={/file remove \$i}}\r\
    \n:log info \"Removendo arquivos .rsc\";\r\
    \n:foreach i in=[/file find] do={:if ([:typeof [:find [/file get \$i name]\
    \_\".rsc\"]]!=\"nil\") do={/file remove \$i}}\r\
    \n:log info \"Rotina de backup finalizada...\";\r\
    \n:log warning \"***************************************\";"
/tool sniffer
set filter-interface="ether5 - Uplink GW Servidores" \
    filter-operator-between-entries=and filter-src-mac-address=\
    84:2B:2B:5A:45:55/FF:FF:FF:FF:FF:FF memory-scroll=no
