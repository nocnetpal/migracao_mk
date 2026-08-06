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

✅ **CCR1036 preparada em bancada (2026-08-06):** modelo 8G-2S+ r2 confirmado; RouterOS e
RouterBOOT atualizados para `7.23.3 stable`; identity `CCR-GW_PRIV_SERVIDORES-VPN_WG`; gerência
temporária `192.168.88.1/24` na `ether1`; único uplink alvo `sfp1-TRUNK-DM`; VLAN 16,
`177.72.104.4/27`, VLAN 100 com `.1/24`, default via `.1` e SRC-NAT ✅ **mantidos habilitados por
decisão do usuário**. Como a CCR está em bancada sem SFP conectado, não há conflito. A proteção
pré-instalação é física: não conectar o trunk à produção enquanto o RB3011 ainda tiver
`192.168.254.1`. Firewall/serviços
endurecidos; chain `forward` validada (established/related, DST-NAT futuro, privadas→internet e
drop final); IPv6 desativado e acesso MAC restrito à gerência. WireGuard não configurado, somente
pós-migração. Evidências em [`config/ccr1036/`](../config/ccr1036/).

✅ **Caminho do NAT fechado (2026-08-06):** a CCR será o **gateway L3 das redes privadas**
recebidas no trunk do DM4170, começando pela VLAN 100 (`192.168.254.1/24`). Fluxo:
privado→CCR→SRC-NAT `.4`→VLAN 16→DM4170→NE8000 `.1`. Não precisa de PBR no NE8000.

📋 **Acesso roteado às redes privadas desenhado, ainda não aplicado (2026-08-06):** liberar na CCR somente as origens
`177.72.104.19/32` (servidor WireGuard), `177.93.244.165/32` (NOC) e `10.150.150.0/24`
(clientes WireGuard). OSPF será formado entre NE8000 `.1` e CCR `.4` sobre a VLAN 16; a regra
planejada aceita protocolo OSPF exclusivamente de `.1`. Demais origens caem no drop final.

📋 **VLAN 15/NTP desenhada, ainda não aplicada (2026-08-06):** o NTP `192.168.116.10/30` é um
container na VM Docker (`ens21`→`vmbr15`→`enp8s0f1.15`), portanto a CCR assumirá o gateway
`192.168.116.9/30` e anunciará `192.168.116.8/30` passivamente no OSPF. Toda a rede NetPal deve
alcançar UDP/123; prefixos de origem ainda precisam ser consolidados.

✅ **Os 4 Proxmox concluídos (2026-08-05):** hosts `.10`–`.13` somente na VLAN 100, VMs públicas
na VLAN 16, NAT e internet OK. CDN dedicada `.107`/`.108`/`.109` segue pela
VLAN 23. No DNS, as VMs `.24`, `.26`, `.29` e `NS-UNBOUND` `.28/.58/.59` estão `running`, com
`tag=16`; o Unbound responde `NOERROR` nos três IPs após desabilitar transporte IPv6 sem rota.
Os IPs antigos `.138/30` e `.210/30` foram removidos. No HubSoft, a VM `.16` passou para
`vmbr1/tag 16`, o RADIUS `.214` para `vmbr1` untagged, e o gateway RADIUS `.213/30` para
`vlan100-servidores`; aplicação e autenticação foram validadas. `.21` DNS2-Recursivo foi removido
intencionalmente e não migra. No Zabbix, as 8 VMs públicas passaram para `tag=16`, as 3 privadas
ficaram untagged na VLAN 100, `.5/27` foi removido e `ether3` da RB750 foi desativada. Restam o
export final do RB3011, testes funcionais restantes e
atualizações de monitoramento.

