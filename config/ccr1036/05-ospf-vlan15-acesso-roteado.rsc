# ============================================================
# CCR1036 - 05-ospf-vlan15-acesso-roteado.rsc
# OSPF area 0.0.0.1 + VLAN 15/NTP + regras de acesso roteado
# RouterOS 7.23.3 - 2026-08-06
# CCR isolada (SFP desconectado): OSPF nao vai validar adjacencia
# ate o trunk ser ligado ao DM4170 - isso e esperado.
# ============================================================

# ---------- 1. VLAN 15 / NTP ----------
/interface vlan
add name=vlan15-NTP vlan-id=15 interface=sfp1-TRUNK-DM comment="NTP container 192.168.116.10"

/ip address
add address=192.168.116.9/30 interface=vlan15-NTP comment="GW NTP"

# ---------- 2. OSPF area 0.0.0.1 (NE8000 .1 <-> CCR .4, MD5 ntprb1030 - decisao #11) ----------
/routing ospf instance
add name=ospf1 router-id=177.72.104.4

/routing ospf area
add name=area0.0.0.1 area-id=0.0.0.1 instance=ospf1

# ROS 7: /routing ospf interface e READ-ONLY - configurar via interface-template.
# Sintaxe real do firmware instalado (confirmada com "?") : auth-key (NAO
# authentication-key, que da bad parameter) e passive como flag pura (sem =yes,
# que da expected end of command). prefix-suppression nao existe no template.
# auth-id=1 casa com o NE8000 (ospf authentication-mode md5 1 plain ntprb1030).
# O /27 sera anunciado como stub na area, mas o NE8000 tem rota conectada
# (preferencia maior) e filtro de entrada - inofensivo.
/routing ospf interface-template
add interfaces=vlan16-PUBLICA area=area0.0.0.1 type=ptp auth=md5 auth-id=1 auth-key=ntprb1030 comment="OSPF NE8000"

# VLANs privadas anunciadas passivamente (sem adjacencia)
/routing ospf interface-template
add interfaces=vlan100-PRIVADA area=area0.0.0.1 passive comment="OSPF PASSIVA VLAN 100"
add interfaces=vlan15-NTP area=area0.0.0.1 passive comment="OSPF PASSIVA VLAN 15"

# ---------- 3. Regras de firewall (script 04 - acesso roteado) ----------
/ip firewall address-list
add list=ORIGENS-GERENCIA address=177.72.104.19 comment="SERVIDOR WIREGUARD"
add list=ORIGENS-GERENCIA address=177.93.244.165 comment="NOC"
add list=ORIGENS-GERENCIA address=10.150.150.0/24 comment="CLIENTES WIREGUARD"
add list=REDES-PRIVADAS address=192.168.254.0/24 comment="VLAN 100"

/ip firewall filter
# 3.1 Gerencia roteada -> redes privadas (retorno passa por ESTABLISHED/RELATED)
add chain=forward action=accept src-address-list=ORIGENS-GERENCIA dst-address-list=REDES-PRIVADAS place-before=[find comment="FORWARD - DROP FINAL"] comment="FORWARD - GERENCIA PARA REDES PRIVADAS"

# 3.2 Input OSPF exclusivo do peer NE8000 (VLAN 16)
add chain=input action=accept protocol=ospf src-address=177.72.104.1 in-interface=vlan16-PUBLICA place-before=[find comment="INPUT - DROP FINAL"] comment="INPUT - OSPF NE8000"

# 3.3 NTP: consulta UDP/123 ao container 192.168.116.10 (VLAN 15)
#     Origem irrestrita de proposito: a CCR so encaminha redes que ela roteia.
#     O NE8000 precisa da liberacao equivalente do lado dele (APs/sites).
add chain=forward action=accept protocol=udp dst-port=123 dst-address=192.168.116.10 place-before=[find comment="FORWARD - DROP FINAL"] comment="NTP - LIBERA CONSULTA UDP 123"

# ---------- 4. Cliente NTP da propria CCR ----------
/system ntp client
set enabled=yes servers=192.168.116.10
