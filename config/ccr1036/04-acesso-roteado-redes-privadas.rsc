# PLANEJADO/NAO APLICADO ate a ultima validacao de 2026-08-06.
# Origens autorizadas a acessar as redes privadas por roteamento.
/ip firewall address-list
add list=ORIGENS-GERENCIA address=177.72.104.19 comment="SERVIDOR WIREGUARD"
add list=ORIGENS-GERENCIA address=177.93.244.165 comment="NOC"
add list=ORIGENS-GERENCIA address=10.150.150.0/24 comment="CLIENTES WIREGUARD"
add list=REDES-PRIVADAS address=192.168.254.0/24 comment="VLAN 100"

# Inserir antes do drop final; retorno passa por ESTABLISHED/RELATED.
/ip firewall filter
add chain=forward action=accept src-address-list=ORIGENS-GERENCIA dst-address-list=REDES-PRIVADAS place-before=[find comment="FORWARD - DROP FINAL"] comment="FORWARD - GERENCIA PARA REDES PRIVADAS"

# Permitir exclusivamente o peer NE8000 para a futura adjacencia OSPF sobre a VLAN 16.
add chain=input action=accept protocol=ospf src-address=177.72.104.1 in-interface=vlan16-PUBLICA place-before=[find comment="INPUT - DROP FINAL"] comment="INPUT - OSPF NE8000"
