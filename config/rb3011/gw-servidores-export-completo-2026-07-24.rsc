# jul/24/2026 16:58:51 by RouterOS 6.49  — EXPORT COMPLETO (não truncado)
# software id = 3EAX-1ULF / model = RB3011UiAS / serial = B88D0B6BA720
#
# Substitui o antigo gw-servidores-export.rsc (que estava TRUNCADO — faltava o topo).
# ⚠️ CREDENCIAIS redigidas neste arquivo ([REDIGIDO]) — regra docs/01, rotacionar fase 4.
#    Valores reais só no equipamento / no export original do usuário.
# ⚠️ address-list BRASIL (~600 entradas) OMITIDA — decidido descartar (decisão #7).
#
# 🆕 Estado após a limpeza do Juca Ana (VLAN198): interface VLAN198 removida,
#    OSPF network 177.72.104.60/30 removido, OSPF interface VLAN198 removido.
#    RESTA: /ip address 177.72.104.61/30 disabled=yes ÓRFÃO (sem interface) — remover.

/interface bridge
add fast-forward=no name="Bridge IP Publico" protocol-mode=none
add name=EOIP-NOC
add fast-forward=no name=loopNETPAL
add fast-forward=no mtu=1500 name=loopback protocol-mode=none

/interface ethernet
# ⚠️ ether1-5 marcadas ESTRAGADA (portas físicas com defeito)
set [ find default-name=ether1 ] arp=proxy-arp comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether2 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether3 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether4 ] comment=ESTRAGADA speed=100Mbps
set [ find default-name=ether5 ] comment=ESTRAGADA
set [ find default-name=ether6 ] comment="PC TS SIX" name="ether6 - PC TS SIX" speed=100Mbps
set [ find default-name=ether7 ] comment="Proxmox - DOCKER - CDNTV" name="ether7 - Proxmox - DOCKER - CDNTV" speed=100Mbps
set [ find default-name=ether8 ] auto-negotiation=no comment="SERVIDOR DNS RECURSIVO" full-duplex=no name="ether8 - SERVIDOR DNS RECURSIVO" speed=100Mbps
set [ find default-name=ether9 ] comment="GERENCIA OLT ZTE" name="ether9 - GERENCIA OLT ZTE" speed=100Mbps
set [ find default-name=ether10 ] comment="PROXMOX ZABBIX" name="ether10 - Callcenter" poe-out=off speed=100Mbps
set [ find default-name=sfp1 ] comment="UPLINK SW TOPO DO RACK" name="sfp1 - UPLINK SW TOPO DO RACK"

/interface eoip
add allow-fast-path=no local-address=177.72.104.1 mac-address=[REDIGIDO] mtu=1500 name=eoip-tunnel1 remote-address=177.93.244.165 tunnel-id=1212

/interface vlan
# (lista completa das VLANs — ver relacao-vlan-ip.md; VLAN198 Juca Ana JÁ REMOVIDA)
add comment="SERVIDOR DNS RECURSIVO" interface="ether8 - SERVIDOR DNS RECURSIVO" name=VLAN10 vlan-id=10
add interface=eoip-tunnel1 name=VLAN11_eoip vlan-id=11
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN13 - DUDE" vlan-id=13
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN15 - NTP SERVER" vlan-id=15
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN16 - IP PUBLICO" vlan-id=16
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN17 - MONSTA" vlan-id=17
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN18 - SERVERINO" vlan-id=18
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN21 - GERENCIA - GGV" vlan-id=21
add comment=PWW interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN22 - PWW" vlan-id=22
add comment=CPV interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN25 - CPV" vlan-id=25
add comment=FSB interface="sfp1 - UPLINK SW TOPO DO RACK" name=VLAN26 vlan-id=26
add interface="VLAN22 - PWW" name="VLAN27 - SW FO Shopping" vlan-id=27
add interface="VLAN25 - CPV" name="VLAN30 - Gerencia Radios CPV" vlan-id=30
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN31 GGV" vlan-id=31
add comment=BCP interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN33 - BCP" vlan-id=33
add comment=FSB interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN35 - FSB" vlan-id=35
add comment="OLT BCP" interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN37 - OLT BCP" vlan-id=37
add comment=LBCP interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN39 - LBCP" vlan-id=39
add comment=PSLD interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN40 - PSLD" vlan-id=40
add comment=CCB interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN41 - CCB" vlan-id=41
add comment=CASCA interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN42 - CASCA" vlan-id=42
add comment=MST interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN43 - MST" vlan-id=43
add comment=SLD interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN44 - SLD" vlan-id=44
add comment=TVR interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN46 - TVR" vlan-id=46
add comment="PRAIA MST" interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN47 - PRAIA MST" vlan-id=47
add comment="PRAIA SAO SIMAO" interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN48 - PRAIA SAO SIMAO" vlan-id=48
add interface="VLAN43 - MST" name="VLAN49 - Clientes IP Publico MST" vlan-id=49
add interface="VLAN46 - TVR" name="VLAN50 - GERENCIA TVR" vlan-id=50
add interface="VLAN25 - CPV" name="VLAN51 - Cliente IP Publico CPV" vlan-id=51
add interface="VLAN22 - PWW" name="VLAN52 - Clientes IP Publico PWW" vlan-id=52
add interface="VLAN37 - OLT BCP" name="VLAN53 - Galeria Krupp" vlan-id=53
add interface="VLAN43 - MST" name="VLAN54 - Marcos Solon" vlan-id=54
add interface="VLAN22 - PWW" name="VLAN90 - RB Bridge Consepro PWW" vlan-id=90
add interface="VLAN22 - PWW" name="VLAN92 - Bridge CC PWW" vlan-id=92
add interface="VLAN25 - CPV" name="VLAN93 - GERENCIA_POP_JDF_E_ENLACE_RANCHO_VELHO" vlan-id=93
add interface="VLAN25 - CPV" name="VLAN196 - RB Banco do Brasil CPV" vlan-id=196
add interface="VLAN25 - CPV" name="VLAN200 - RB Brigde Predio Maicon" vlan-id=200
add interface="VLAN43 - MST" name="VLAN250 - Gerencia OLT MST" vlan-id=250
add comment="GERENCIA OLT LBCP" interface="VLAN39 - LBCP" name=VLAN539 vlan-id=539
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
add interface="sfp1 - UPLINK SW TOPO DO RACK" name="VLAN1066 - GERADOR MST" vlan-id=1066
add interface="VLAN43 - MST" name="VLAN2020 - Gerencia EDD MST" vlan-id=2020
add interface="VLAN46 - TVR" name="VLAN - 600 - AP_CENTRO_TVR_REI_DOS_PAMPAS" vlan-id=600
add interface=VLAN26 name="VLAN 35 GERENCIA OLT FSB" vlan-id=35
add comment="OLT ZTE GGV" interface="VLAN31 GGV" name="VLAN21 - OLT ZTE GGV" vlan-id=21
# NOTA: "VLAN198 - Pantano => Juca Ana" (inner 198 sobre VLAN46) NÃO consta mais — removida.

