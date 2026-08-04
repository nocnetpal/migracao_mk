# aug/04/2026 12:00:00 by RouterOS 6.49
# software id = 3EAX-1ULF
#
# model = RB3011UiAS
# serial number = B88D0B6BA720
/interface bridge
add fast-forward=no name="Bridge IP Publico" protocol-mode=none
add name=EOIP-NOC
add fast-forward=no name=loopNETPAL
add fast-forward=no mtu=1500 name=loopback protocol-mode=none
/interface ethernet
set [ find default-name=ether1 ] arp=proxy-arp comment=ESTRAGADA speed=\
    100Mbps
set [ find default-name=ether2 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether3 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether4 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether5 ] comment=ESTRAGADA
set [ find default-name=ether6 ] comment=\
    "RB2011: TS SIX, CGNAT-1 mgmt, Dude, RRFlow, Regua" name=\
    "ether6 - RB2011 Bridge Servidores" speed=100Mbps
set [ find default-name=ether7 ] comment=\
    "Dell R420  gerencia 192.168.116.122/30" name=\
    "ether7 - Proxmox Docker CDNTV" speed=100Mbps
set [ find default-name=ether8 ] auto-negotiation=no comment=\
    "HP 360 G7  gerencia 192.168.115.138/30" full-duplex=no name=\
    "ether8 - Proxmox DNS" speed=100Mbps
set [ find default-name=ether9 ] comment="OLT CPV MGNT" name=\
    "ether9 - Gerencia OLT CPV" speed=100Mbps
set [ find default-name=ether10 ] comment=\
    "RB750: NE8000 mgmt, Proxmox Zabbix, Proxmox HubSoft" name=\
    "ether10 - RB750 Bridge" poe-out=off speed=100Mbps
set [ find default-name=sfp1 ] comment="UPLINK SW TOPO DO RACK" name=\
    "sfp1 - UPLINK SW TOPO DO RACK"
/interface eoip
add allow-fast-path=no local-address=177.72.104.1 mac-address=\
    02:E8:EE:CE:C9:4C mtu=1500 name=eoip-tunnel1 remote-address=\
    177.93.244.165 tunnel-id=1212
/interface vlan
add comment="SERVIDOR DNS RECURSIVO" interface="ether8 - Proxmox DNS" name=\
    VLAN10 vlan-id=10
add interface=eoip-tunnel1 name=VLAN11_eoip vlan-id=11
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN13 - DUDE" vlan-id=13
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN15 - NTP SERVER" \
    vlan-id=15
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN16 - IP PUBLICO" \
    vlan-id=16
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN17 - MONSTA" vlan-id=\
    17
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN18 - SERVERINO" \
    vlan-id=18
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN21 - GERENCIA - GGV" \
    vlan-id=21
add comment=PWW interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN22 - PWW" \
    vlan-id=22
add comment=CPV interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN25 - CPV" \
    vlan-id=25
add comment=FSB interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN26" \
    vlan-id=26
add interface="VLAN22 - PWW" name="VLAN27 - SW FO Shopping" vlan-id=27
add interface="VLAN25 - CPV" name="VLAN30 - Gerencia Radios CPV" vlan-id=30
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN31 GGV" vlan-id=31
add comment=BCP interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN33 - BCP" \
    vlan-id=33
add comment=FSB interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN35 - FSB" \
    vlan-id=35
add comment="OLT BCP" interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN37 - OLT BCP" vlan-id=37
add comment=LBCP interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN39 - LBCP" vlan-id=39
add comment=PSLD interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN40 - PSLD" vlan-id=40
add comment=CCB interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN41 - CCB" \
    vlan-id=41
add comment=CASCA interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN42 - CASCA" \
    vlan-id=42
add comment=MST interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN43 - MST" \
    vlan-id=43
add comment=SLD interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN44 - SLD" \
    vlan-id=44
add comment=TVR interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN46 - TVR" \
    vlan-id=46
add comment="PRAIA MST" interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN47 - PRAIA MST" vlan-id=47
add comment="PRAIA SAO SIMAO" interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN48 - PRAIA SAO SIMAO" vlan-id=48
add interface="VLAN43 - MST" name="VLAN49 - Clientes IP Publico MST" vlan-id=\
    49
add interface="VLAN46 - TVR" name="VLAN50 - GERENCIA TVR" vlan-id=50
add interface="VLAN25 - CPV" name="VLAN51 - Cliente IP Publico CPV" vlan-id=\
    51
