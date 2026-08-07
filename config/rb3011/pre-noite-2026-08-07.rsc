# aug/07/2026 16:52:31 by RouterOS 6.49
# software id = 3EAX-1ULF
#
# model = RB3011UiAS
# serial number = B88D0B6BA720
/interface bridge
add fast-forward=no name="Bridge IP Publico" protocol-mode=none
add name=EOIP-NOC
add comment="Etapa1 VLAN100 gerencia + VLAN16 publico" name=bridge-servidores \
    protocol-mode=none vlan-filtering=yes
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
set [ find default-name=ether8 ] comment=\
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
add comment=FSB interface="sfp1 - UPLINK SW TOPO DO RACK" name=VLAN26 \
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
add comment=CASCA interface="sfp1 - UPLINK SW TOPO DO RACK" name=\
    "VLAN42 - CASCA" vlan-id=42
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
add comment="IP PUBLICO tagged dos servidores" interface=bridge-servidores \
    name=vlan16-servidores vlan-id=16
add comment="GERENCIA SERVIDORES 192.168.254.0/24" interface=\
    bridge-servidores name=vlan100-servidores vlan-id=100
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
add bridge="Bridge IP Publico" interface="VLAN16 - IP PUBLICO"
add bridge="Bridge IP Publico" interface="ether6 - RB2011 Bridge Servidores"
add bridge="Bridge IP Publico" interface=vlan16-servidores
add bridge=bridge-servidores interface="ether7 - Proxmox Docker CDNTV" pvid=\
    100
add bridge=bridge-servidores interface="ether8 - Proxmox DNS" pvid=100
/interface bridge settings
set allow-fast-path=no
/ip neighbor discovery-settings
set discover-interface-list=all
/ip settings
set tcp-syncookies=yes
/interface bridge vlan
add bridge=bridge-servidores tagged=bridge-servidores untagged=\
    "ether7 - Proxmox Docker CDNTV,ether8 - Proxmox DNS" vlan-ids=100
add bridge=bridge-servidores tagged=\
    "bridge-servidores,ether7 - Proxmox Docker CDNTV,ether8 - Proxmox DNS" \
    vlan-ids=16
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
    vlan100-servidores network=192.168.115.60
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
    vlan100-servidores network=192.168.115.212
add address=192.168.123.9/30 comment="GERENCIA SERVIDOR GRAYLOG" interface=\
    "Bridge IP Publico" network=192.168.123.8
add address=192.168.116.121/30 comment="GERENCIA PROXMOX DOCKER - CDNTV" \
    interface=vlan100-servidores network=192.168.116.120
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
add address=192.168.115.105/30 comment="OLT Solid\E3o" interface=\
    "VLAN44 - SLD" network=192.168.115.104
add address=192.168.115.233/30 comment="Gerencia OLT Praia Solid\E3o" \
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
add address=192.168.116.149/30 comment="CRS Escrit\F3rio" interface=\
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
    vlan100-servidores network=192.168.17.36
add address=192.168.66.1/28 comment="DHCP PC SIX" interface=\
    "ether6 - RB2011 Bridge Servidores" network=192.168.66.0
add address=192.168.116.5/30 comment="GERENCIA PROXMOX PNETLAB" interface=\
    "Bridge IP Publico" network=192.168.116.4
add address=192.168.116.25/30 comment="ROTEADOR PRINCIPAL PNETLAB" interface=\
    "Bridge IP Publico" network=192.168.116.24
add address=192.168.17.41/30 comment="DUDE PMCPV" interface=\
    vlan100-servidores network=192.168.17.40
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
add address=192.168.116.21/30 comment="RB BRIDGE SERVIDORES" interface=\
    "Bridge IP Publico" network=192.168.116.20
add address=192.168.115.21/30 comment="GERENCIA PROXMOX VOIP" interface=\
    "Bridge IP Publico" network=192.168.115.20
add address=192.168.115.137/30 comment="GERENCIA PROXMOX DNS" interface=\
    vlan100-servidores network=192.168.115.136
add address=10.200.255.253/30 comment="SERVIDOR DE DNS RECURSIVO" interface=\
    VLAN10 network=10.200.255.252
add address=192.168.115.177/30 interface=VLAN539 network=192.168.115.176
add address=192.168.116.197/30 comment="SW TVR" interface="VLAN46 - TVR" \
    network=192.168.116.196
add address=192.168.31.33/29 comment="Bacupari  => Serraria" interface=\
    "VLAN753 - MK POP Bacupari" network=192.168.31.32
add address=192.168.90.1/24 interface="VLAN1066 - GERADOR MST" network=\
    192.168.90.0
add address=192.168.254.1/24 comment="GW VLAN100 hypervisors" interface=\
    vlan100-servidores network=192.168.254.0
