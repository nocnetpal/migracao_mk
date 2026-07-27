# Base L2 — bridge-servidores no RB3011 (rodar 1× na noite do Docker, antes do docker-m1)
# VLAN 100 = 192.168.254.0/24 · GW .1
# VLAN 16 = tagged → Bridge IP Publico
# NÃO APLICAR em horário comercial.

# Se bridge-servidores já existir, pular este arquivo e ir ao *-m1 do host.

/interface bridge add name=bridge-servidores vlan-filtering=yes protocol-mode=none \
  comment="Etapa1 VLAN100 gerencia + VLAN16 publico"

/interface vlan add name=vlan100-servidores vlan-id=100 interface=bridge-servidores \
  comment="GERENCIA SERVIDORES 192.168.254.0/24"
/interface vlan add name=vlan16-servidores vlan-id=16 interface=bridge-servidores \
  comment="IP PUBLICO tagged dos servidores"

/ip address add address=192.168.254.1/24 interface=vlan100-servidores \
  comment="GW VLAN100 hypervisors"

/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 tagged=bridge-servidores
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 tagged=bridge-servidores

/interface bridge port add bridge="Bridge IP Publico" interface=vlan16-servidores

/ip address print where address~"192.168.254.1"
/interface bridge print where name=bridge-servidores
/ping 192.168.254.1 count=2