add interface="VLAN22 - PWW" name="VLAN52 - Clientes IP Publico PWW" vlan-id=\
    52
add interface="VLAN37 - OLT BCP" name="VLAN53 - Galeria Krupp" vlan-id=53
add interface="VLAN43 - MST" name="VLAN54 - Marcos Solon" vlan-id=54
add interface="VLAN22 - PWW" name="VLAN90 - RB Bridge Consepro PWW" vlan-id=\
    90
add interface="VLAN22 - PWW" name="VLAN92 - Bridge CC PWW" vlan-id=92
add interface="VLAN25 - CPV" name=\
    "VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" vlan-id=93
add interface="VLAN25 - CPV" name="VLAN196 - RB Banco do Brasil CPV" vlan-id=\
    196
add interface="VLAN25 - CPV" name="VLAN200 - RB Brigde Predio Maicon" \
    vlan-id=200
add interface="VLAN43 - MST" name="VLAN250 - Gerencia OLT MST" vlan-id=250
add comment="GERENCIA OLT LBCP" interface="VLAN39 - LBCP" name=VLAN539 \
    vlan-id=539
add interface="VLAN33 - BCP" name="VLAN708 - MK POP Serraria" vlan-id=708
add interface="VLAN33 - BCP" name="VLAN712 - MK POP Casca" vlan-id=712
add interface="VLAN44 - SLD" name="VLAN713 - GW SOLIDAO" vlan-id=713
add interface="VLAN43 - MST" name="VLAN718 - MK POP Valim" vlan-id=718
add interface="VLAN43 - MST" name="VLAN719 - MK POP Pantano" vlan-id=719
add interface="VLAN43 - MST" name="VLAN720 - MK POP Povos" vlan-id=720
add interface="VLAN35 - FSB" name="VLAN721 - MK POP Faz. Cardoso" vlan-id=721
add interface="VLAN35 - FSB" name="VLAN731 - MK POP Cavalhada" vlan-id=731
add interface="VLAN33 - BCP" name="VLAN738 - MK POP Solidao 101" vlan-id=738
add interface="VLAN43 - MST" name="VLAN742 - MK POP TAN" vlan-id=742
add interface="VLAN33 - BCP" name="VLAN753 - MK POP Bacupari" vlan-id=753
add interface="VLAN33 - BCP" name="VLAN765 - Serraria => BCP" vlan-id=765
add interface="VLAN43 - MST" name="VLAN770 - MK POP TAN" vlan-id=770
add interface="VLAN43 - MST" name="VLAN772 - MK POP Tio Joca" vlan-id=772
add interface="VLAN33 - BCP" name="VLAN775 - MK POP Aguape" vlan-id=775
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN1066 - GERADOR MST" \
    vlan-id=1066
add interface="VLAN43 - MST" name="VLAN2020 - Gerencia EDD MST" vlan-id=2020
add interface="VLAN46 - TVR" name="VLAN - 600 - AP_CENTRO_TVR_REI_DOS_PAMPAS" \
    vlan-id=600
add interface=VLAN26 name="VLAN 35 GERENCIA OLT FSB" vlan-id=35
add comment="OLT ZTE GGV" interface="VLAN31 GGV" name="VLAN21 - OLT ZTE GGV" \
    vlan-id=21
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=POOLESCRITORIOBCP ranges=192.168.122.10-192.168.122.39
add name=POOLESCRITORIOMST ranges=192.168.122.66-192.168.122.85
add name="POOLESCRITORIO PWW" ranges=192.168.122.110-192.168.122.120
add name="DHCP SUPORTE PWW" ranges=192.168.122.142-192.168.122.189
add name=ovpn-pool ranges=192.168.77.50-192.168.77.254
add name=dhcp_pool5 ranges=192.168.25.2-192.168.25.6
add name=dhcp_pool6 ranges=192.168.66.2-192.168.66.14
add name=dhcp_pool7 ranges=192.168.66.2-192.168.66.14
add name=dhcp_pool8 ranges=192.168.90.2-192.168.90.254
add name=dhcp_pool9 ranges=192.168.66.2-192.168.66.14
/ip dhcp-server
add address-pool=dhcp_pool8 disabled=no interface="VLAN1066 - GERADOR MST" \
    name=dhcp1
# DHCP server can not run on slave interface!
add address-pool=dhcp_pool9 disabled=no interface=\
    "ether6 - RB2011 Bridge Servidores" name=dhcp2
