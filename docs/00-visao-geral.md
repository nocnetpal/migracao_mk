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

## Status

📋 Fase atual: **Etapa 1** — VLAN **100** = `192.168.254.0/24` (hypervisors `.10`–`.13`, GW `.1`)
+ VLAN **16** (VMs `177.x`); ainda nos Mikrotiks — [16](16-etapa1-proxmox-vlans-datacom.md) ·
**runbook madrugada:** [17](17-runbook-etapa1-madrugada.md).
SW_JDF: 100 livre · 16 = IP_PUBLICO.

- ✅ Inventário completo da GW Servidores (IPs, VLANs/QinQ, portas, bridges, OSPF, NAT, VPNs, DHCP,
  automações) — [07](07-enderecamento-ip.md) e [08](08-vlans-e-portas.md)
- ✅ Decisões fechadas: DHCP trivial (1 escopo); natureza das VPNs (L2TP sem criptografia +
  OpenVPN); **dono do `/27` → NE8000, NAT → CCR1036** — ✅ **CCR dentro do `/27`** com
  `177.72.104.4` na VLAN 16 (2026-07-27); ~~`/32` via P2P~~ e ~~`10.254.254.x`~~ descartados.
  Pendência: DST-NAT Dude/TS SIX (`.1` vs `.4`)
- 🆕 **Desenho alvo definido pelo usuário (2026-07-23):** saem RB3011 + RB2011; entram **DM4170**
  (no lugar do RB3011) e **CCR1036** (VPN + automações + cobre dos servidores, ligada direto ao
  NE8000); a **rede de acesso não é tocada**. Firewall redesenhado enxuto (sem
  geo-allowlist BRASIL). Trabalho na ordem: físico → L2 → L3 — ver [02](02-arquitetura-alvo.md)
- 📝 Plano de corte ([04](04-plano-migracao.md)): QinQ em janela futura; **agora** prioridade =
  servidores 177 ([15](15-plano-migracao-servidores-177.md)) — Etapa A em andamento/documentada
- ⏳ Principais bloqueios restantes: NAT ✅ CCR no `/27` (`.4` VLAN 16); DST-NAT Dude/TS SIX
  (`.1` vs `.4`); decisão #12 (portas/VLANs Proxmox HubSoft/DNS). Sistemas vivos
  ([05](05-limpeza-politicas.md), passo 1) conscientemente adiado.
  ~~Confirmações DmOS (SVI sobre QinQ)~~ ✅ **caiu (decisão #13, 2026-07-24)** — DM4170 fica só L2.
  ~~MTU nos dois trechos~~ ✅ **estratégia fechada (2026-07-24)**: jumbo frame máximo de cada
  equipamento. ~~Dimensionamento do NE8000~~ ✅ **confirmado (2026-07-24): capacidade livre.**
  ~~Variante CCR1036~~ ✅ **decidida: 8G-2S+.** ~~Automações (backup FTP, netwatch→API)~~ ✅
  **descartadas, não migram (decisão #6).**
  ~~Sobreposição do `177.72.104.60/30`~~ ✅ **resolvido (2026-07-24): sem conflito + dono definido**
  — o `.60/30` (VLAN198 Pantano=>Juca Ana) **sai do RB3011 e vira interface do NE8000** (assume o
  `.61`), o que de quebra torna consistente o `FTP/sftp client-source -a .61` que o NE8000 já tinha
  (era pré-config pra isso, não anomalia). Decisão #10.
  📌 Escopo fechado: **a rede de acesso não será mexida** — corte do trunk em janela única (troca
  de cabo)
- 🆕 **Modelo do DM4170 confirmado (usuário, 2026-07-24): 24GX+12XS** (24× GE SFP + 12× 10GE SFP+,
  todo óptico) — fecha mais um pré-requisito do [04](04-plano-migracao.md).
- 🆕 **Decisão #13 fechada (usuário, 2026-07-24): DM4170 fica só em L2.** Ele só faz QinQ
  termination; todo o roteamento das VLANs de acesso (~50 QinQ + 3 simples de serviço) passa a
  ser feito no **NE8000** — que já faz isso hoje para as VLANs de POP em paralelo. **Isso elimina
  o bloqueio técnico nº1** do projeto (SVI sobre tag interna QinQ no DmOS deixa de ser
  pré-requisito). Custo aceito: mais função crítica concentrada no NE8000 (reforça a urgência da
  decisão #3, redundância/HA). Propagado em [02](02-arquitetura-alvo.md#2a-✅-decisão-13-fechada-2026-07-24-dm4170-fica-só-em-l2),
  [03](03-decisoes-pendentes.md), [04](04-plano-migracao.md) e [09](09-l2-mapeamento-vlans.md).
- 🆕 **Cruzamento com o Dude** ([11](11-cruzamento-dude-devices.md)): forte candidato ao switch de
  topo do rack identificado (**Huawei S6730 "Jardim Formoso"**, ainda sem confirmação física);
  vários nomes de sistema no firewall do RB3011 estão **desatualizados** frente ao monitoramento
  ao vivo (ex.: `.8` "Hubsoft" parece morto, o real é `.16`); descobertas **duas VPNs adicionais**
  fora do RB3011 (WireGuard em `.19`, OpenVPN-2 em `.12`) que podem não fazer parte da decisão #5
- 🆕 **Três decisões fechadas de uma vez (usuário, 2026-07-24):** #3 redundância/HA — **sem
  redundância**, aceita os mesmos pontos únicos de hoje; #7 geo-allowlist BRASIL — **descartar**,
  não recria no NE8000 (já estava assim em [05](05-limpeza-politicas.md), só faltava sincronizar
  com [03](03-decisoes-pendentes.md)); #11 chave OSPF MD5 — **Opção A**, mantém `ntprb1030` na
  janela de corte, rotação fica pra fase 4. Também fechada por escopo a decisão #2 (lista de MKs
  a remover) — não precisava de coleta nova, os MKs remotos de POP já são independentes do RB3011.
  Também fechada a decisão #10 (sobreposição `177.72.104.60/30`) — sem conflito real.
- 🆕 **Rodada final de decisões (usuário, 2026-07-24):** IP do NAT na CCR1036 definido
  (`177.72.104.4`, entre os únicos 2 IPs livres do `/27` — `.4` e `.15`); MTU decidido (jumbo
  frame máximo de cada equipamento); dimensionamento do NE8000 confirmado livre; variante da
  CCR1036 decidida (**8G-2S+**); rotina 1 da decisão #6 (backup semanal FTP) **também descartada**
  — não migra, mesmo tratamento da rotina 2. Só ficam de pé: mecanismo de rota do NAT, decisão #12
  (Proxmox HubSoft/DNS + checklist Zabbix), e sistemas vivos (adiado por escolha).
- ✅ **Decisão #6 (rotina 2) fechada — descartada (usuário, 2026-07-24):** a notificação
  netwatch → script `dude` → `api.focuschat.com.br` **não vai ser recriada** — usuário nem sabia
  que essa automação existia. De quebra, invalidou a hipótese de que `API-ZAP` (`.26`) era o
  destino (era uma chamada HTTPS direta pro SaaS FocusChat, sem host local envolvido) — corrigido
  em [03](03-decisoes-pendentes.md), [05](05-limpeza-politicas.md), [07](07-enderecamento-ip.md),
  [11](11-cruzamento-dude-devices.md), [12](12-mapeamento-proxmox.md). Token FocusChat só precisa
  ser **revogado** na fase 4, não rotacionado ([04](04-plano-migracao.md), [13](13-rotina-corte.md)).

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
