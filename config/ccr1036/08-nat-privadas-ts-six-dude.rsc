# ============================================================
# CCR1036 - 08-nat-privadas-ts-six-dude.rsc
# Inclui TS SIX (66) e Dude (116) no SRC-NAT para 177.72.104.15
# RouterOS 7.23.3 - 2026-08-06
# No RB3011, a lista NAT tinha 192.168.66.0/28 e 192.168.116.28/30.
# OLT CPV (109) NAO fazia NAT no RB3011 (so gerencia) - fora.
# DNS publico (.28/.58/.59) e roteado pelo NE8000; a consulta dos
# servidores privados sai mascarada como .4 pela VLAN 16 - sem regra
# DNS especifica, o forward PRIVADAS PARA INTERNET + SRC-NAT cobrem.
# ============================================================

/ip firewall address-list
add list=NAT-PRIVADAS address=192.168.66.0/28 comment="VLAN 66 - TS SIX"
add list=NAT-PRIVADAS address=192.168.116.28/30 comment="VLAN 116 - DUDE"