~~⛔ **HubSoft/Zabbix bloqueados no caminho RB750 (2026-08-05):**~~ tentativa controlada de estender
a VLAN 100 pelo RB3011 `ether10` e pela RB750 foi revertida sem impacto. O diagnóstico corrigiu
uma falha local do `vmbr0 self` e comprovou o caminho completo até a interface virtual no RB3011.
Captura conclusiva mostrou o ARP entrando sem tag em `vlan100-rb750-test`, mas saindo na
`bridge-servidores` como **QinQ `16,100`** (56→64 bytes), sem chegar à SVI `.1`: o segundo handoff
entre `Bridge IP Publico` e `bridge-servidores` interage com o handoff VLAN 16 já existente e
empilha as duas tags. ~~A causa provável era hw-offload/RB750.~~ ✅ **Causa L2 isolada; esse desenho
não deve ser repetido.** Rollback total validado nos dois equipamentos. Scripts M1/M2 antigos
continuam bloqueados. ✅ **HubSoft resolvido por outro caminho:** switch gigabit não gerenciável
intercalado na `ether8`, com DNS + `eno2` do HubSoft. A migração foi concluída sem usar o handoff
defeituoso; `eno1/vmbr0` ficou sem IP e sem VMs, e a porta antiga `ether4` foi desativada na RB750
(`eno1` confirmou `NO-CARRIER`). ✅ **Zabbix também concluído:** `enp3s0f1/vmbr1` com `.10/24`,
8 VMs públicas em VLAN 16 e 3 privadas untagged; gateways privados `.37`, `.41` e `.61` movidos
para `vlan100-servidores`. A porta antiga `ether3` da RB750 foi desativada e `enp3s0f0` confirmou
`NO-CARRIER`. Ver [16](16-etapa1-proxmox-vlans-datacom.md).

- ✅ Inventário completo da GW Servidores (IPs, VLANs/QinQ, portas, bridges, OSPF, NAT, VPNs, DHCP,
  automações) — [07](07-enderecamento-ip.md) e [08](08-vlans-e-portas.md)
- ✅ Decisões fechadas: DHCP trivial (1 escopo); natureza das VPNs (L2TP sem criptografia +
  OpenVPN); **dono do `/27` → NE8000, NAT → CCR1036** — ✅ **CCR dentro do `/27`** com
  `177.72.104.4` na VLAN 16 (2026-07-27); ✅ **caminho L2 confirmado em 2026-08-06:** a VLAN 16
  chega à CCR pelo trunk **DM4170↔CCR**, enquanto o NE8000 mantém `.1/27` pelo trunk
  **DM4170↔NE8000**. ✅ **Topologia simplificada em 2026-08-06:** não haverá link direto
  CCR↔NE8000; todo o tráfego da CCR passa pelo trunk com o DM4170.
  ~~`/32` via P2P~~ e ~~`10.254.254.x`~~ descartados.
  Pendência: DST-NAT Dude/TS SIX (`.1` vs `.4`)
- ✅ **Sequência da VPN definida em 2026-08-06:** WireGuard na CCR somente **depois de toda a
  migração concluída e validada**. Não entra na configuração de bancada nem na janela inicial.
- 🆕 **Desenho alvo definido pelo usuário (2026-07-23, corrigido 2026-08-06):** saem RB3011 +
  RB2011; entram **DM4170** (L2 e agregação física) e **CCR1036** (gateway privado + NAT, com
  WireGuard somente pós-migração), ligada **apenas ao DM4170 por trunk**; a rede de acesso não é
  tocada. Automações antigas descartadas. Firewall redesenhado enxuto (sem
  geo-allowlist BRASIL). Trabalho na ordem: físico → L2 → L3 — ver [02](02-arquitetura-alvo.md)
- 📝 Plano de corte ([04](04-plano-migracao.md)): QinQ em janela futura; **agora** prioridade =
  servidores 177 ([15](15-plano-migracao-servidores-177.md)) — Etapa A em andamento/documentada
- ⏳ Principais bloqueios restantes: NAT ✅ CCR no `/27` (`.4` VLAN 16); DST-NAT Dude/TS SIX
  (`.1` vs `.4`); decisão #12 ✅ concluída para os 4 Proxmox. Sistemas vivos
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
- 🆕 **Decisão #13 fechada (usuário, 2026-07-24; refinada 2026-08-06): DM4170 fica só em L2.**
  Ele só faz QinQ termination/switching. As VLANs de acesso e 18/1066 terminam no **NE8000**;
  redes privadas locais, incluindo VLAN 15/NTP, terminam na **CCR**. **Isso elimina
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
  — não migra, mesmo tratamento da rotina 2. Só ficam de pé: teste do mecanismo de rota do NAT,
  ~~decisão #12~~ ✅ os 4 Proxmox concluídos, e sistemas vivos (adiado
  por escolha).
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
