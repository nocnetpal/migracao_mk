# aug/04/2026 17:14:32 by RouterOS 6.49
# Export POS-Fase-1A (bridge-servidores criada, ether7 ainda na Bridge IP Publico)
# Próximo passo: Fase 1B na madrugada — mover ether7 para bridge-servidores

# Estado atual:
# - bridge-servidores: criada, vlan-filtering=yes, VLANs 100+16 configuradas
# - 192.168.254.1/24: ativo em vlan100-servidores
# - vlan16-servidores: porta da Bridge IP Publico
# - ether7: AINDA na Bridge IP Publico (será movido na Fase 1B)