/ip dhcp-server network
add address=192.168.66.0/28 gateway=192.168.66.1
add address=192.168.90.0/24 dns-server=9.9.9.9,8.8.8.8 gateway=192.168.90.1
/ip dns
set cache-size=512000KiB servers=9.9.9.9,8.8.8.8
/ip dns static
add address=177.72.104.7 name=financeiro.netpal.com.br
add address=192.168.123.14 name=painel.netpal.com.br
/ip firewall address-list
add address=65.49.0.0/17 list=UltraSurfServers
add address=204.107.140.0/24 list=UltraSurfServers
add address=177.72.104.0/21 list="REDE LIBERADA"
add address=177.93.240.0/21 list="REDE LIBERADA"
add address=187.60.191.7 list="REDE LIBERADA"
add address=186.215.138.240 list="REDE LIBERADA"
add address=177.101.197.84 list="REDE LIBERADA"
add address=177.1.161.120 list="REDE LIBERADA"
add address=177.1.162.126 list="REDE LIBERADA"
add address=192.168.122.0/24 list="REDE GERENCIA"
add address=177.72.104.0/27 list="REDE GERENCIA"
add address=192.168.10.0/24 list="REDE GERENCIA"
add address=1.1.1.0/24 list="REDE GERENCIA"
add address=172.16.222.0/24 list=NAT
add address=1.1.1.0/24 list=NAT
add address=187.45.202.53 list="REDE LIBERADA"
add address=192.168.123.0/30 list=VOIP
add address=192.168.115.212/30 list=VOIP
add address=192.168.115.12/30 list=VOIP
add address=192.168.122.0/24 list=LAN
add address=192.168.122.0/24 list=VOIP
add address=177.72.104.0/27 list=VOIP
add address=54.82.91.114 list=VOIP
add address=54.94.29.106 list=VOIP
add address=45.58.46.228 list=VOIP
add address=200.215.211.3 list=VOIP
add address=177.72.104.0/24 list=VOIP
add address=192.168.123.4/30 list=VOIP
add address=187.103.111.110 list=VOIP
add address=168.205.252.20 list=VOIP
add address=177.93.240.0/21 list=VOIP
add address=172.16.130.0/24 list=VOIP
add address=172.16.131.0/24 list=VOIP
add address=1.1.1.0/24 list=VOIP
add address=2.2.2.0/24 list=VOIP
add address=661606d0fe4e.sn.mynetname.net list=VOIP
add address=189.74.241.181 list=VOIP
add address=177.72.104.0/21 list=LAN
add address=177.93.240.0/21 list=LAN
add address=177.72.104.0/21 list=VOIP
add address=192.168.122.128/26 list=LAN
add address=192.168.122.0/26 list=LAN
add address=172.16.123.0/30 list=LAN
add address=172.16.123.0/30 list=NAT
add address=192.168.123.12/30 list=NAT
add address=177.128.70.198 list=ESPECTRA
add address=177.204.86.15 list=ESPECTRA
add address=177.204.86.15 list=VOIP
add address=177.128.70.198 list=VOIP
add address=104.219.54.119 list=VOIP
add address=192.168.116.0/30 list=LAN
add address=192.168.200.0/24 list=VOIP
add address=179.184.115.133 list=VOIP
add address=177.93.247.63 list=LAN
add address=sip.nvoxtelecom.com list=VOIP
add address=192.168.81.0/24 list=VOIP
add address=192.168.80.0/24 list=VOIP
add address=192.168.82.0/24 list=VOIP
add address=192.168.83.0/24 list=VOIP
add address=186.230.20.243 list=VOIP
add address=192.168.123.8/30 list=NAT
add address=177.73.6.171 comment="Bruno INB" list=VOIP
add address=177.72.104.0/21 list=RANGENETPAL
add address=177.93.240.0/21 list=RANGENETPAL
add address=192.168.81.0/24 list=RANGENETPAL
add address=192.168.123.12/30 list=SMTP_LIBERADO
add address=177.72.104.1 list=SMTP_LIBERADO
add address=186.215.138.240 list=RANGENETPAL
add address=1.1.1.0/24 list=RANGENETPAL
add address=67d206d2e298.sn.mynetname.net list=VOIP
add address=177.73.3.159 list=VOIP
add address=187.85.111.11 list="REDE GERENCIA"
add address=186.225.212.144 list="REDE GERENCIA"
add address=187.5.224.18 list="REDE GERENCIA"
add address=177.6.21.136/29 list="REDE GERENCIA"
add address=177.6.21.136/29 list=RANGENETPAL
add address=187.5.224.18 list=RANGENETPAL
add address=186.225.212.144 list=RANGENETPAL
add address=187.85.111.11 list=RANGENETPAL
add address=192.168.115.60/30 list=LAN
add address=192.168.115.60/30 list=NAT
add address=192.168.115.60/30 list=VOIP
add address=192.168.115.0/24 list=RANGENETPAL
add address=192.168.115.40/30 list=RANGENETPAL
add address=177.72.104.1 list=VOIP
add address=a.ntp.br list=RANGENETPAL
add address=b.ntp.br list=RANGENETPAL
add address=192.168.15.152/29 list=RANGENETPAL
add address=192.168.123.14 list=FORA_DO_NAT
add address=192.168.115.24/30 list=NAT
add address=amz.smartolt.com list=SmartOLT
add address=192.168.115.40/30 list=NAT
add address=amz.smartolt.com list=RANGENETPAL
add address=192.168.116.18 list=NAT
add address=177.72.104.11 list=DNS_AUTORITATIVO
add address=177.72.104.12 list=DNS_AUTORITATIVO
add address=192.168.115.124/30 list=NAT
add address=172.16.200.5 list=RANGENETPAL
add address=172.31.254.0/24 list=RANGENETPAL
add address=172.30.254.0/24 list=RANGENETPAL
add address=192.168.116.8/30 list=NAT
add address=177.72.104.0/27 list=SERVIDORES_NETPAL
add address=192.168.123.12/30 list=VOIP
add address=177.72.104.10 list=DNS_AUT
add address=177.72.104.11 list=DNS_AUT
add address=177.72.104.54 list=FORA_DO_NAT
add address=192.168.15.16/30 list=RANGENETPAL
add address=192.168.116.16/30 list=RANGENETPAL
add address=192.168.116.36/30 comment=amz.smartolt.com list=RANGENETPAL
add address=192.168.116.36/30 list=NAT
add address=192.168.123.0/30 list=NAT
add address=192.168.123.0/30 list="REDE GERENCIA"
add address=192.168.116.44/30 list=NAT
add address=192.168.115.208/30 list=NAT
add address=192.168.115.212/30 list=NAT_RADIUS
add address=192.168.123.16/30 list=NAT
add address=192.168.123.10 list=FORA_DO_NAT
add address=10.200.255.240 list=RANGENETPAL
add address=18.229.217.195 list=ROUTEMANAGER
add address=18.229.217.195 comment=amz.smartolt.com list=RANGENETPAL
add address=45.174.238.90 comment=amz.smartolt.com list=RANGENETPAL
add address=45.174.238.90 list=ROUTEMANAGER
add address=1.1.1.0/24 list=ROUTEMANAGER
add address=192.168.15.4/30 list=FORA_DO_NAT
add address=177.93.244.165 list=VOIP
add address=177.72.104.0/21 list=FORA_DO_NAT_RADIUS
add address=177.93.240.0/21 list=FORA_DO_NAT_RADIUS
add address=10.200.255.240 list=FORA_DO_NAT_RADIUS
add address=200.182.150.227 list=ESPECTRA
add address=10.140.100.0/24 list=NAT
add address=192.168.116.122 list=NAT
add address=192.168.15.72/30 list=NAT
add address=192.168.116.8/30 list=LAN
add address=192.168.116.9 list=FORA_DO_NAT
add address=192.168.15.72/30 list=RANGENETPAL
add address=5.10.68.168/29 list=BRASIL
add address=5.10.70.152/29 list=BRASIL
add address=5.10.76.232/29 list=BRASIL
add address=5.10.91.56/29 list=BRASIL
add address=5.10.91.64/28 list=BRASIL
add address=5.10.92.236/30 list=BRASIL
add address=5.10.93.80/29 list=BRASIL
add address=5.10.100.72/29 list=BRASIL
add address=5.10.104.176/29 list=BRASIL
add address=5.10.111.28/30 list=BRASIL
add address=5.10.111.40/30 list=BRASIL
add address=5.10.111.248/29 list=BRASIL
add address=5.10.113.224/29 list=BRASIL
add address=5.10.113.240/29 list=BRASIL
add address=5.10.115.200/29 list=BRASIL
add address=5.10.117.0/28 list=BRASIL
add address=5.10.117.24/30 list=BRASIL
add address=5.10.117.40/29 list=BRASIL
add address=5.10.118.0/27 list=BRASIL
add address=5.10.118.192/27 list=BRASIL
add address=5.10.120.136/29 list=BRASIL
add address=5.10.122.104/29 list=BRASIL
add address=5.10.126.224/29 list=BRASIL
add address=5.10.194.0/23 list=BRASIL
add address=5.10.196.0/22 list=BRASIL
add address=5.63.26.0/24 list=BRASIL
add address=5.132.37.0/24 list=BRASIL
add address=5.153.0.248/29 list=BRASIL
add address=5.153.1.136/29 list=BRASIL
add address=5.153.8.104/29 list=BRASIL
add address=5.153.8.176/28 list=BRASIL
add address=5.153.21.192/27 list=BRASIL
add address=5.199.174.192/27 list=BRASIL
add address=5.224.37.0/24 list=BRASIL
add address=5.225.37.0/24 list=BRASIL
add address=15.227.249.0/24 list=BRASIL
add address=31.201.0.24/30 list=BRASIL
add address=31.201.9.0/25 list=BRASIL
add address=31.201.9.128/26 list=BRASIL
add address=31.201.9.192/27 list=BRASIL
add address=32.59.0.222 list=BRASIL
add address=32.59.1.0/25 list=BRASIL
add address=32.104.18.0/24 list=BRASIL
add address=32.105.1.0/24 list=BRASIL
add address=32.105.2.0/23 list=BRASIL
add address=32.105.4.0/22 list=BRASIL
add address=32.105.8.0/23 list=BRASIL
add address=32.105.10.0/24 list=BRASIL
add address=32.105.38.0/23 list=BRASIL
add address=32.105.40.0/22 list=BRASIL
add address=37.58.64.40/29 list=BRASIL
add address=37.58.70.112/29 list=BRASIL
add address=37.58.80.232/29 list=BRASIL
add address=37.58.86.38/31 list=BRASIL
add address=37.58.89.120/29 list=BRASIL
add address=37.58.91.40/29 list=BRASIL
add address=37.58.95.208/29 list=BRASIL
add address=37.58.96.160/30 list=BRASIL
add address=37.58.97.160/29 list=BRASIL
add address=37.58.100.224/29 list=BRASIL
add address=37.58.102.24/29 list=BRASIL
add address=37.58.106.112/29 list=BRASIL
add address=37.58.106.144/29 list=BRASIL
add address=37.58.107.40/29 list=BRASIL
add address=37.58.127.232/29 list=BRASIL
add address=37.222.37.0/24 list=BRASIL
add address=37.223.28.0/24 list=BRASIL
add address=37.252.238.0/23 list=BRASIL
add address=46.36.193.225 list=BRASIL
add address=46.36.193.226/31 list=BRASIL
add address=46.36.193.228/31 list=BRASIL
add address=46.136.173.0/24 list=BRASIL
add address=46.252.177.160/27 list=BRASIL
add address=50.30.36.64/26 list=BRASIL
add address=50.30.36.192/26 list=BRASIL
add address=50.30.37.64/26 list=BRASIL
add address=50.30.39.0/26 list=BRASIL
add address=50.30.39.96/27 list=BRASIL
add address=50.30.39.224/27 list=BRASIL
add address=50.30.40.64/26 list=BRASIL
add address=50.30.40.128/26 list=BRASIL
add address=50.30.40.192/27 list=BRASIL
add address=50.30.44.32/27 list=BRASIL
add address=50.30.44.64/27 list=BRASIL
add address=50.30.44.224/27 list=BRASIL
add address=54.232.0.0/16 list=BRASIL
add address=57.74.0.0/17 list=BRASIL
add address=62.75.203.224/27 list=BRASIL
add address=63.250.139.0/27 list=BRASIL
add address=63.250.139.96/29 list=BRASIL
add address=63.250.140.160/27 list=BRASIL
add address=63.250.142.192/27 list=BRASIL
add address=63.250.143.64/27 list=BRASIL
add address=63.250.180.32/27 list=BRASIL
add address=63.250.182.40/29 list=BRASIL
add address=63.250.185.0/27 list=BRASIL
add address=63.250.185.240/29 list=BRASIL
add address=63.250.188.16/28 list=BRASIL
add address=63.250.188.32/27 list=BRASIL
add address=63.250.188.64/27 list=BRASIL
add address=63.250.189.72/29 list=BRASIL
add address=64.34.188.128/26 list=BRASIL
add address=64.64.0.186/31 list=BRASIL
add address=64.64.0.188/31 list=BRASIL
add address=64.64.1.130/31 list=BRASIL
add address=64.64.1.132/31 list=BRASIL
add address=64.64.12.52/30 list=BRASIL
add address=64.77.45.64/26 list=BRASIL
add address=64.106.134.170/31 list=BRASIL
add address=64.106.134.172/30 list=BRASIL
add address=64.106.134.176/30 list=BRASIL
add address=64.106.135.160/29 list=BRASIL
add address=64.106.135.168/31 list=BRASIL
add address=64.106.152.190/31 list=BRASIL
add address=64.106.152.192/28 list=BRASIL
add address=64.106.152.208/31 list=BRASIL
add address=64.117.208.32/27 list=BRASIL
add address=64.117.208.136/29 list=BRASIL
add address=64.117.209.216/29 list=BRASIL
add address=64.117.209.248/29 list=BRASIL
add address=64.117.210.0/26 list=BRASIL
add address=64.117.210.64/27 list=BRASIL
add address=64.117.210.128/26 list=BRASIL
add address=64.150.181.155 list=BRASIL
add address=64.150.181.156/30 list=BRASIL
add address=64.150.181.160/30 list=BRASIL
add address=64.150.181.164/31 list=BRASIL
add address=64.187.123.120/29 list=BRASIL
add address=64.187.123.208/29 list=BRASIL
add address=64.208.7.0/24 list=BRASIL
add address=64.209.111.28/30 list=BRASIL
add address=64.211.43.0/24 list=BRASIL
add address=64.233.162.0/24 list=BRASIL
add address=64.236.10.0/23 list=BRASIL
add address=65.205.133.0/24 list=BRASIL
add address=66.85.154.128/29 list=BRASIL
add address=66.100.58.32/29 list=BRASIL
add address=66.101.33.0/26 list=BRASIL
add address=66.135.62.32/28 list=BRASIL
add address=66.165.78.0/27 list=BRASIL
add address=66.165.166.96/28 list=BRASIL
add address=66.165.171.72/30 list=BRASIL
add address=66.178.17.0/24 list=BRASIL
add address=66.231.243.48/28 list=BRASIL
add address=67.15.148.64/26 list=BRASIL
add address=67.15.149.192/26 list=BRASIL
add address=67.15.159.64/26 list=BRASIL
add address=67.15.214.128/28 list=BRASIL
add address=67.15.233.0/27 list=BRASIL
add address=67.15.236.96/27 list=BRASIL
add address=67.15.242.32/28 list=BRASIL
add address=67.15.242.224/27 list=BRASIL
add address=67.23.243.176/30 list=BRASIL
add address=69.24.250.192/28 list=BRASIL
add address=69.30.244.40/29 list=BRASIL
add address=69.42.121.176/28 list=BRASIL
add address=69.61.8.24/29 list=BRASIL
add address=69.61.11.112/29 list=BRASIL
add address=69.61.14.80/29 list=BRASIL
add address=69.61.16.120/29 list=BRASIL
add address=69.63.152.80/30 list=BRASIL
add address=69.64.41.96/27 list=BRASIL
add address=69.174.101.16/28 list=BRASIL
add address=69.174.101.64/27 list=BRASIL
add address=69.174.101.104/29 list=BRASIL
add address=69.174.101.120/29 list=BRASIL
add address=69.174.101.192/29 list=BRASIL
add address=69.174.101.208/28 list=BRASIL
add address=69.174.101.240/28 list=BRASIL
add address=69.195.196.0/26 list=BRASIL
add address=70.36.25.16/28 list=BRASIL
add address=70.36.25.104/29 list=BRASIL
add address=72.14.241.8/29 list=BRASIL
add address=72.14.241.16/29 list=BRASIL
add address=72.232.230.128/25 list=BRASIL
add address=72.233.57.128/26 list=BRASIL
add address=74.120.240.80/28 list=BRASIL
add address=74.121.191.160/29 list=BRASIL
add address=74.209.134.0/24 list=BRASIL
add address=76.12.254.40/29 list=BRASIL
add address=76.12.254.64/27 list=BRASIL
add address=76.72.168.80/29 list=BRASIL
add address=78.24.201.16/28 list=BRASIL
add address=78.24.202.8/29 list=BRASIL
add address=78.24.203.8/29 list=BRASIL
add address=78.24.206.8/29 list=BRASIL
add address=80.78.17.236/30 list=BRASIL
add address=80.78.20.64/29 list=BRASIL
add address=80.239.202.96/29 list=BRASIL
add address=80.239.231.8/29 list=BRASIL
add address=80.252.188.200/30 list=BRASIL
add address=81.95.150.112/28 list=BRASIL
add address=81.95.155.216/29 list=BRASIL
add address=81.95.158.120/29 list=BRASIL
add address=82.138.131.0/25 list=BRASIL
add address=82.138.131.128/26 list=BRASIL
add address=82.211.1.0/24 list=BRASIL
add address=82.211.25.0/24 list=BRASIL
add address=84.200.28.0/24 list=BRASIL
add address=85.25.104.0/27 list=BRASIL
add address=85.25.160.224/27 list=BRASIL
add address=85.25.161.64/27 list=BRASIL
add address=85.25.162.64/27 list=BRASIL
add address=85.25.162.128/26 list=BRASIL
add address=85.25.163.32/27 list=BRASIL
add address=85.25.164.64/27 list=BRASIL
add address=85.25.167.192/27 list=BRASIL
add address=85.25.168.0/27 list=BRASIL
add address=85.25.180.64/27 list=BRASIL
add address=85.25.180.160/27 list=BRASIL
add address=85.25.181.0/27 list=BRASIL
add address=85.25.183.128/26 list=BRASIL
add address=85.25.186.96/27 list=BRASIL
add address=85.25.187.64/27 list=BRASIL
add address=85.25.188.64/27 list=BRASIL
add address=85.25.229.64/27 list=BRASIL
add address=85.25.230.96/27 list=BRASIL
add address=85.158.209.192/26 list=BRASIL
add address=85.238.128.0/22 list=BRASIL
add address=86.58.206.240/28 list=BRASIL
add address=91.108.185.80/30 list=BRASIL
add address=91.190.174.64/26 list=BRASIL
add address=95.154.223.128/25 list=BRASIL
add address=108.175.53.64/27 list=BRASIL
add address=139.82.0.0/16 list=BRASIL
add address=139.122.208.0/24 list=BRASIL
add address=141.255.157.96/28 list=BRASIL
add address=143.54.0.0/16 list=BRASIL
add address=143.106.0.0/15 list=BRASIL
add address=143.108.0.0/16 list=BRASIL
add address=146.82.224.168/29 list=BRASIL
add address=146.134.0.0/16 list=BRASIL
add address=146.164.0.0/16 list=BRASIL
add address=146.247.120.0/28 list=BRASIL
add address=147.65.0.0/16 list=BRASIL
add address=148.177.88.0/21 list=BRASIL
add address=150.161.0.0/16 list=BRASIL
add address=150.162.0.0/15 list=BRASIL
add address=150.164.0.0/15 list=BRASIL
add address=151.236.5.239 list=BRASIL
add address=151.236.5.240 list=BRASIL
add address=152.84.0.0/16 list=BRASIL
add address=152.92.0.0/16 list=BRASIL
add address=155.211.0.0/16 list=BRASIL
add address=157.86.0.0/16 list=BRASIL
add address=159.172.52.0/24 list=BRASIL
add address=159.182.81.0/24 list=BRASIL
add address=159.253.136.224/29 list=BRASIL
add address=159.253.142.160/29 list=BRASIL
add address=159.253.143.160/30 list=BRASIL
add address=159.253.144.168/29 list=BRASIL
add address=159.253.149.208/29 list=BRASIL
add address=159.253.151.232/29 list=BRASIL
add address=159.253.152.104/29 list=BRASIL
add address=159.253.153.208/29 list=BRASIL
add address=161.24.0.0/16 list=BRASIL
add address=161.79.0.0/16 list=BRASIL
add address=161.148.0.0/16 list=BRASIL
add address=164.41.0.0/16 list=BRASIL
add address=164.85.0.0/16 list=BRASIL
add address=167.167.56.0/21 list=BRASIL
add address=168.161.218.0/23 list=BRASIL
add address=170.66.0.0/16 list=BRASIL
add address=173.224.114.64/27 list=BRASIL
add address=173.224.117.0/27 list=BRASIL
add address=173.224.117.64/27 list=BRASIL
add address=173.224.123.128/27 list=BRASIL
add address=173.253.112.96/29 list=BRASIL
add address=173.253.112.144/29 list=BRASIL
add address=173.253.112.176/29 list=BRASIL
add address=173.253.112.192/29 list=BRASIL
add address=173.253.113.32/29 list=BRASIL
add address=173.253.113.104/29 list=BRASIL
add address=173.253.114.136/29 list=BRASIL
add address=173.253.114.224/29 list=BRASIL
add address=173.253.115.0/29 list=BRASIL
add address=173.253.115.80/29 list=BRASIL
add address=173.253.117.216/29 list=BRASIL
add address=173.253.118.24/29 list=BRASIL
add address=173.253.118.112/29 list=BRASIL
add address=173.253.118.144/29 list=BRASIL
add address=173.253.120.40/29 list=BRASIL
add address=173.253.120.144/29 list=BRASIL
add address=173.253.120.200/29 list=BRASIL
add address=173.253.120.248/29 list=BRASIL
add address=173.253.122.96/29 list=BRASIL
add address=173.253.122.120/29 list=BRASIL
add address=173.253.122.232/29 list=BRASIL
add address=173.253.124.64/29 list=BRASIL
add address=173.253.124.224/29 list=BRASIL
add address=173.255.2.200/29 list=BRASIL
add address=173.255.3.104/29 list=BRASIL
add address=173.255.5.16/29 list=BRASIL
add address=173.255.5.32/29 list=BRASIL
add address=173.255.5.128/29 list=BRASIL
add address=173.255.5.208/29 list=BRASIL
add address=173.255.5.248/29 list=BRASIL
add address=173.255.6.72/29 list=BRASIL
add address=173.255.6.112/29 list=BRASIL
add address=174.35.93.0/24 list=BRASIL
add address=174.138.160.8/29 list=BRASIL
add address=176.67.84.40/30 list=BRASIL
add address=177.0.0.0/9 list=BRASIL
add address=177.128.0.0/10 list=BRASIL
add address=177.192.0.0/11 list=BRASIL
add address=178.18.241.88/29 list=BRASIL
add address=178.174.22.128/25 list=BRASIL
add address=178.236.226.24/30 list=BRASIL
add address=179.96.0.0/17 list=BRASIL
add address=179.128.0.0/9 list=BRASIL
add address=184.95.46.136/29 list=BRASIL
add address=184.171.160.40/29 list=BRASIL
add address=184.171.252.188/30 list=BRASIL
add address=184.172.9.88/29 list=BRASIL
add address=184.172.9.176/28 list=BRASIL
add address=184.172.9.232/29 list=BRASIL
add address=184.172.17.24/29 list=BRASIL
add address=184.172.21.72/29 list=BRASIL
add address=184.172.21.184/29 list=BRASIL
add address=184.172.24.112/29 list=BRASIL
add address=184.172.25.64/27 list=BRASIL
add address=184.172.32.216/29 list=BRASIL
add address=184.172.34.136/29 list=BRASIL
add address=184.172.57.192/27 list=BRASIL
add address=184.172.57.224/28 list=BRASIL
add address=184.172.57.240/29 list=BRASIL
add address=184.172.63.88/29 list=BRASIL
add address=184.173.82.96/28 list=BRASIL
add address=184.173.83.120/29 list=BRASIL
add address=184.173.83.144/28 list=BRASIL
add address=184.173.84.16/28 list=BRASIL
add address=184.173.84.48/28 list=BRASIL
add address=184.173.84.64/28 list=BRASIL
add address=184.173.84.80/29 list=BRASIL
add address=184.173.84.112/28 list=BRASIL
add address=184.173.99.80/29 list=BRASIL
add address=184.173.108.232/29 list=BRASIL
add address=184.173.117.160/27 list=BRASIL
add address=184.173.122.160/27 list=BRASIL
add address=184.173.195.16/29 list=BRASIL
add address=185.12.248.152/29 list=BRASIL
add address=186.192.0.0/10 list=BRASIL
add address=187.0.0.0/9 list=BRASIL
add address=188.130.250.40/30 list=BRASIL
add address=188.138.4.160/27 list=BRASIL
add address=188.138.4.192/27 list=BRASIL
add address=188.138.5.0/27 list=BRASIL
add address=188.138.20.128/27 list=BRASIL
add address=188.138.23.0/27 list=BRASIL
add address=188.138.30.32/27 list=BRASIL
add address=188.138.30.160/27 list=BRASIL
add address=188.138.38.96/27 list=BRASIL
add address=188.138.39.96/27 list=BRASIL
add address=188.138.44.64/27 list=BRASIL
add address=188.138.44.224/27 list=BRASIL
add address=188.138.47.64/27 list=BRASIL
add address=188.138.54.32/27 list=BRASIL
add address=188.138.55.96/27 list=BRASIL
add address=188.138.61.160/27 list=BRASIL
add address=188.138.62.224/27 list=BRASIL
add address=188.138.63.160/27 list=BRASIL
add address=189.0.0.0/9 list=BRASIL
add address=190.9.39.0/24 list=BRASIL
add address=190.98.141.0/29 list=BRASIL
add address=190.98.144.0/20 list=BRASIL
add address=190.98.168.0/23 list=BRASIL
add address=192.80.209.0/24 list=BRASIL
add address=192.111.229.0/24 list=BRASIL
add address=192.132.35.0/24 list=BRASIL
add address=192.146.157.0/24 list=BRASIL
add address=192.146.229.0/24 list=BRASIL
add address=192.147.218.0/24 list=BRASIL
add address=192.153.88.0/24 list=BRASIL
add address=192.153.120.0/24 list=BRASIL
add address=192.159.116.0/24 list=BRASIL
add address=192.160.45.0/24 list=BRASIL
add address=192.160.50.0/24 list=BRASIL
add address=192.160.111.0/24 list=BRASIL
add address=192.160.128.0/24 list=BRASIL
add address=192.188.11.0/24 list=BRASIL
add address=192.190.31.0/24 list=BRASIL
add address=192.195.237.0/24 list=BRASIL
add address=192.198.8.0/21 list=BRASIL
add address=192.207.194.0/23 list=BRASIL
add address=192.207.200.0/22 list=BRASIL
add address=192.207.204.0/23 list=BRASIL
add address=192.207.206.0/24 list=BRASIL
add address=192.216.140.128/29 list=BRASIL
add address=192.223.64.0/18 list=BRASIL
add address=192.231.114.0/23 list=BRASIL
add address=192.231.116.0/22 list=BRASIL
add address=192.231.120.0/23 list=BRASIL
add address=194.117.108.68/30 list=BRASIL
add address=194.117.109.72/30 list=BRASIL
add address=194.117.109.164/30 list=BRASIL
add address=194.117.109.172/30 list=BRASIL
add address=194.117.109.200/30 list=BRASIL
add address=194.117.116.240/30 list=BRASIL
add address=194.117.117.168/30 list=BRASIL
add address=195.22.219.0/24 list=BRASIL
add address=195.112.164.124/30 list=BRASIL
add address=195.112.164.196/30 list=BRASIL
add address=195.112.164.216/30 list=BRASIL
add address=195.112.164.244/30 list=BRASIL
add address=195.112.172.8/30 list=BRASIL
add address=195.112.172.32/30 list=BRASIL
add address=195.112.172.96/30 list=BRASIL
add address=195.112.172.148/30 list=BRASIL
add address=195.112.172.220/30 list=BRASIL
add address=195.112.173.36/30 list=BRASIL
add address=195.112.173.200/30 list=BRASIL
add address=195.112.173.220/30 list=BRASIL
add address=195.112.186.56/30 list=BRASIL
add address=195.112.186.136/30 list=BRASIL
add address=195.112.186.168/30 list=BRASIL
add address=195.112.187.0/30 list=BRASIL
add address=195.112.187.64/30 list=BRASIL
add address=195.112.187.76/30 list=BRASIL
add address=195.112.187.80/30 list=BRASIL
add address=195.112.187.108/30 list=BRASIL
add address=195.112.187.132/30 list=BRASIL
add address=195.112.188.64/30 list=BRASIL
add address=195.112.188.172/30 list=BRASIL
add address=195.112.188.204/30 list=BRASIL
add address=195.112.188.208/30 list=BRASIL
add address=195.112.188.236/30 list=BRASIL
add address=195.112.189.152/30 list=BRASIL
add address=198.7.60.160/27 list=BRASIL
add address=198.12.32.0/19 list=BRASIL
add address=198.15.83.8/29 list=BRASIL
add address=198.15.83.32/27 list=BRASIL
add address=198.15.105.152/29 list=BRASIL
add address=198.17.120.0/23 list=BRASIL
add address=198.17.232.0/24 list=BRASIL
add address=198.24.4.0/23 list=BRASIL
add address=198.49.128.0/22 list=BRASIL
add address=198.50.16.0/21 list=BRASIL
add address=198.58.8.0/21 list=BRASIL
add address=198.81.8.0/22 list=BRASIL
add address=198.154.93.103 list=BRASIL
add address=198.154.93.104/30 list=BRASIL
add address=198.154.93.108/31 list=BRASIL
add address=198.154.93.110 list=BRASIL
add address=198.184.161.0/24 list=BRASIL
add address=199.16.205.200/29 list=BRASIL
add address=199.16.207.128/27 list=BRASIL
add address=199.19.109.59 list=BRASIL
add address=199.19.109.60/30 list=BRASIL
add address=199.19.109.64/27 list=BRASIL
add address=199.19.109.96/28 list=BRASIL
add address=199.19.109.112/29 list=BRASIL
add address=199.34.122.56/29 list=BRASIL
add address=199.34.123.88/29 list=BRASIL
add address=199.34.123.240/29 list=BRASIL
add address=199.34.124.240/29 list=BRASIL
add address=199.34.126.16/29 list=BRASIL
add address=199.34.126.136/29 list=BRASIL
add address=199.34.126.160/27 list=BRASIL
add address=199.34.127.168/29 list=BRASIL
add address=199.66.220.72/29 list=BRASIL
add address=199.71.232.0/28 list=BRASIL
add address=199.87.52.120/29 list=BRASIL
add address=199.101.96.160/28 list=BRASIL
add address=199.101.98.144/28 list=BRASIL
add address=199.101.98.176/28 list=BRASIL
add address=199.101.100.64/28 list=BRASIL
add address=199.101.101.128/28 list=BRASIL
add address=199.101.101.200/29 list=BRASIL
add address=199.101.101.224/29 list=BRASIL
add address=199.101.101.240/29 list=BRASIL
add address=199.101.146.0/29 list=BRASIL
add address=199.115.75.176/29 list=BRASIL
add address=199.191.58.188/30 list=BRASIL
add address=199.191.58.212/30 list=BRASIL
add address=199.191.58.220/30 list=BRASIL
add address=199.191.58.224/28 list=BRASIL
add address=199.191.59.240/28 list=BRASIL
add address=199.230.53.224/30 list=BRASIL
add address=199.233.234.0/29 list=BRASIL
add address=199.233.234.40/29 list=BRASIL
add address=199.241.185.80/29 list=BRASIL
add address=199.241.187.28/30 list=BRASIL
add address=199.241.187.168/30 list=BRASIL
add address=199.241.188.72/29 list=BRASIL
add address=199.241.188.128/29 list=BRASIL
add address=199.241.190.208/29 list=BRASIL
add address=200.0.8.0/21 list=BRASIL
add address=200.0.32.0/20 list=BRASIL
add address=200.0.56.0/22 list=BRASIL
add address=200.0.60.0/23 list=BRASIL
add address=200.0.68.0/22 list=BRASIL
add address=200.0.81.0/24 list=BRASIL
add address=200.0.85.0/24 list=BRASIL
add address=200.0.86.0/23 list=BRASIL
add address=200.0.92.0/24 list=BRASIL
add address=200.0.102.0/24 list=BRASIL
add address=200.3.16.0/20 list=BRASIL
add address=200.5.9.0/24 list=BRASIL
add address=200.6.35.0/24 list=BRASIL
add address=200.6.38.0/23 list=BRASIL
add address=200.6.40.0/21 list=BRASIL
add address=200.6.132.0/23 list=BRASIL
add address=200.7.0.0/22 list=BRASIL
add address=200.7.8.0/22 list=BRASIL
add address=200.9.1.0/24 list=BRASIL
add address=200.9.2.0/24 list=BRASIL
add address=200.9.65.0/24 list=BRASIL
add address=200.9.66.0/24 list=BRASIL
add address=200.9.68.0/24 list=BRASIL
add address=200.9.76.0/24 list=BRASIL
add address=200.9.84.0/22 list=BRASIL
add address=200.9.88.0/21 list=BRASIL
add address=200.9.102.0/23 list=BRASIL
add address=200.9.104.0/22 list=BRASIL
add address=200.9.112.0/23 list=BRASIL
add address=200.9.114.0/24 list=BRASIL
add address=200.9.116.0/22 list=BRASIL
add address=200.9.121.0/24 list=BRASIL
add address=200.9.124.0/22 list=BRASIL
add address=200.9.129.0/24 list=BRASIL
add address=200.9.130.0/23 list=BRASIL
add address=200.9.132.0/24 list=BRASIL
add address=200.9.138.0/23 list=BRASIL
add address=200.9.140.0/24 list=BRASIL
add address=200.9.144.0/24 list=BRASIL
add address=200.9.148.0/23 list=BRASIL
add address=200.9.158.0/23 list=BRASIL
add address=200.9.169.0/24 list=BRASIL
add address=200.9.170.0/23 list=BRASIL
add address=200.9.172.0/22 list=BRASIL
add address=200.9.184.0/24 list=BRASIL
add address=200.9.199.0/24 list=BRASIL
add address=200.9.202.0/23 list=BRASIL
add address=200.9.206.0/24 list=BRASIL
add address=200.9.214.0/24 list=BRASIL
add address=200.9.220.0/22 list=BRASIL
add address=200.9.224.0/24 list=BRASIL
add address=200.9.226.0/24 list=BRASIL
add address=200.9.229.0/24 list=BRASIL
add address=200.9.234.0/24 list=BRASIL
add address=200.9.249.0/24 list=BRASIL
add address=200.9.250.0/23 list=BRASIL
add address=200.9.252.0/24 list=BRASIL
add address=200.10.32.0/20 list=BRASIL
add address=200.10.48.0/21 list=BRASIL
add address=200.10.56.0/22 list=BRASIL
add address=200.10.136.0/23 list=BRASIL
add address=200.10.138.0/24 list=BRASIL
add address=200.10.144.0/24 list=BRASIL
add address=200.10.146.0/24 list=BRASIL
add address=200.10.153.0/24 list=BRASIL
add address=200.10.154.0/24 list=BRASIL
add address=200.10.156.0/22 list=BRASIL
add address=200.10.174.0/23 list=BRASIL
add address=200.10.178.0/23 list=BRASIL
add address=200.10.180.0/23 list=BRASIL
add address=200.10.185.0/24 list=BRASIL
add address=200.10.187.0/24 list=BRASIL
add address=200.10.189.0/24 list=BRASIL
add address=200.10.191.0/24 list=BRASIL
add address=200.10.192.0/23 list=BRASIL
add address=200.10.209.0/24 list=BRASIL
add address=200.10.210.0/24 list=BRASIL
add address=200.10.227.0/24 list=BRASIL
add address=200.11.0.0/20 list=BRASIL
add address=200.11.16.0/21 list=BRASIL
add address=200.11.24.0/22 list=BRASIL
add address=200.11.28.0/24 list=BRASIL
add address=200.12.0.0/20 list=BRASIL
add address=200.12.139.0/24 list=BRASIL
add address=200.13.8.0/21 list=BRASIL
add address=200.14.32.0/23 list=BRASIL
add address=200.14.35.0/24 list=BRASIL
add address=200.15.0.0/22 list=BRASIL
add address=200.17.0.0/16 list=BRASIL
add address=200.18.0.0/15 list=BRASIL
add address=200.20.0.0/16 list=BRASIL
add address=200.30.0.0/21 list=BRASIL
add address=200.58.16.0/28 list=BRASIL
add address=200.58.21.32/27 list=BRASIL
add address=200.58.21.96/27 list=BRASIL
add address=200.58.48.0/26 list=BRASIL
add address=200.58.50.0/28 list=BRASIL
add address=200.58.50.40/29 list=BRASIL
add address=200.58.50.64/27 list=BRASIL
add address=200.58.50.160/28 list=BRASIL
add address=200.96.0.0/13 list=BRASIL
add address=200.128.0.0/9 list=BRASIL
add address=201.0.0.0/10 list=BRASIL
add address=201.64.0.0/11 list=BRASIL
add address=201.126.113.0/24 list=BRASIL
add address=204.12.55.128/29 list=BRASIL
add address=204.12.57.208/29 list=BRASIL
add address=204.12.63.96/29 list=BRASIL
add address=204.12.68.184/29 list=BRASIL
add address=204.12.68.192/28 list=BRASIL
add address=204.12.68.208/29 list=BRASIL
add address=204.12.110.200/29 list=BRASIL
add address=204.12.110.208/29 list=BRASIL
add address=204.12.112.112/28 list=BRASIL
add address=204.12.112.128/29 list=BRASIL
add address=204.12.120.112/28 list=BRASIL
add address=204.12.121.120/29 list=BRASIL
add address=204.12.126.104/29 list=BRASIL
add address=204.183.118.0/24 list=BRASIL
add address=204.245.24.80/29 list=BRASIL
add address=205.185.210.0/23 list=BRASIL
add address=205.185.212.128/26 list=BRASIL
add address=206.49.99.0/24 list=BRASIL
add address=206.73.5.64/27 list=BRASIL
add address=206.73.5.192/27 list=BRASIL
add address=206.73.6.64/27 list=BRASIL
add address=206.73.6.96/28 list=BRASIL
add address=206.73.49.64/29 list=BRASIL
add address=206.73.54.192/26 list=BRASIL
add address=206.73.57.80/28 list=BRASIL
add address=206.73.57.192/26 list=BRASIL
add address=206.73.59.16/28 list=BRASIL
add address=206.73.59.64/27 list=BRASIL
add address=206.73.243.64/27 list=BRASIL
add address=206.73.246.0/28 list=BRASIL
add address=206.73.253.64/27 list=BRASIL
add address=206.73.253.128/26 list=BRASIL
add address=206.182.130.0/27 list=BRASIL
add address=206.182.130.64/29 list=BRASIL
add address=206.182.163.144/28 list=BRASIL
add address=206.182.176.224/27 list=BRASIL
add address=206.182.200.0/27 list=BRASIL
add address=206.182.200.64/26 list=BRASIL
add address=206.182.200.192/26 list=BRASIL
add address=206.214.73.0/27 list=BRASIL
add address=206.214.208.236/30 list=BRASIL
add address=206.214.210.103 list=BRASIL
add address=206.214.210.104/31 list=BRASIL
add address=206.214.210.106 list=BRASIL
add address=206.214.216.126/31 list=BRASIL
add address=206.214.216.128/31 list=BRASIL
add address=206.214.216.142/31 list=BRASIL
add address=206.214.216.144/31 list=BRASIL
add address=206.214.218.102/31 list=BRASIL
add address=206.214.218.104/31 list=BRASIL
add address=206.221.217.120/29 list=BRASIL
add address=206.221.217.248/29 list=BRASIL
add address=206.221.219.0/30 list=BRASIL
add address=206.221.219.88/29 list=BRASIL
add address=206.221.219.96/29 list=BRASIL
add address=206.221.219.152/29 list=BRASIL
add address=206.221.219.200/29 list=BRASIL
add address=206.221.220.104/29 list=BRASIL
add address=206.221.220.224/29 list=BRASIL
add address=206.221.221.40/29 list=BRASIL
add address=206.221.221.104/29 list=BRASIL
add address=206.221.221.216/29 list=BRASIL
add address=206.222.15.240/29 list=BRASIL
add address=207.83.160.0/29 list=BRASIL
add address=207.83.160.32/27 list=BRASIL
add address=207.83.160.96/28 list=BRASIL
add address=207.117.37.0/24 list=BRASIL
add address=207.117.236.0/24 list=BRASIL
add address=207.209.70.0/24 list=BRASIL
add address=207.209.73.0/24 list=BRASIL
add address=207.209.75.0/24 list=BRASIL
add address=207.209.76.0/24 list=BRASIL
add address=207.209.88.32/27 list=BRASIL
add address=207.209.119.0/28 list=BRASIL
add address=207.209.240.0/24 list=BRASIL
add address=208.48.246.0/23 list=BRASIL
add address=208.51.226.0/24 list=BRASIL
add address=208.64.127.80/29 list=BRASIL
add address=208.89.105.156/30 list=BRASIL
add address=208.89.105.160/27 list=BRASIL
add address=208.89.105.192/31 list=BRASIL
add address=208.89.105.194 list=BRASIL
add address=208.110.71.168/29 list=BRASIL
add address=209.28.63.0/26 list=BRASIL
add address=209.28.63.128/26 list=BRASIL
add address=209.28.69.80/28 list=BRASIL
add address=209.28.69.112/28 list=BRASIL
add address=209.28.87.16/28 list=BRASIL
add address=209.28.87.32/27 list=BRASIL
add address=209.28.87.128/26 list=BRASIL
add address=209.28.89.64/28 list=BRASIL
add address=209.28.89.160/27 list=BRASIL
add address=209.28.111.64/27 list=BRASIL
add address=209.28.120.112/28 list=BRASIL
add address=209.41.76.0/24 list=BRASIL
add address=209.41.79.144/29 list=BRASIL
add address=209.85.34.0/24 list=BRASIL
add address=209.85.59.192/26 list=BRASIL
add address=209.93.4.0/26 list=BRASIL
add address=209.93.19.128/25 list=BRASIL
add address=209.93.131.0/25 list=BRASIL
add address=209.93.136.128/25 list=BRASIL
add address=209.93.156.224/27 list=BRASIL
add address=209.93.192.64/28 list=BRASIL
add address=209.93.193.64/26 list=BRASIL
add address=209.93.194.0/26 list=BRASIL
add address=209.93.194.128/25 list=BRASIL
add address=209.93.196.128/25 list=BRASIL
add address=209.93.197.0/24 list=BRASIL
add address=209.93.201.0/27 list=BRASIL
add address=209.93.204.192/27 list=BRASIL
add address=209.93.209.0/25 list=BRASIL
add address=209.93.209.128/26 list=BRASIL
add address=209.93.215.192/26 list=BRASIL
add address=209.93.220.96/27 list=BRASIL
add address=209.93.220.128/25 list=BRASIL
add address=209.208.14.40/29 list=BRASIL
add address=209.208.22.48/28 list=BRASIL
add address=209.208.126.32/29 list=BRASIL
add address=209.239.118.160/27 list=BRASIL
add address=209.239.122.96/27 list=BRASIL
add address=209.239.122.192/27 list=BRASIL
add address=209.239.123.96/27 list=BRASIL
add address=209.239.126.64/27 list=BRASIL
add address=212.63.161.128/30 list=BRASIL
add address=212.63.177.0/30 list=BRASIL
add address=212.63.184.4/30 list=BRASIL
add address=212.63.184.16/30 list=BRASIL
add address=212.63.184.76/30 list=BRASIL
add address=212.63.184.104/30 list=BRASIL
add address=212.63.184.136/30 list=BRASIL
add address=212.63.184.160/30 list=BRASIL
add address=212.63.184.176/30 list=BRASIL
add address=212.63.187.12/30 list=BRASIL
add address=212.63.187.36/30 list=BRASIL
add address=212.63.187.60/30 list=BRASIL
add address=212.63.187.128/30 list=BRASIL
add address=212.63.187.136/30 list=BRASIL
add address=212.63.187.176/30 list=BRASIL
add address=212.63.187.224/30 list=BRASIL
add address=212.63.187.240/29 list=BRASIL
add address=212.63.190.88/30 list=BRASIL
add address=212.63.190.168/30 list=BRASIL
add address=212.63.190.240/30 list=BRASIL
add address=212.63.205.104/30 list=BRASIL
add address=212.85.216.0/24 list=BRASIL
add address=216.38.54.45 list=BRASIL
add address=216.38.54.46/31 list=BRASIL
add address=216.38.54.48 list=BRASIL
add address=216.53.188.128/27 list=BRASIL
add address=216.53.191.192/26 list=BRASIL
add address=216.119.138.160/29 list=BRASIL
add address=216.119.139.8/29 list=BRASIL
add address=216.119.139.56/29 list=BRASIL
add address=216.194.132.0/23 list=BRASIL
add address=216.194.135.0/24 list=BRASIL
add address=216.230.33.0/24 list=BRASIL
add address=216.239.33.8/29 list=BRASIL
add address=216.239.55.8/29 list=BRASIL
add address=216.244.82.48/29 list=BRASIL
add address=217.23.111.96/27 list=BRASIL
add address=speedtest.net list=BRASIL
add address=ookla.com list=BRASIL
add address=177.72.104.5 list=SISTEMA_LIBERADOS
add address=187.85.111.11 list=BELLUNO
add address=186.225.212.242 list=BELLUNO
add address=177.36.37.234 list=BELLUNO
add address=52.67.237.11 list=BELLUNO
add address=52.67.162.156 list=BELLUNO
add address=189.90.194.0/24 comment=HUBSOFT list=SISTEMA_LIBERADOS
add address=191.6.192.0/19 list=BRASIL
add address=20.206.91.111 list=BLOQUEADOS
add address=138.118.173.72 list=SISTEMA_LIBERADOS
add address=177.72.104.0/21 list=IP_PUBLICO
add address=177.93.240.0/21 list=IP_PUBLICO
add address=100.0.0.0/8 list=RANGENETPAL
add address=200.192.224.0/21 list=BRASIL
add address=200.142.128.0/20 list=BRASIL
add address=189.0.0.0/16 list=BRASIL
add address=189.96.0.0/15 list=BRASIL
add address=187.1.192.0/18 list=BRASIL
add address=189.98.0.0/15 list=BRASIL
add address=187.88.0.0/14 list=BRASIL
add address=177.112.0.0/14 list=BRASIL
add address=177.160.0.0/14 list=BRASIL
add address=177.172.0.0/14 list=BRASIL
add address=177.196.0.0/14 list=BRASIL
add address=179.228.0.0/14 list=BRASIL
add address=179.164.0.0/14 list=BRASIL
add address=179.168.0.0/14 list=BRASIL
add address=179.116.0.0/14 list=BRASIL
add address=179.132.0.0/14 list=BRASIL
add address=179.148.0.0/14 list=BRASIL
add address=179.88.0.0/14 list=BRASIL
add address=191.196.0.0/14 list=BRASIL
add address=191.200.0.0/14 list=BRASIL
add address=191.204.0.0/14 list=BRASIL
add address=191.208.0.0/14 list=BRASIL
add address=191.20.0.0/14 list=BRASIL
add address=191.24.0.0/14 list=BRASIL
add address=177.24.0.0/16 list=BRASIL
add address=177.25.64.0/18 list=BRASIL
add address=177.25.128.0/17 list=BRASIL
add address=179.94.0.0/16 list=BRASIL
add address=179.80.0.0/15 list=BRASIL
add address=179.82.0.0/16 list=BRASIL
add address=179.160.0.0/15 list=BRASIL
add address=179.163.0.0/16 list=BRASIL
add address=191.28.0.0/15 list=BRASIL
add address=177.60.0.0/16 list=BRASIL
add address=177.61.0.0/17 list=BRASIL
add address=177.61.192.0/18 list=BRASIL
add address=179.128.0.0/15 list=BRASIL
add address=179.130.0.0/16 list=BRASIL
add address=179.131.128.0/17 list=BRASIL
add address=152.240.0.0/13 list=BRASIL
add address=152.248.0.0/16 list=BRASIL
add address=152.251.0.0/16 list=BRASIL
add address=152.252.0.0/15 list=BRASIL
add address=152.254.0.0/17 list=BRASIL
add address=152.255.0.0/16 list=BRASIL
add address=177.168.0.0/15 list=BRASIL
add address=177.171.0.0/16 list=BRASIL
add address=177.26.0.0/16 list=BRASIL
add address=177.27.0.0/17 list=BRASIL
add address=177.27.128.0/18 list=BRASIL
add address=177.63.0.0/17 list=BRASIL
add address=177.63.128.0/18 list=BRASIL
add address=177.77.0.0/16 list=BRASIL
add address=177.78.0.0/15 list=BRASIL
add address=177.116.0.0/15 list=BRASIL
add address=177.118.0.0/17 list=BRASIL
add address=177.118.192.0/18 list=BRASIL
add address=177.119.0.0/16 list=BRASIL
add address=177.144.0.0/17 list=BRASIL
add address=177.144.192.0/18 list=BRASIL
add address=177.145.0.0/16 list=BRASIL
add address=177.146.0.0/15 list=BRASIL
add address=179.92.0.0/16 list=BRASIL
add address=179.100.128.0/17 list=BRASIL
add address=179.101.0.0/16 list=BRASIL
add address=179.102.0.0/15 list=BRASIL
add address=179.112.0.0/16 list=BRASIL
add address=179.114.0.0/15 list=BRASIL
add address=179.145.64.0/18 list=BRASIL
add address=179.145.128.0/17 list=BRASIL
add address=179.144.0.0/16 list=BRASIL
add address=179.146.0.0/15 list=BRASIL
add address=179.174.64.0/18 list=BRASIL
add address=179.174.128.0/17 list=BRASIL
add address=179.175.0.0/16 list=BRASIL
add address=179.172.0.0/15 list=BRASIL
add address=179.225.0.0/17 list=BRASIL
add address=179.224.0.0/16 list=BRASIL
add address=179.226.0.0/15 list=BRASIL
add address=187.116.0.0/18 list=BRASIL
add address=187.116.128.0/17 list=BRASIL
add address=187.117.0.0/16 list=BRASIL
add address=187.118.0.0/15 list=BRASIL
add address=191.8.192.0/18 list=BRASIL
add address=191.8.0.0/17 list=BRASIL
add address=191.9.0.0/16 list=BRASIL
add address=191.10.0.0/15 list=BRASIL
add address=191.12.0.0/16 list=BRASIL
add address=191.14.0.0/15 list=BRASIL
add address=191.16.0.0/16 list=BRASIL
add address=191.18.0.0/16 list=BRASIL
add address=191.19.240.0/20 list=BRASIL
add address=191.192.0.0/16 list=BRASIL
add address=191.194.0.0/15 list=BRASIL
add address=179.84.128.0/19 list=BRASIL
add address=179.84.192.0/18 list=BRASIL
add address=179.84.0.0/17 list=BRASIL
add address=179.85.0.0/16 list=BRASIL
add address=179.86.0.0/15 list=BRASIL
add address=177.215.160.0/19 list=BRASIL
add address=177.215.192.0/18 list=BRASIL
add address=177.215.0.0/17 list=BRASIL
add address=177.214.0.0/16 list=BRASIL
add address=177.212.0.0/15 list=BRASIL
add address=179.245.96.0/19 list=BRASIL
add address=179.245.0.0/18 list=BRASIL
add address=179.245.128.0/17 list=BRASIL
add address=179.244.0.0/16 list=BRASIL
add address=179.246.0.0/15 list=BRASIL
add address=179.193.0.0/17 list=BRASIL
add address=179.237.128.0/17 list=BRASIL
add address=186.246.128.0/17 list=BRASIL
add address=152.234.64.0/18 list=BRASIL
add address=179.69.0.0/18 list=BRASIL
add address=167.249.92.0/22 list=BRASIL
add address=100.0.0.0/8 list=BRASIL
add address=45.231.140.0/22 list=BRASIL
add address=191.32.0.0/14 list=BRASIL
add address=191.176.0.0/14 list=BRASIL
add address=209.14.137.106 list=VOIP
add address=131.196.220.0/22 list=BRASIL
add address=177.72.104.5 list=FORA_DO_NAT
add address=192.168.15.0/24 list=RANGENETPAL
add address=177.72.104.8 list=FORA_DO_NAT
add address=192.168.115.98 list=NAT
add address=104.41.12.151 list=SIXTELECOM
add address=45.163.14.62 list=SIXTELECOM
add address=177.93.244.165 list=SIXTELECOM
add address=1.1.1.0/24 list=SIXTELECOM
add address=177.72.104.0/27 list=SIXTELECOM
add address=177.93.242.0/24 list=CGNAT
add address=192.168.116.0/24 list=RANGENETPAL
add address=192.168.115.104/30 list=RANGENETPAL
add address=192.168.115.12/30 list=NAT
add address=177.72.104.19 list=FORA_DO_NAT
add address=182.168.83.0/24 list=FORA_DO_NAT
add address=182.168.84.0/24 list=FORA_DO_NAT
add address=172.31.254.200/30 list=RANGENETPAL
add address=192.168.84.0/24 list=RANGENETPAL
add address=192.168.83.0/24 list=RANGENETPAL
add address=177.72.104.131 list=RANGENETPAL
add address=10.7.0.0/24 list=NAT
add address=192.168.25.0/29 list=NAT
add address=10.66.64.0/21 list=PPPOE_BLOQUEADOS
add address=192.168.116.4/30 list=NAT
add address=10.7.0.0/24 list=RANGENETPAL
add address=192.168.116.24/30 list=NAT
add address=192.168.17.36/30 list=NAT
add address=192.168.22.48/28 list=NAT
add address=192.168.66.0/28 list=NAT
add address=192.168.66.0/28 list=RANGENETPAL
add address=192.168.116.28/30 list=NAT
add address=10.200.255.252/30 list=NAT
add address=192.168.115.214 list=FORA_DO_NAT_RADIUS
add address=177.72.104.0/22 list="REDE LIBERADA_OPA_SUITE"
add address=177.93.240.0/21 list="REDE LIBERADA_OPA_SUITE"
add address=45.174.128.1 list="REDE LIBERADA_OPA_SUITE"
add address=45.174.128.1 comment=amz.smartolt.com list=RANGENETPAL
add address=192.168.90.0/24 list=NAT
add address=177.72.104.28 comment="DNS NetPal" list=DNS_AUT
add address=177.72.104.58 comment="DNS NetPal Loopback 58" list=DNS_AUT
add address=177.72.104.59 comment="DNS NetPal Loopback 59" list=DNS_AUT
add address=192.168.115.136/30 list=NAT
add address=192.168.254.0/24 comment="Etapa1 VLAN100 gerencia servidores" \
    list=NAT
