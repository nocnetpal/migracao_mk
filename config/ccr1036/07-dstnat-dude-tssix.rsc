# ============================================================
# CCR1036 - 07-dstnat-dude-tssix.rsc
# DST-NAT Dude e TS SIX na CCR .15 (decisao #9, fechada 2026-08-06; IP trocado 2026-08-07)
# RouterOS 7.23.3 - 2026-08-06
# Quem acessa de fora passa a usar 177.72.104.15 (era 177.72.104.1).
# A regra FORWARD - DSTNAT (connection-nat-state=dstnat) ja existe.
# Sem restricao de origem, igual ao RB3011 original.
# dst-address adicionado 2026-08-07: sem ele, a regra casa qualquer destino nessas
# portas (nao so o .15) e sequestraria transito de clientes WireGuard, por exemplo.
# ============================================================

/ip firewall nat
add chain=dstnat action=dst-nat dst-address=177.72.104.15 to-addresses=192.168.116.30 to-ports=8291 dst-port=18291 protocol=tcp comment="DUDE - era .1:18291"
add chain=dstnat action=dst-nat dst-address=177.72.104.15 to-addresses=192.168.66.14 to-ports=15389 dst-port=15389 protocol=tcp comment="TS SIX - era .1:15389"
