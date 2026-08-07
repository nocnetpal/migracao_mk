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
~~`177.72.104.4/27`~~ → 🆕 **`177.72.104.15/27` (troca 2026-08-07 — o LoopBack1 `.4/32` do
NE8000/PPPOE_NETPAL impede o `.4`; `.15` livre confirmado por checagem ao vivo)**, VLAN 100 com
`.1/24`, default via `.1` e SRC-NAT ✅ **mantidos habilitados por
decisão do usuário**. ⚠️ **A CCR está com `.4` da base de 2026-08-06 — reconfigurar para `.15`**
antes do trunk subir. Como a CCR está em bancada sem SFP conectado, não há conflito. A proteção
pré-instalação é física: não conectar o trunk à produção enquanto o RB3011 ainda tiver
`192.168.254.1`. Firewall/serviços
endurecidos; chain `forward` validada (established/related, DST-NAT futuro, privadas→internet e
drop final); IPv6 desativado e acesso MAC restrito à gerência. WireGuard não configurado, somente
pós-migração. Evidências em [`config/ccr1036/`](../config/ccr1036/).

✅ **DM4170 configurado em bancada (2026-08-07):** firmware atualizado para **DmOS 12.4.0**
(estava 9.8.0); hostname `DM4170-SW_SERVIDORES`; timezone BRA -3; SNTP `192.168.116.10`;
SNMPv2c (`nepaltelecom`, `public` removida); ACL de proteção de CPU (whitelist: `/27` + NOC
`177.93.244.165` + `192.168.0.0/24` temporária); **sem SVI/OSPF** (decisão #13); VLANs
15/16/66/100/109/116; trunks **XS1 (ten 1/1/1) → NE8000** e **XS2 (ten 1/1/2) → CCR1036**
com as 6 VLANs tagged; GE 1/1/1–1/1/8 placeholders dos servidores (native/tagged do mapa
A.6); GE 1/1/9 (CGNAT-1) e 1/1/10 (Gerência NE8000) aguardando destino. **QinQ fica no RB3011**
(decisão do usuário — não mexer). Evidências em [`config/dm4170/`](../config/dm4170/).

✅ **CCR1036 100% pronta em bancada (2026-08-06, scripts 01–09):** além da base acima — OSPF
completo (6 interface-templates: VLAN 16 ptp+MD5 `auth-id=1` com o NE8000; VLANs 100/15/66/109/116
passivas), VLAN 15/NTP (`192.168.116.9/30` + cliente NTP), VLANs privadas restantes (66 TS SIX
`192.168.66.1/28`, 109 OLT CPV `192.168.115.41/30`, 116 Dude `192.168.116.29/30`), firewall de
acesso roteado (gerência `.19`/NOC/clientes WG → privadas; OSPF só de `.1`; UDP/123), DST-NAT
Dude/TS SIX na `.4` (decisão #9 fechada), SRC-NAT de TS SIX/Dude, gerência remota (winbox/ssh:
bancada + `/27` + NOC com regras de input) e backup pré-corte salvo
(`ccr1036-pre-corte-2026-08-06.rsc`). Sintaxe real do firmware 7.23.3 diverge da doc oficial:
`auth-key` (não `authentication-key`) e `passive` como flag pura. ~~vlan10 (DNS recursivo)~~ e
~~vlan999 (Callcenter)~~ **removidas do plano pelo usuário**. Tudo que resta depende do trunk
ligado (OSPF FULL, NTP) e do NE8000 — **toda a config do NE8000 ficou para o dia da migração**
(decisão do usuário), inclusive o bloqueio do banco Docker já desenhado.

✅ **Caminho do NAT fechado (2026-08-06):** a CCR será o **gateway L3 das redes privadas**
recebidas no trunk do DM4170, começando pela VLAN 100 (`192.168.254.1/24`). Fluxo:
privado→CCR→SRC-NAT ~~`.4`~~ 🆕 **`.15`**→VLAN 16→DM4170→NE8000 `.1`. Não precisa de PBR no
NE8000. (IP trocado 2026-08-07.)

✅ **Acesso roteado às redes privadas aplicado (2026-08-06):** liberadas na CCR somente as origens
`177.72.104.19/32` (servidor WireGuard), `177.93.244.165/32` (NOC) e `10.150.150.0/24`
(clientes WireGuard). OSPF formado entre NE8000 `.1` e CCR ~~`.4`~~ 🆕 `.15` sobre a VLAN 16
(adjacência só
valida com o trunk ligado); a regra aceita protocolo OSPF exclusivamente de `.1`. Demais origens
caem no drop final.

✅ **VLAN 15/NTP aplicada (2026-08-06):** o NTP `192.168.116.10/30` é um
container na VM Docker (`ens21`→`vmbr15`→`enp8s0f1.15`); a CCR assumiu o gateway
`192.168.116.9/30` e anuncia `192.168.116.8/30` passivamente no OSPF. UDP/123 liberado na CCR
com origem irrestrita de propósito; falta a liberação equivalente no NE8000 (dia da migração).

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
  OpenVPN **+ PPTP** — PPTP descartado no redesenho); **dono do `/27` → NE8000, NAT → CCR1036** —
  ✅ **CCR dentro do `/27`** com
  ~~`177.72.104.4`~~ 🆕 **`177.72.104.15`** na VLAN 16 (2026-07-27; **troca 2026-08-07**:
  LoopBack1 `.4/32` do NE8000/PPPOE_NETPAL; `.15` livre confirmado — ver
  [`config/ne8000/check-177.72.104.15-livre-2026-08-07.md`](../config/ne8000/check-177.72.104.15-livre-2026-08-07.md));
  ✅ **caminho L2 confirmado em 2026-08-06:** a VLAN 16
  chega à CCR pelo trunk **DM4170↔CCR**, enquanto o NE8000 mantém `.1/27` pelo trunk
  **DM4170↔NE8000**. ✅ **Topologia simplificada em 2026-08-06:** não haverá link direto
  CCR↔NE8000; todo o tráfego da CCR passa pelo trunk com o DM4170.
   ~~`/32` via P2P~~ e ~~`10.254.254.x`~~ descartados.
   ~~Pendência: DST-NAT Dude/TS SIX (`.1` vs `.4`)~~ ✅ **fechada (2026-08-06): DST-NAT na CCR
   ~~`.4`~~ 🆕 `.15`** (decisão #9); quem acessa de fora passa a usar `177.72.104.15`.
- ✅ **Sequência da VPN definida em 2026-08-06:** WireGuard na CCR somente **depois de toda a
  migração concluída e validada**. Não entra na configuração de bancada nem na janela inicial.
- 🆕 **Desenho alvo definido pelo usuário (2026-07-23, corrigido 2026-08-06):** saem **RB3011 +
  RB2011**; o **RB750 permanece** (termina WireGuard em `.19`, migra pós-corte). Entram **DM4170**
  (L2 e agregação física) e **CCR1036** (gateway privado + NAT, com WireGuard somente pós-migração),
  ligada **apenas ao DM4170 por trunk**; a rede de acesso não é tocada. Automações antigas
  descartadas. Firewall redesenhado enxuto (sem
  geo-allowlist BRASIL). Trabalho na ordem: físico → L2 → L3 — ver [02](02-arquitetura-alvo.md)
- 📝 Plano de corte ([04](04-plano-migracao.md)): QinQ em janela futura; **agora** prioridade =
  servidores 177 ([15](15-plano-migracao-servidores-177.md)) — Etapa A em andamento/documentada
- ⏳ Principais bloqueios restantes: ~~NAT~~ ✅ CCR no `/27` (~~`.4`~~ 🆕 **`.15`** VLAN 16,
  troca 2026-08-07); ~~DST-NAT Dude/TS
  SIX (`.1` vs `.4`)~~ ✅ **fechada: DST-NAT na CCR `.15` (2026-08-06/07)**; decisão #12 ✅
  concluída
  para os 4 Proxmox. **CCR 100% pronta (falta só trocar `.4` → `.15`); restante é só dia da
  migração** (trunk → OSPF FULL + NTP;
  toda a config do NE8000, inclusive bloqueio do banco Docker, combinada para a janela). Sistemas
  vivos ([05](05-limpeza-politicas.md), passo 1) conscientemente adiado.
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
  ao vivo (ex.: `.8` "Hubsoft" parece morto, o real é `.16`); ✅ **WireGuard `.19` confirmado
  como o próprio RB750** (2026-08-06) — não é host Proxmox; o RB750 permanece até a VPN migrar
  para a CCR pós-migração; OpenVPN-2 `.12` é VM independente no Proxmox Docker.
- 🆕 **Três decisões fechadas de uma vez (usuário, 2026-07-24):** #3 redundância/HA — **sem
  redundância**, aceita os mesmos pontos únicos de hoje; #7 geo-allowlist BRASIL — **descartar**,
  não recria no NE8000 (já estava assim em [05](05-limpeza-politicas.md), só faltava sincronizar
  com [03](03-decisoes-pendentes.md)); #11 chave OSPF MD5 — **Opção A**, mantém `ntprb1030` na
  janela de corte, rotação fica pra fase 4. Também fechada por escopo a decisão #2 (~~lista de MKs
  a remover~~ — RB3011 e RB2011 saem; RB750 **fica** até WireGuard migrar, corrigido 2026-08-06) —
  não precisava de coleta nova, os MKs remotos de POP já são independentes do RB3011.
  Também fechada a decisão #10 (sobreposição `177.72.104.60/30`) — sem conflito real.