/ip firewall filter
add action=log chain=forward dst-address=177.72.104.58 dst-port=53 \
    log-prefix="DNS58-UDP " protocol=udp src-address=10.150.150.4
add action=log chain=forward dst-address=177.72.104.58 dst-port=53 \
    log-prefix="DNS58-TCP " protocol=tcp src-address=10.150.150.4
add action=accept chain=forward comment="LIBERA DNS NETPAL UDP" \
    dst-address-list=DNS_AUT dst-port=53 protocol=udp src-address=\
    10.150.150.0/24
add action=accept chain=forward comment="LIBERA DNS NETPAL TCP" \
    dst-address-list=DNS_AUT dst-port=53 protocol=tcp src-address=\
    10.150.150.0/24
add action=accept chain=forward dst-address=10.200.255.240
add action=accept chain=forward dst-address=10.200.255.252/30
add action=accept chain=forward dst-address=192.168.115.214
add action=accept chain=forward dst-address=177.72.104.58
add action=accept chain=forward dst-address=177.72.104.28
add action=accept chain=forward dst-address=177.72.104.2
add action=accept chain=forward dst-address=177.72.104.57
add action=accept chain=forward dst-address=177.72.104.29
add action=accept chain=forward dst-address=177.72.104.6 dst-port=80,443 \
    protocol=tcp
