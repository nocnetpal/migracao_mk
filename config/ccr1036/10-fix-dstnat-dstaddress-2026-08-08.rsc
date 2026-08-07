# ============================================================
# CCR1036 - 10-fix-dstnat-dstaddress-2026-08-08.rsc
# Completa a troca .4 -> .15: os DST-NAT do Dude e TS SIX ficaram
# sem dst-address (casavam qualquer destino nas portas 18291/15389,
# o que sequestraria transito de clientes WireGuard de passagem).
# Rodar uma vez: /import file=10-fix-dstnat-dstaddress-2026-08-08.rsc
# ============================================================

/ip firewall nat set [find comment="DUDE - era .1:18291"] dst-address=177.72.104.15
/ip firewall nat set [find comment="TS SIX - era .1:15389"] dst-address=177.72.104.15

:put "FIX APLICADO - conferindo:"
/ip firewall nat print
