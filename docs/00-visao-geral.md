# Migração Mikrotik → Datacom

## Objetivo

Remover o(s) Mikrotik(s) que hoje atuam como gateway/roteador da rede e substituir por:

- **Switch Datacom DM4170**: ~~assume roteamento entre VLANs (inter-VLAN routing)~~ → 🆕 **fica só
  em L2** (decisão #13, 2026-07-24) — faz QinQ termination e entrega tudo num trunk até o NE8000;
  conexão direta com o NE8000.
- **Huawei NE8000** (já existente, "acima" na topologia): assume firewall L3, o bloco IP público
  `/27` (o Datacom não suporta NAT, confirmado) **e agora também o roteamento inter-VLAN** (SVIs +
  OSPF area1) que seria do DM4170 — decisão #13. 🆕 **NAT em si vai para a CCR1036**, não para o
  NE8000 — correção do usuário em 2026-07-23 (ver
  [03-decisoes-pendentes.md](03-decisoes-pendentes.md)).

## Motivação

- Tirar o Mikrotik do caminho crítico (hoje é ponto único de falha).
- Ganho de performance/throughput (Datacom com capacidade maior que o MK atual).
- Padronizar com o resto da infraestrutura, que já usa Datacom.
- Aproveitar a troca para remover **outros equipamentos Mikrotik** que hoje compõem esse mesmo trecho da rede (não só o gateway principal) — lista completa em levantamento, ver [01-inventario-atual.md](01-inventario-atual.md).

## Status — fotografia atual (2026-08-07)

> 📜 O histórico detalhado de como cada ponto evoluiu está no `git log` e nos docs temáticos
> (com as correções em ~~riscado~~). **Decisões: todas as 14 fechadas** — sumário-tabela no topo
> do [03-decisoes-pendentes.md](03-decisoes-pendentes.md).

**Fase atual:** aguardando agendamento da **próxima janela** (previsão: semana de 2026-08-10,
**data ainda não marcada**) — instalar DM4170 + CCR no rack e migrar os servidores 177
([runbook-noite.html](runbook-noite.html) é o passo a passo oficial; estratégia em
[15](15-plano-migracao-servidores-177.md)). O QinQ **fica no RB3011** — corte do trunk é janela
futura. 📌 Escopo fechado: **a rede de acesso não é tocada.**

### Papéis (desenho fechado)

| Equipamento | Papel |
|---|---|
| DM4170 24GX+12XS | **Só L2** (decisão #13): QinQ termination + agregação física dos servidores |
| NE8000 | Dono do `/27` (SVI VLAN 16, `.1`) + firewall L3 + SVIs das VLANs de acesso; segue core BGP/OSPF ([06](06-ne8000-bgp-core.md)) |
| CCR1036 8G-2S+ | NAT (**`177.72.104.15`** na VLAN 16) + gateway das redes privadas locais + WireGuard (só pós-migração); único uplink = trunk com o DM4170 |
| RB3011 + RB2011 | **Saem** (RB3011 mantém o QinQ até a janela futura) |
| RB750 | **Fica** com o WireGuard `.19` até a VPN migrar pra CCR (pós-migração) |

### ✅ Pronto

- **4 Proxmox migrados (2026-08-05):** hosts `.10`–`.13` na VLAN 100 (`192.168.254.0/24`, GW `.1`),
  VMs públicas tag 16 — [16](16-etapa1-proxmox-vlans-datacom.md)
- **CCR1036 100% em bancada (2026-08-06, scripts 01–09):** VLANs 15/16/66/100/109/116, OSPF
  (ptp+MD5 com o NE8000, privadas passivas), firewall, SRC-NAT, DST-NAT Dude/TS SIX, gerência
  remota, backup pré-corte — [`config/ccr1036/`](../config/ccr1036/).
  ⚠️ **Ainda está com `.4` — trocar para `.15` antes do trunk subir** (passo 3 do
  [runbook-noite.html](runbook-noite.html): inclui router-id do OSPF e `dst-address` dos DST-NAT;
  os `.rsc` antigos têm `.4`, não re-executar)
- **DM4170 em bancada (2026-08-07):** DmOS 12.4.0, hostname `DM4170-SW_SERVIDORES`, SNTP/SNMP/ACL
  de CPU, VLANs 15/16/66/100/109/116, trunks **XS1→NE8000** e **XS2→CCR**, GE 1/1/1–8
  placeholders dos servidores, **sem SVI/OSPF** — [`config/dm4170/`](../config/dm4170/)
- **NE8000 — LoopBacks de gerência (2026-08-07):** `10.200.255.241` (PPPOE) e `10.200.255.242`
  (BGP_NETPAL) criadas e no OSPF — a gerência não depende mais do `.54`
  ([`config/ne8000/loopbacks-gerencia-2026-08-07.md`](../config/ne8000/loopbacks-gerencia-2026-08-07.md))
- **IP da CCR definido `.15` (2026-08-07):** o `.4` é o LoopBack1 do NE8000/PPPOE_NETPAL;
  `.15` confirmado livre ao vivo
  ([`config/ne8000/check-177.72.104.15-livre-2026-08-07.md`](../config/ne8000/check-177.72.104.15-livre-2026-08-07.md))
- **Caminho do NAT:** privado→CCR→SRC-NAT `.15`→VLAN 16→DM4170→NE8000 `.1`; sem PBR no NE8000.
  Acesso roteado às privadas restrito a `.19`/NOC/`10.150.150.0/24`; OSPF aceito só de `.1`

### ⏳ Pendente

- **Toda a config do NE8000 fica pro dia da migração** (decisão do usuário): SVI do `/27`, OSPF
  com a CCR, liberação UDP/123, bloqueio do banco Docker (já desenhado em
  [`config/ne8000/bloqueio-banco-docker-2026-08-06.txt`](../config/ne8000/bloqueio-banco-docker-2026-08-06.txt))
- **Bloqueador #3:** testar ARP/ping/rota `.15`↔`.1` quando o trunk subir —
  [13-rotina-corte.md](13-rotina-corte.md)
- Sistemas vivos do firewall antigo ([05](05-limpeza-politicas.md), passo 1) — conscientemente
  adiado; endurecimento por servidor é pós-corte (decisão #14)
- WireGuard na CCR + saída do RB750 — só depois de toda a migração validada (decisão #5)
- **Janela QinQ futura:** trunk `sfp1`→DM4170, SVIs POP no NE8000, router-id/source do BGP
  FlowSpec e NetStream saindo do `.54`, desligar RB3011/RB2011 — [13](13-rotina-corte.md)
- Fase 4 (descomissionamento): rotação/revogação de credenciais — chave OSPF MD5 da area1
  (decisão #11), FTP backup, PPP, SNMP, token FocusChat (revogar)

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
- [13-rotina-corte.md](13-rotina-corte.md) — runbook operacional da janela de corte (checklist passo a passo, com rollback)
- [14-ips-servidores-e-17772.md](14-ips-servidores-e-17772.md) — lista consolidada de IPs dos servidores físicos/VMs + mapa do `177.72.104.0/27` para a virada
- [15-plano-migracao-servidores-177.md](15-plano-migracao-servidores-177.md) — **Etapa A** (DM4170+CCR no NE8000) e **Etapa B** (só servidores 177); QinQ fora desta fase
- [16-etapa1-proxmox-vlans-datacom.md](16-etapa1-proxmox-vlans-datacom.md) — 🆕 **primeira etapa:** VLANs Proxmox + portas Datacom (native gerência + tag 16)
- [17-runbook-etapa1-madrugada.md](17-runbook-etapa1-madrugada.md) — 🆕 **runbook passo a passo** da madrugada Etapa 1 (4 Proxmox)
- [arquitetura-alvo.drawio](arquitetura-alvo.drawio) — diagrama esquemático da arquitetura alvo (abrir no draw.io desktop ou app.diagrams.net)
- [runbook-noite.html](runbook-noite.html) — 🆕 **passo a passo autoritativo da próxima janela** (data a definir; interativo, checkbox salva no navegador; inclui a troca `.4`→`.15` na CCR)
- [ips-virada.html](ips-virada.html) — 🆕 mapa visual dos IPs do `/27` para a virada (complementa o [14](14-ips-servidores-e-17772.md))