add action=accept chain=forward dst-address=177.72.104.131
add action=accept chain=forward dst-address=177.72.104.22
add action=accept chain=forward dst-address=177.72.104.27
add action=accept chain=forward dst-address=177.72.104.24 dst-port=\
    443,80,45345,21 protocol=tcp
add action=accept chain=forward dst-address=177.72.104.26
add action=accept chain=forward dst-address=177.72.104.109
add action=accept chain=forward comment="OPA SUITE - CHAT" dst-address=\
    177.72.104.30 dst-port=80,443 protocol=tcp
add action=drop chain=forward dst-address=177.72.104.30 dst-port=45345 \
    protocol=tcp src-address-list="!REDE LIBERADA_OPA_SUITE"
add action=accept chain=forward dst-address=177.72.105.217
add action=accept chain=forward dst-address=177.72.105.221
add action=accept chain=forward dst-address=177.72.104.23
add action=accept chain=forward dst-address=192.168.15.18
add action=accept chain=forward comment="FUSION NETPAL CLIENTES ELABORADOS" \
    dst-address=177.72.104.14
add action=accept chain=forward comment="FUSION NETPAL CLIENTES SIMPLES" \
    dst-address=177.72.104.25
add action=accept chain=forward comment="SBC VOIP" dst-address=177.72.104.20
add action=accept chain=forward comment="TIP VOIP" dst-address=177.72.104.13
add action=accept chain=forward comment=MADE4IT dst-address=177.72.104.17
add action=accept chain=forward comment="FUSION NETPAL" dst-address=\
    177.72.104.18