/ppp profile
set *0 change-tcp-mss=no only-one=no use-compression=no use-encryption=no \
    use-mpls=no use-upnp=no
set *FFFFFFFE only-one=no use-compression=no use-encryption=no use-mpls=no
/queue type
set 0 kind=sfq
set 1 kind=sfq
set 9 kind=sfq
/routing bgp instance
set default as=52828
/routing ospf area
add area-id=0.0.0.1 name=area1
/routing ospf instance
set [ find default=yes ] redistribute-connected=as-type-1 \
    redistribute-static=as-type-1 router-id=172.16.200.5
/snmp community
set [ find default=yes ] addresses=0.0.0.0/0 name=netpaltelecom
/system logging action
add name=logacesso remote=192.168.124.2 target=remote
/user group
set full policy="local,telnet,ssh,ftp,reboot,read,write,policy,test,winbox,pas\
    sword,web,sniff,sensitive,api,romon,dude,tikapp"
/interface bridge port
add bridge="Bridge IP Publico" interface=ether2
add bridge="Bridge IP Publico" interface="ether10 - RB750 Bridge"
add bridge="Bridge IP Publico" interface=ether4
add bridge="Bridge IP Publico" interface=ether1
add bridge="Bridge IP Publico" interface="ether7 - Proxmox Docker CDNTV"
add bridge="Bridge IP Publico" interface="VLAN16 - IP PUBLICO"
add bridge="Bridge IP Publico" interface="ether8 - Proxmox DNS"
add bridge="Bridge IP Publico" interface="ether6 - RB2011 Bridge Servidores"
/interface bridge settings
set allow-fast-path=no
/ip neighbor discovery-settings
set discover-interface-list=all
/ip settings
set tcp-syncookies=yes
/interface l2tp-server server
set authentication=chap,mschap1,mschap2 enabled=yes ipsec-secret=ntp1030
/interface ovpn-server server
set auth=sha1 certificate=server cipher=aes256 default-profile=\
    default-encryption enabled=yes require-client-certificate=yes
/interface pptp-server server
set authentication=pap,chap,mschap1,mschap2 max-mru=1480 max-mtu=1480
/ip address
add address=172.16.200.5 comment=LOOPBACK interface=loopback network=\
    172.16.200.5
add address=192.168.123.13/30 comment="GERENCIA SERVIDOR VOIP CPV" interface=\
    "ether7 - Proxmox Docker CDNTV" network=192.168.123.12
add address=192.168.116.34/30 comment="GERENCIA LOCAL" interface=\
    "sfp1 - UPLINK SW TOPO DO RACK" network=192.168.116.32
add address=177.72.104.1/27 comment="IP PUBLICO" interface=\
    "Bridge IP Publico" network=177.72.104.0
add address=192.168.116.29/30 comment="GERENCIA THE DUDE" interface=\
    "Bridge IP Publico" network=192.168.116.28
add address=192.168.123.21/30 comment="GERENCIA SERVIDOR VOIP BCP BACKUP" \
    interface="Bridge IP Publico" network=192.168.123.20
add address=192.168.115.61/30 comment="GERENCIA SERVIDOR MONSTA" interface=\
    "Bridge IP Publico" network=192.168.115.60
add address=192.168.115.41/30 comment="GERENCIA OLT ZTE CPV" interface=\
    "ether9 - Gerencia OLT CPV" network=192.168.115.40
add address=177.72.104.53/30 comment="GERENCIA HUAWEI" interface=\
    "sfp1 - UPLINK SW TOPO DO RACK" network=177.72.104.52
add address=192.168.115.101/30 comment="REGUA VOLT" interface=ether1 network=\
    192.168.115.100
add address=192.168.116.9/30 comment="GERENCIA NTP SERVE" interface=\
    "VLAN15 - NTP SERVER" network=192.168.116.8
add address=192.168.116.17/30 comment="GERENCIA LIBRENMS" interface=\
    "Bridge IP Publico" network=192.168.116.16
add address=192.168.116.37/30 comment="GERENCIA WIKI 2 " interface=\
    "Bridge IP Publico" network=192.168.116.36
add address=192.168.123.1/30 comment="GERENCIA DNS BACKUP" interface=\
    "Bridge IP Publico" network=192.168.123.0
add address=192.168.116.45/30 comment="GERENCIA WIKI" interface=\
    "Bridge IP Publico" network=192.168.116.44
