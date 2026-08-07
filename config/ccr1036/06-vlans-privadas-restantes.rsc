# ============================================================
# CCR1036 - 06-vlans-privadas-restantes.rsc
# VLANs privadas locais restantes: 66 (TS SIX), 109 (OLT CPV),
# 116 (Dude/legado) - RouterOS 7.23.3 - 2026-08-06
# Gateways herdados do RB3011 (export pre-etapa1-2026-08-04).
# vlan10 (DNS recursivo) e vlan999 (Callcenter) fora do plano.
# CCR isolada (SFP desconectado): redes sem resposta ate o trunk
# ser ligado ao DM4170 - esperado.
# ============================================================

# ---------- 1. VLANs + gateways ----------
/interface vlan
add name=vlan66-TS-SIX vlan-id=66 interface=sfp1-TRUNK-DM comment="TS SIX 192.168.66.14/28 (era ether6 RB3011)"
add name=vlan109-OLT-CPV vlan-id=109 interface=sfp1-TRUNK-DM comment="OLT CPV 192.168.115.42/30 (era ether9 RB3011)"
add name=vlan116-DUDE vlan-id=116 interface=sfp1-TRUNK-DM comment="DUDE/legado 192.168.116.30/30 (era Bridge IP Publico RB3011)"

/ip address
add address=192.168.66.1/28 interface=vlan66-TS-SIX comment="GW TS SIX"
add address=192.168.115.41/30 interface=vlan109-OLT-CPV comment="GW OLT CPV"
add address=192.168.116.29/30 interface=vlan116-DUDE comment="GW DUDE/legado"

# ---------- 2. OSPF: redes anunciadas passivamente (mesmo padrao do 05) ----------
# Sintaxe real do firmware: auth-key (nao authentication-key), passive como flag pura.
/routing ospf interface-template
add interfaces=vlan66-TS-SIX area=area0.0.0.1 passive comment="OSPF PASSIVA VLAN 66"
add interfaces=vlan109-OLT-CPV area=area0.0.0.1 passive comment="OSPF PASSIVA VLAN 109"
add interfaces=vlan116-DUDE area=area0.0.0.1 passive comment="OSPF PASSIVA VLAN 116"

# ---------- 3. Acesso roteado da gerencia (complementa o script 04) ----------
# Redes privadas alcancaveis de ORIGENS-GERENCIA (177.72.104.19, 177.93.244.165,
# 10.150.150.0/24) - regra FORWARD do 04 usa REDES-PRIVADAS.
/ip firewall address-list
add list=REDES-PRIVADAS address=192.168.66.0/28 comment="VLAN 66 - TS SIX"
add list=REDES-PRIVADAS address=192.168.115.40/30 comment="VLAN 109 - OLT CPV"
add list=REDES-PRIVADAS address=192.168.116.28/30 comment="VLAN 116 - DUDE"

# ---------- Pendencia (nao incluir ainda) ----------
# DST-NAT TS SIX (:15389 -> 192.168.66.14) aguarda a decisao #9 (.1 vs .4) no 03.