add action=accept chain=forward comment="Servidor Fusion Voip" dst-address=\
    177.72.104.7 dst-port=80,45345,443,3478 protocol=tcp src-address-list=\
    !RANGENETPAL
add action=accept chain=forward comment="Servidor Fusion Voip Multistore" \
    dst-address=177.72.104.9
add action=accept chain=forward dst-address=192.168.116.8/30
add action=drop chain=forward dst-address=177.72.104.12 dst-port=443,22 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=accept chain=forward comment="Servidor sala" dst-address=\
    177.72.104.16
add action=accept chain=forward comment="Servidor sala" dst-port=3478 \
    protocol=udp
add action=drop chain=forward dst-address=177.153.51.195 src-address=\
    192.168.115.14
add action=drop chain=forward dst-address=177.72.104.5 dst-port=\
    0,17,19,111,161,135-139,179,445,1900,10001 protocol=udp
add action=drop chain=forward comment="DROPA CGNAT" dst-address-list=\
    !192.168.116.30 dst-port=80,443,22,1900,2122,2210,2323,8291 protocol=tcp \
    src-address=177.93.242.0/24
add action=accept chain=forward comment="LIBERA HUBSOFT PARA O BRASIL" \
    dst-address=177.72.104.8
add action=accept chain=forward comment="LIBERA HUBSOFT PARA O BRASIL" \
    dst-address=177.72.104.5 dst-port=!148 protocol=tcp