- 🆕 **Rodada final de decisões (usuário, 2026-07-24):** IP do NAT na CCR1036 definido
  (~~`177.72.104.4`~~ → 🆕 `.15` em 2026-08-07 — o `.4` é o LoopBack1 `.4/32` do NE8000/PPPOE_NETPAL;
  antes se acreditava `.4` e `.15` serem os 2 livres do `/27`); MTU decidido (jumbo
  frame máximo de cada equipamento); dimensionamento do NE8000 confirmado livre; variante da
  CCR1036 decidida (**8G-2S+**); rotina 1 da decisão #6 (backup semanal FTP) **também descartada**
  — não migra, mesmo tratamento da rotina 2. Só ficam de pé: teste do mecanismo de rota do NAT,
  ~~decisão #12~~ ✅ os 4 Proxmox concluídos, e sistemas vivos (adiado
  por escolha).
- ✅ **Decisão #6 (rotina 2) fechada — descartada (usuário, 2026-07-24):** a notificação
  netwatch → script `dude` → `api.focuschat.com.br` **não vai ser recriada** — usuário nem sabia
  que essa automação existia. De quebra, invalidou a hipótese de que ~~`API-ZAP` (`.26`)~~ era o
  destino (era uma chamada HTTPS direta pro SaaS FocusChat, sem host local envolvido). ✅
  **Identidade do `.26` corrigida em 2026-08-06:** o host é **API-WHATS** (Node.js, sem
  banco/Docker) e o "API-ZAP" real é o `.23` = **APLICACOES** (renomeado) — sincronizado em
  [03](03-decisoes-pendentes.md), [05](05-limpeza-politicas.md), [07](07-enderecamento-ip.md),
  [11](11-cruzamento-dude-devices.md), [12](12-mapeamento-proxmox.md), [14](14-ips-servidores-e-17772.md).
  Token FocusChat só precisa
  ser **revogado** na fase 4, não rotacionado ([04](04-plano-migracao.md), [13](13-rotina-corte.md)).
- ✅ **Decisão #14 fechada (2026-07-24):** firewall dos servidores locais sobe sem regra dedicada;
  endurecimento fica pós-corte (ver [03](03-decisoes-pendentes.md)).

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
- [runbook-noite.html](runbook-noite.html) — 🆕 **passo a passo autoritativo da janela de 2026-08-07** (interativo, checkbox salva no navegador; inclui a troca `.4`→`.15` na CCR)
- [ips-virada.html](ips-virada.html) — 🆕 mapa visual dos IPs do `/27` para a virada (complementa o [14](14-ips-servidores-e-17772.md))
