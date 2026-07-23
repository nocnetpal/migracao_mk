# Migração Mikrotik → Datacom

## Objetivo

Remover o(s) Mikrotik(s) que hoje atuam como gateway/roteador da rede e substituir por:

- **Switch Datacom L3**: assume roteamento entre VLANs (inter-VLAN routing) e conexão direta com o NE8000.
- **Huawei NE8000** (já existente, "acima" na topologia): assume firewall L3 e o bloco IP público
  `/27` (o Datacom não suporta NAT, confirmado). 🆕 **NAT em si vai para a CCR1036**, não para o
  NE8000 — correção do usuário em 2026-07-23 (ver
  [03-decisoes-pendentes.md](03-decisoes-pendentes.md)).

## Motivação

- Tirar o Mikrotik do caminho crítico (hoje é ponto único de falha).
- Ganho de performance/throughput (Datacom com capacidade maior que o MK atual).
- Padronizar com o resto da infraestrutura, que já usa Datacom.
- Aproveitar a troca para remover **outros equipamentos Mikrotik** que hoje compõem esse mesmo trecho da rede (não só o gateway principal) — lista completa em levantamento, ver [01-inventario-atual.md](01-inventario-atual.md).

## Status

📋 Fase atual: **inventário técnico do RB3011/RB2011 concluído; plano de corte em rascunho v1.**

- ✅ Inventário completo da GW Servidores (IPs, VLANs/QinQ, portas, bridges, OSPF, NAT, VPNs, DHCP,
  automações) — [07](07-enderecamento-ip.md) e [08](08-vlans-e-portas.md)
- ✅ Decisões fechadas: DHCP trivial (1 escopo); natureza das VPNs (L2TP sem criptografia +
  OpenVPN); **dono do `/27` → NE8000, mas NAT → CCR1036** (decisões #1/#9/#8, corrigidas
  2026-07-23 — mecanismo exato de roteamento do IP de NAT até a CCR1036 ainda em aberto)
- 🆕 **Desenho alvo definido pelo usuário (2026-07-23):** saem RB3011 + RB2011; entram **DM4170**
  (no lugar do RB3011) e **CCR1036** (VPN + automações + cobre dos servidores, ligada direto ao
  NE8000); a **rede de acesso não é tocada**. Firewall redesenhado enxuto (sem
  geo-allowlist BRASIL). Trabalho na ordem: físico → L2 → L3 — ver [02](02-arquitetura-alvo.md)
- 📝 Plano de corte rascunhado ([04](04-plano-migracao.md)): estratégia fatiada por VLAN + janela
  única para o núcleo
- ⏳ Principais bloqueios: confirmações DmOS com a Datacom (**SVI sobre tag interna QinQ** — o
  DM4170 herda as SVIs do RB3011; limite de IPs secundários; MTU); lista de sistemas vivos
  ([05](05-limpeza-politicas.md), passo 1); sobreposição do `177.72.104.60/30` (decisão #10).
  📌 Escopo fechado: **a rede de acesso não será mexida** — corte do trunk em janela única (troca
  de cabo)
- 🆕 **Cruzamento com o Dude** ([11](11-cruzamento-dude-devices.md)): forte candidato ao switch de
  topo do rack identificado (**Huawei S6730 "Jardim Formoso"**, ainda sem confirmação física);
  vários nomes de sistema no firewall do RB3011 estão **desatualizados** frente ao monitoramento
  ao vivo (ex.: `.8` "Hubsoft" parece morto, o real é `.16`); descobertas **duas VPNs adicionais**
  fora do RB3011 (WireGuard em `.19`, OpenVPN-2 em `.12`) que podem não fazer parte da decisão #5

## Índice dos documentos

- [01-inventario-atual.md](01-inventario-atual.md) — o que existe hoje (equipamentos Mikrotik, funções)
- [02-arquitetura-alvo.md](02-arquitetura-alvo.md) — desenho da rede depois da migração
- [03-decisoes-pendentes.md](03-decisoes-pendentes.md) — pontos ainda em aberto
- [04-plano-migracao.md](04-plano-migracao.md) — plano de corte (a ser preenchido)
- [05-limpeza-politicas.md](05-limpeza-politicas.md) — redesenho limpo do firewall/NAT (não portar 1:1)
- [06-ne8000-bgp-core.md](06-ne8000-bgp-core.md) — o que o NE8000 realmente é (core BGP/OSPF da rede)
- [07-enderecamento-ip.md](07-enderecamento-ip.md) — levantamento de todos os IPs públicos/privados usados na GW Servidores
- [08-vlans-e-portas.md](08-vlans-e-portas.md) — topologia L2 (QinQ, portas físicas, EoIP, OSPF) da GW Servidores
- [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md) — mapeamento VLAN a VLAN para o desenho alvo (etapa L2)
- [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md) — endereçamento da CCR1036 e dos servidores locais
- [11-cruzamento-dude-devices.md](11-cruzamento-dude-devices.md) — cruzamento com o monitoramento do Dude (`Devices.csv`): candidato ao switch de topo do rack, nomes de sistema desatualizados, VPNs adicionais
- [12-mapeamento-proxmox.md](12-mapeamento-proxmox.md) — os 4 clusters Proxmox, hypervisor + VMs (públicas e privadas), com todos os IPs