add address=192.168.115.209/30 comment="GERENCIA PROXMOXHUB" interface=\
    "Bridge IP Publico" network=192.168.115.208
add address=192.168.115.213/30 comment="GERENCIA RADIUS HUBSOFT" interface=\
    "Bridge IP Publico" network=192.168.115.212
add address=192.168.123.9/30 comment="GERENCIA SERVIDOR GRAYLOG" interface=\
    "Bridge IP Publico" network=192.168.123.8
add address=192.168.116.121/30 comment="GERENCIA PROXMOX DOCKER - CDNTV" \
    interface="Bridge IP Publico" network=192.168.116.120
add address=192.168.15.73/30 comment=MONSTA interface="VLAN18 - SERVERINO" \
    network=192.168.15.72
add address=192.168.115.97/30 comment="SERVIDOR TS CALLCENTER" interface=\
    "Bridge IP Publico" network=192.168.115.96
add address=192.168.31.49/29 comment="JDF => Rancho Velho" interface=\
    "VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" network=192.168.31.48
add address=192.168.31.41/29 comment="Aguape  => Bacupari" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.31.40
add address=192.168.31.17/29 comment="Casca => Bacupari" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.31.16
add address=192.168.31.9/29 comment="Faz. Nova => Bacupari" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.31.8
add address=192.168.30.201/29 comment="M Quiteria => Casca" interface=\
    "VLAN712 - MK POP Casca" network=192.168.30.200
add address=192.168.30.193/29 comment="Abelha => Solidao 101" interface=\
    "VLAN738 - MK POP Solidao 101" network=192.168.30.192
add address=192.168.30.177/29 comment="Rodrigo => Solidao" interface=\
    "VLAN775 - MK POP Aguape" network=192.168.30.176
add address=192.168.30.161/29 comment="Serraria => FSB" interface=\
    "VLAN765 - Serraria => BCP" network=192.168.30.160
add address=192.168.30.153/29 comment="Solidao => Aguape" interface=\
    "VLAN775 - MK POP Aguape" network=192.168.30.152
add address=192.168.30.113/29 comment="Faz. Cardoso => Cavalhada" interface=\
    "VLAN731 - MK POP Cavalhada" network=192.168.30.112
add address=192.168.30.81/29 comment="Serraria => Faz. Cardoso" interface=\
    "VLAN721 - MK POP Faz. Cardoso" network=192.168.30.80
add address=192.168.30.73/29 comment="Pantano => Valim" interface=\
    "VLAN718 - MK POP Valim" network=192.168.30.72
add address=192.168.30.49/29 comment="Bacupari => Solidao 101" interface=\
    "VLAN738 - MK POP Solidao 101" network=192.168.30.48
add address=192.168.15.85/30 comment="SW Shopping" interface=\
    "VLAN52 - Clientes IP Publico PWW" network=192.168.15.84
add address=192.168.15.81/30 comment="SW4370 Solidao" interface=\
    "VLAN44 - SLD" network=192.168.15.80
add address=192.168.15.29/30 comment="S4370 Praia Solidao" interface=\
    "VLAN40 - PSLD" network=192.168.15.28
add address=192.168.15.61/30 comment="S5735 Lagoa do Bacupari" interface=\
    "VLAN39 - LBCP" network=192.168.15.60
add address=192.168.15.89/30 comment="CEEE Shopping" interface=\
    "VLAN52 - Clientes IP Publico PWW" network=192.168.15.88
add address=192.168.17.1/30 comment="SW Aguape" interface=\
    "VLAN775 - MK POP Aguape" network=192.168.17.0
add address=192.168.17.5/30 comment="SW Povos" interface=\
    "VLAN720 - MK POP Povos" network=192.168.17.4
add address=192.168.17.9/30 comment="SW Pantano" interface=\
    "VLAN719 - MK POP Pantano" network=192.168.17.8
add address=192.168.17.17/30 comment="SW Serraria" interface=\
    "VLAN708 - MK POP Serraria" network=192.168.17.16
add address=192.168.17.21/30 comment="SW Bacupari" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.17.20
add address=192.168.17.25/30 comment="SW Bacupari" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.17.24
add address=192.168.30.145/29 comment="CEEE BCP Fase 1" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.30.144
add address=192.168.22.1/27 comment=GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO \
    interface="VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" network=\
    192.168.22.0
add address=192.168.115.105/30 comment="OLT Solidão" interface=\
    "VLAN44 - SLD" network=192.168.115.104