add action=accept chain=forward comment="LIBERA HUBSOFT PARA O BRASIL" \
    dst-address=177.72.104.5 dst-port=!148 protocol=udp
add action=accept chain=forward comment="HUBSOFT OUTPUT" src-address=\
    177.72.104.8
add action=accept chain=forward dst-address=192.168.115.14
add action=accept chain=forward comment="LIBERA L2TP IPSEC" dst-port=\
    500,1701,4500 protocol=udp
add action=accept chain=forward comment="SISTEMAS LIBERADOS" \
    src-address-list=SISTEMA_LIBERADOS
add action=accept chain=forward comment="LIBERA CALLSYS" dst-address=\
    177.72.104.5 dst-port=!45345 protocol=tcp
add action=accept chain=forward comment="LIBERA A TODA REDE NETPAL" \
    dst-address-list=RANGENETPAL src-address-list=RANGENETPAL
add action=accept chain=forward comment=BELLUNO dst-address=177.72.104.0/27 \
    src-address-list=BELLUNO
add action=accept chain=forward comment="LIBERA DNS" dst-address-list=DNS_AUT \
    dst-port=53 protocol=udp
add action=accept chain=forward comment="LIBERA ESPECTRA" src-address-list=\
    ESPECTRA
add action=accept chain=forward src-address-list=VOIP
add action=accept chain=forward dst-address=192.168.115.16/30
add action=accept chain=forward dst-address=192.168.115.124/30
add action=accept chain=forward dst-address=192.168.116.8/30
add action=accept chain=forward src-address=192.168.123.16/30
add action=drop chain=input comment="BLOQUEIA DNS" disabled=yes dst-address=\
    177.72.104.1 dst-port=53 protocol=udp