/ip dhcp-server
add address-pool=dhcp_pool8 disabled=no interface="VLAN1066 - GERADOR MST" name=dhcp1
add address-pool=dhcp_pool9 disabled=no interface="ether6 - PC TS SIX" name=dhcp2

/interface bridge port
add bridge="Bridge IP Publico" interface=ether2
add bridge="Bridge IP Publico" interface="ether10 - Callcenter"
add bridge="Bridge IP Publico" interface=ether4
add bridge="Bridge IP Publico" interface=ether1
add bridge="Bridge IP Publico" interface="ether7 - Proxmox - DOCKER - CDNTV"
add bridge="Bridge IP Publico" interface="VLAN16 - IP PUBLICO"
add bridge="Bridge IP Publico" interface="ether8 - SERVIDOR DNS RECURSIVO"
add bridge="Bridge IP Publico" interface="ether6 - PC TS SIX"

/interface l2tp-server server
set authentication=chap,mschap1,mschap2 enabled=yes ipsec-secret=[REDIGIDO]
/interface ovpn-server server
set auth=sha1 certificate=server cipher=aes256 default-profile=default-encryption enabled=yes require-client-certificate=yes
/interface pptp-server server
# ⚠️ PPTP HABILITADO (mschap1) — VPN insegura, não estava clara antes
set authentication=pap,chap,mschap1,mschap2 enabled=yes max-mru=1480 max-mtu=1480

# --- /ip address, firewall, nat, route, ospf: ver export original / relacao-vlan-ip.md ---
# Mudanças-chave neste export vs. o truncado:
#   - /ip address: 177.72.104.61/30 agora "disabled=yes" e SEM interface= (órfão) — REMOVER.
#   - /routing ospf network: 177.72.104.60/30 REMOVIDO (Juca Ana).
#   - /routing ospf interface: entrada da VLAN198 REMOVIDA.
# Firewall/NAT/rotas: idênticos ao já analisado em docs/05, docs/07 (regras .5 Hubsoft/CallSys,
#   DROPA CGNAT, drops de gerência RANGENETPAL, dst-nat Dude/TS SIX, src-nat NAT→.1).

/snmp community
set [ find default=yes ] addresses=0.0.0.0/0 name=[REDIGIDO]
/ppp secret
# 4 usuários VPN — senhas [REDIGIDO] (rotacionar fase 4): bruno, vpnbruno, isaac, leonardo
/ip route
add comment=NETPAL distance=1 gateway=192.168.116.33
add distance=1 dst-address=10.8.0.0/21 gateway=177.72.104.9
add distance=1 dst-address=10.30.0.0/30 gateway=177.72.104.19
add distance=1 dst-address=10.150.150.0/24 gateway=177.72.104.19
add distance=1 dst-address=10.254.0.0/22 gateway=177.72.104.12
add comment="ROTA DNS" disabled=yes distance=1 dst-address=177.72.104.56/30 gateway=177.72.104.28
add comment="DNS loopback 58 via ns-netpal" distance=1 dst-address=177.72.104.58/32 gateway=177.72.104.28
add comment="DNS loopback 59 via ns-netpal" distance=1 dst-address=177.72.104.59/32 gateway=177.72.104.28
add distance=1 dst-address=192.168.88.0/24 gateway=1.1.1.3