add address=192.168.115.233/30 comment="Gerencia OLT Praia Solidão" \
    interface="VLAN40 - PSLD" network=192.168.115.232
add address=192.168.115.229/30 comment="Gerencia OLT Lagoa do Bacupari" \
    interface="VLAN39 - LBCP" network=192.168.115.228
add address=192.168.115.205/30 comment="RB Bridge Consepro PWW" interface=\
    "VLAN90 - RB Bridge Consepro PWW" network=192.168.115.204
add address=192.168.115.65/30 comment="RB Banco do Brasil PWW" interface=\
    "VLAN52 - Clientes IP Publico PWW" network=192.168.115.64
add address=192.168.116.113/29 comment="CEEE Bridge Predio Maicon 2" \
    interface="VLAN200 - RB Brigde Predio Maicon" network=192.168.116.112
add address=192.168.115.85/30 comment="RB Banco do Brasil CPV" interface=\
    "VLAN196 - RB Banco do Brasil CPV" network=192.168.115.84
add address=192.168.116.149/30 comment="CRS Escritório" interface=\
    "VLAN54 - Marcos Solon" network=192.168.116.148
add address=192.168.116.153/30 comment="RB  CASA -  Marcos Solon" interface=\
    "VLAN54 - Marcos Solon" network=192.168.116.152
add address=192.168.115.5/30 comment="RB Brigde Predio Maicon" interface=\
    "VLAN200 - RB Brigde Predio Maicon" network=192.168.115.4
add address=192.168.115.245/30 comment="Gerencia OLT PLSD" interface=\
    "VLAN40 - PSLD" network=192.168.115.244
add address=192.168.23.89/29 comment="CEEE FSB" interface="VLAN35 - FSB" \
    network=192.168.23.88
add address=192.168.115.225/30 comment="Gerencia OLT BCP" interface=\
    "VLAN37 - OLT BCP" network=192.168.115.224
add address=192.168.115.237/30 comment="OLTGerencia OLT CCB" interface=\
    "VLAN41 - CCB" network=192.168.115.236
add address=192.168.116.157/30 comment="Gerencia EDD TIM MST" interface=\
    "VLAN2020 - Gerencia EDD MST" network=192.168.116.156
add address=192.168.115.17/30 comment="Gerencia OLT CASCA" interface=\
    "VLAN42 - CASCA" network=192.168.115.16
add address=192.168.115.141/30 comment="Gerencia OLT PWW" interface=\
    "VLAN52 - Clientes IP Publico PWW" network=192.168.115.140
add address=192.168.115.125/30 comment="Gerencia OLT GGV" interface=\
    "VLAN21 - OLT ZTE GGV" network=192.168.115.124
add address=192.168.30.25/29 comment="ENLACE JESUELO DA SILVA" interface=\
    "VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" network=192.168.30.24
add address=172.31.254.33/30 comment="GW POP SOLIDAO" interface=\
    "VLAN713 - GW SOLIDAO" network=172.31.254.32
add address=192.168.116.177/29 comment=GERENCIA_NETPAL_JDF_CYMI interface=\
    "VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" network=192.168.116.176
add address=192.168.16.1/27 comment="REDE RODEIO" interface=\
    "VLAN - 600 - AP_CENTRO_TVR_REI_DOS_PAMPAS" network=192.168.16.0
add address=192.168.115.53/30 comment="Gerencia OLT FSB" interface=\
    "VLAN 35 GERENCIA OLT FSB" network=192.168.115.52
add address=192.168.115.169/30 comment="Gerencia OLT MST" interface=\
    "VLAN43 - MST" network=192.168.115.168
add address=192.168.115.241/30 comment="SW FO Shopping" interface=\
    "VLAN27 - SW FO Shopping" network=192.168.115.240
add address=192.168.15.93/30 comment="Gerencia SW Jardim Formoso" interface=\
    "VLAN30 - Gerencia Radios CPV" network=192.168.15.92
add address=192.168.6.1/24 comment="Gerencia Radios CPV CRS JDF" interface=\
    "VLAN30 - Gerencia Radios CPV" network=192.168.6.0
add address=192.168.115.9/30 comment="Gerencia OLT PWW Nova" interface=\
    "VLAN22 - PWW" network=192.168.115.8
add address=192.168.115.81/30 comment="RB Bridge Banco do Brasil MST" \
    interface="VLAN49 - Clientes IP Publico MST" network=192.168.115.80