add action=drop chain=forward comment="INICIA FIREWALL BASICO" disabled=yes \
    dst-address-list=RANGENETPAL dst-port=53 protocol=udp src-address-list=\
    !RANGENETPAL
add action=drop chain=forward dst-port=25 protocol=tcp src-address-list=\
    !SMTP_LIBERADO
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=2756 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=\
    0,17,19,111,161,135-139,179,445,1900,10001 protocol=udp src-address-list=\
    !RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=21-23 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=80 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=8728 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=8729 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=15320 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=8858 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=8291 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=4443 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=443 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=45345 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=2122 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=2323 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=3306 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward dst-address-list=RANGENETPAL dst-port=27591 \
    protocol=tcp src-address-list=!RANGENETPAL
add action=drop chain=forward comment="FIM FIREWALL BASICO" dst-address-list=\
    RANGENETPAL dst-port=2534 protocol=tcp src-address-list=!RANGENETPAL
/ip firewall mangle
add action=change-mss chain=forward new-mss=clamp-to-pmtu passthrough=yes \
    protocol=tcp tcp-flags=syn
/ip firewall nat
add action=dst-nat chain=dstnat comment="REDIRECIONAMENTO THE DUDE" \
    dst-address=177.72.104.1 dst-port=18291 protocol=tcp to-addresses=\
    192.168.116.30 to-ports=8291
