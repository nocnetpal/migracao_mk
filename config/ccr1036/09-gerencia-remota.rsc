# ============================================================
# CCR1036 - 09-gerencia-remota.rsc
# Gerencia remota da CCR em producao - RouterOS 7.23.3 - 2026-08-06
# /ip service sozinho nao basta: o INPUT - DROP FINAL bloqueia antes.
# winbox/ssh: bancada (192.168.88.0/24) + /27 publico + NOC.
# Desabilita ovpn-server1 (estava habilitado no export pre-corte).
# ============================================================

/ip service
set winbox address=192.168.88.0/24,177.72.104.0/27,177.93.244.165
set ssh address=192.168.88.0/24,177.72.104.0/27,177.93.244.165

/ip firewall filter
add chain=input action=accept src-address=177.72.104.0/27 place-before=[find comment="INPUT - DROP FINAL"] comment="INPUT - GERENCIA /27"
add chain=input action=accept src-address=177.93.244.165 place-before=[find comment="INPUT - DROP FINAL"] comment="INPUT - GERENCIA NOC"

/interface ovpn-server server
set ovpn-server1 disabled=yes