add address=192.168.116.209/28 comment="CRS - PWW" interface=\
    "VLAN52 - Clientes IP Publico PWW" network=192.168.116.208
add address=192.168.17.37/30 comment="DUDE VLSUL" interface=\
    "Bridge IP Publico" network=192.168.17.36
add address=192.168.66.1/28 comment="DHCP PC SIX" interface=\
    "ether6 - RB2011 Bridge Servidores" network=192.168.66.0
add address=192.168.116.5/30 comment="GERENCIA PROXMOX PNETLAB" interface=\
    "Bridge IP Publico" network=192.168.116.4
add address=192.168.116.25/30 comment="ROTEADOR PRINCIPAL PNETLAB" interface=\
    "Bridge IP Publico" network=192.168.116.24
add address=192.168.17.41/30 comment="DUDE PMCPV" interface=\
    "Bridge IP Publico" network=192.168.17.40
add address=192.168.15.45/30 comment="Gerencia SW Praia MST" interface=\
    "VLAN47 - PRAIA MST" network=192.168.15.44
add address=192.168.115.173/30 comment="Gerencia OLT Praia MST" interface=\
    "VLAN47 - PRAIA MST" network=192.168.115.172
add address=192.168.15.49/30 comment="GERENCIA SW DATACOM" interface=\
    VLAN11_eoip network=192.168.15.48
add address=192.168.22.49/28 comment="GATEWAY LAGOA DO BACUPARI" interface=\
    "VLAN39 - LBCP" network=192.168.22.48
add address=192.168.17.45/30 comment="DUDE PMMST" interface=\
    "Bridge IP Publico" network=192.168.17.44
add address=192.168.15.53/30 comment="GERENCIA SW PRAIA SAO SIMAO" interface=\
    "VLAN48 - PRAIA SAO SIMAO" network=192.168.15.52
add address=192.168.115.181/30 comment="GERENCIA OLT PRAIA SAO SIMAO" \
    interface="VLAN48 - PRAIA SAO SIMAO" network=192.168.115.180
add address=172.31.254.29/30 comment="GW Praia MST" interface=\
    "VLAN47 - PRAIA MST" network=172.31.254.28
add address=192.168.15.253/30 comment="VLAN 46 GERENCIA TVR" interface=\
    "VLAN50 - GERENCIA TVR" network=192.168.15.252
add address=177.72.104.61/30 disabled=yes network=177.72.104.60
add address=192.168.116.21/30 comment="RB BRIDGE SERVIDORES" interface=\
    "Bridge IP Publico" network=192.168.116.20
add address=192.168.115.21/30 comment="GERENCIA PROXMOX VOIP" interface=\
    "Bridge IP Publico" network=192.168.115.20
add address=192.168.115.137/30 comment="GERENCIA PROXMOX DNS" interface=\
    "Bridge IP Publico" network=192.168.115.136
add address=10.200.255.253/30 comment="SERVIDOR DE DNS RECURSIVO" interface=\
    VLAN10 network=10.200.255.252
add address=192.168.115.177/30 interface=VLAN539 network=192.168.115.176
add address=192.168.116.197/30 comment="SW TVR" interface="VLAN46 - TVR" \
    network=192.168.116.196
add address=192.168.31.33/29 comment="Bacupari  => Serraria" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.31.32
add address=192.168.90.1/24 interface="VLAN1066 - GERADOR MST" network=\
    192.168.90.0
/ip dhcp-server network
add address=192.168.66.0/28 gateway=192.168.66.1
add address=192.168.90.0/24 dns-server=9.9.9.9,8.8.8.8 gateway=192.168.90.1
/ip dns
set cache-size=512000KiB servers=9.9.9.9,8.8.8.8
/ip dns static
add address=177.72.104.7 name=financeiro.netpal.com.br
add address=192.168.123.14 name=painel.netpal.com.br
/interface bridge port
add bridge="Bridge IP Publico" interface=ether2
add bridge="Bridge IP Publico" interface="ether10 - RB750 Bridge"
add bridge="Bridge IP Publico" interface=ether4
add bridge="Bridge IP Publico" interface=ether1
add bridge="Bridge IP Publico" interface="ether7 - Proxmox Docker CDNTV"
add bridge="Bridge IP Publico" interface="VLAN16 - IP PUBLICO"
add bridge="Bridge IP Publico" interface="ether8 - Proxmox DNS"
add bridge="Bridge IP Publico" interface="ether6 - RB2011 Bridge Servidores"