add action=dst-nat chain=dstnat comment="REDIRECIONAMENTO TS SIX" \
    dst-address=177.72.104.1 dst-port=15389 protocol=tcp to-addresses=\
    192.168.66.14 to-ports=15389
add action=src-nat chain=srcnat comment="NAT GERAL" dst-address=\
    !192.168.116.30 src-address-list=NAT to-addresses=177.72.104.1
add action=src-nat chain=srcnat comment="NAT GERAL" dst-address-list=\
    !FORA_DO_NAT_RADIUS src-address-list=NAT_RADIUS to-addresses=177.72.104.1
/ip firewall raw
add action=accept chain=prerouting protocol=icmp
add action=accept chain=prerouting protocol=igmp
add action=accept chain=prerouting protocol=tcp
add action=accept chain=prerouting protocol=udp
add action=accept chain=prerouting protocol=gre
add action=log chain=prerouting log=yes log-prefix="Not TCP protocol" \
    protocol=!tcp
add action=drop chain=prerouting comment="Unused protocol protection" \
    disabled=yes protocol=!tcp
/ip firewall service-port
set h323 disabled=yes
set sip disabled=yes ports=5060,5061,5063
set udplite disabled=yes
set dccp disabled=yes
/ip route
add comment=NETPAL distance=1 gateway=192.168.116.33
add distance=1 dst-address=10.8.0.0/21 gateway=177.72.104.9
add distance=1 dst-address=10.30.0.0/30 gateway=177.72.104.19
add distance=1 dst-address=10.150.150.0/24 gateway=177.72.104.19
add distance=1 dst-address=10.254.0.0/22 gateway=177.72.104.12
add comment="ROTA DNS" disabled=yes distance=1 dst-address=177.72.104.56/30 \
    gateway=177.72.104.28
add comment="DNS loopback 58 via ns-netpal" distance=1 dst-address=\
    177.72.104.58/32 gateway=177.72.104.28
add comment="DNS loopback 59 via ns-netpal" distance=1 dst-address=\
    177.72.104.59/32 gateway=177.72.104.28
add distance=1 dst-address=192.168.88.0/24 gateway=1.1.1.3
/ip service
set telnet disabled=yes port=2323
set ftp address=177.93.240.0/21,177.72.104.0/21,192.168.115.0/24
set www disabled=yes port=8858
set ssh address=177.93.240.0/21,177.72.104.0/21,1.1.1.0/24 port=15320
set api address=177.72.104.0/21,177.72.104.0/21,1.1.1.0/24
set winbox address=\
    177.72.104.0/21,177.93.240.0/21,10.7.0.0/24,192.168.116.28/30
set api-ssl disabled=yes
/ip ssh
set forwarding-enabled=both strong-crypto=yes
/lcd
set time-interval=daily
/routing filter
add action=accept chain=ospf-in prefix=177.72.104.56/30
/routing ospf interface
add interface=loopback network-type=broadcast passive=yes
add authentication=md5 authentication-key=ntprb1030 interface=\
    "sfp1 - UPLINK SW TOPO DO RACK" network-type=point-to-point
add authentication=md5 authentication-key=ntprb1030 interface="VLAN13 - DUDE" \
    network-type=point-to-point
add authentication=md5 authentication-key=ntprb1030 interface=\
    "Bridge IP Publico" network-type=point-to-point
add authentication=md5 authentication-key=ntprb1030 interface=ether3 \
    network-type=point-to-point
add authentication=md5 authentication-key=ntprb1030 interface=\
    "VLAN713 - GW SOLIDAO" network-type=point-to-point
add authentication=md5 authentication-key=ntprb1030 interface=VLAN11_eoip \
    network-type=point-to-point
/routing ospf network
add area=area1 network=177.72.104.0/27
add area=area1 network=172.16.200.5/32
add area=area1 network=192.168.123.12/30
add area=area1 network=192.168.116.32/30
add area=area1 network=192.168.115.12/30
add area=area1 network=192.168.123.20/30
add area=area1 network=192.168.123.24/30
add area=area1 network=192.168.115.36/30
add area=area1 network=192.168.115.60/30
add area=area1 network=192.168.115.40/30
add area=area1 network=192.168.15.0/30
add area=area1 network=177.72.104.52/30
add area=area1 network=192.168.115.100/30
add area=area1 network=192.168.15.16/30
add area=area1 network=192.168.115.140/30
add area=area1 network=192.168.116.16/30
add area=area1 network=192.168.116.36/30
add area=area1 network=192.168.123.0/30
add area=area1 network=172.18.255.160/27
add area=area1 network=192.168.116.120/30
add area=area1 network=192.168.116.28/30
add area=area1 network=172.31.254.32/30
add area=area1 network=10.7.0.0/24
add area=area1 network=192.168.116.24/30
add area=area1 network=192.168.15.48/30
add area=area1 network=192.168.17.44/30
add area=area1 network=172.31.254.28/30
add area=area1 network=192.168.116.20/30
add area=area1 network=192.168.115.20/30
add area=area1 network=192.168.115.136/30
add area=area1 network=10.200.255.252/30
add area=area1 network=192.168.116.196/30
add area=area1 network=192.168.90.0/24
add area=area1 network=192.168.1.0/24
add area=area1 network=10.200.255.248/30
/snmp
set contact=noc@netpal.com.br enabled=yes location="Capivari do Sul"
/system clock
set time-zone-name=America/Sao_Paulo
/system identity
set name="GW Servidores"
/system logging
set 0 topics=info,!firewall,!ospf
/system ntp client
set enabled=yes primary-ntp=192.168.116.10 secondary-ntp=192.168.116.10
/system scheduler
add interval=1w name=backup_ftp on-event="/system script run backup_ftp" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive \
    start-date=dec/17/2019 start-time=12:00:00
/system script
add dont-require-permissions=yes name=backup_ftp owner=jdf policy=\
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
    \n:log warning \"****;"
add dont-require-permissions=no name=dude owner=jdf policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n/tool fetch keep-result=no url=\"https://api.focuschat.com.br/core/v2/ap\
    i/chats/send-text\?accessToken=651d642ceb448515516f8c3c&number=6542a8153b2\
    1a45acd288931&message=%E2%9C%85%F0%9F%98%83ONLINE%E2%9C%85%0ADispositivo=[\
    Device.Name]%0AIP=[Device.FirstAddress] %0ASERVI\C3\87O=[Probe.Name]%0ASta\
    tus= [Service.Status]%0ATempo OFF= [Service.TimeLastDown]&forceSend=true&v\
    erifyContact=false&isWhisper=false\""
/tool bandwidth-server
set authenticate=no
/tool sniffer
set filter-interface="ether10 - RB750 Bridge" filter-mac-address=\
    84:2B:2B:5A:45:55/FF:FF:FF:FF:FF:FF filter-operator-between-entries=and \
    memory-scroll=no
