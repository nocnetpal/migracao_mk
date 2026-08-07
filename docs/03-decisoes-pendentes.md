# Decisões pendentes

> 📇 **Sumário** (detalhe em cada seção abaixo; ⚠️ a ordem física no arquivo é 1–11, 13, 12, 14):

| # | Decisão | Status | Resultado resumido |
|---|---|---|---|
| 1 | NAT e DHCP | ✅ 2026-07-23 | NAT → **CCR1036**; NE8000 só `/27`+firewall; DHCP = 1 escopo trivial |
| 2 | Quais MKs saem | ✅ 2026-08-06 | RB3011 + RB2011 saem; **RB750 fica** (WireGuard `.19`) até VPN migrar |
| 3 | Redundância/HA | ✅ 2026-07-24 | **Sem redundância** — mesmo SPOF de hoje, aceito |
| 4 | OSPF / adjacências | ✅ | VLAN 28 morre com o MK; nova adjacência CCR `.15`↔NE8000 `.1` na VLAN 16 |
| 5 | VPN de equipe | ✅ 2026-08-06 | WireGuard na CCR **só pós-migração**; L2TP/OpenVPN/PPTP não recriados |
| 6 | Automações (backup FTP, netwatch→FocusChat) | ✅ 2026-07-24 | **Descartadas**, não migram; token FocusChat só revogar (fase 4) |
| 7 | Geo-allowlist BRASIL | ✅ 2026-07-24 | **Descartar** — lista órfã, nunca referenciada |
| 8 | Dependências NE8000↔GW Servidores | ✅ | Resolvida pela #9 (`/27` connected no NE8000); LoopBacks de gerência criadas 2026-08-07 |
| 9 | Dono do `/27` + IP da CCR | ✅ 2026-08-07 | NE8000 dono (`.1`); CCR ~~`.4`~~ → **`.15`** VLAN 16; DST-NAT Dude/TS SIX na CCR |
| 10 | Sobreposição `177.72.104.60/30` | ✅ 2026-07-24 | Sem conflito; `.60/30` migra pro NE8000 |
| 11 | Chave OSPF MD5 | ✅ 2026-07-24 | Opção A — mantém a chave atual da area1 no corte, rotação fase 4 |
| 12 | Gerência dos 4 Proxmox | ✅ 2026-08-05 | Concluída: hosts `.10`–`.13` na VLAN 100, VMs públicas tag 16 |
| 13 | DM4170 L2 ou L3 | ✅ 2026-07-24 | Opção B — **DM4170 só L2**; SVIs QinQ no NE8000; privadas na CCR |
| 14 | Firewall dos servidores locais | ✅ 2026-07-24 | Sobe **sem regra dedicada**; endurecimento pós-corte |

## 1. Onde ficam NAT e DHCP?

Firewall L3 já definido: vai para o NE8000. Mas NAT e DHCP ainda não foram decididos entre:

- **Opção A** — Tudo no NE8000 (NAT + DHCP relay/server + firewall). Datacom fica só com inter-VLAN routing.
- **Opção B** — DHCP no Datacom (para as VLANs locais), NAT no NE8000.
- **Opção C** — outra combinação (ex.: DHCP em servidor dedicado, fora do Datacom/NE8000).

**✅ NAT no Datacom: descartado.** Conferido o datasheet oficial
([datacom-dm4170-datasheet.pdf](datacom-dm4170-datasheet.pdf)) — o DM4170 é um switch
L2/L3/MPLS carrier (VLAN/QinQ, LAG/LACP, EAPS/RSTP, OSPF/BGP, ACL, QoS, MPLS LER/LSR/LDP,
RADIUS/TACACS, DHCP **client**, SNMP). **Não há suporte a NAT/PAT em nenhuma parte do
documento.** Isso elimina a Opção B para NAT.

🆕 **Correção (usuário, 2026-07-23): NAT vai para a CCR1036, não para o NE8000.** O NE8000 só
**termina o bloco público** `177.72.104.0/27` (IP público direto para os servidores que já têm IP
dedicado + firewall). A tradução de endereço (SRC-NAT das redes privadas, DST-NAT do Dude/TS SIX)
roda na **CCR1036** — mais perto da Opção C original ("servidor dedicado, fora do Datacom/NE8000")
do que da A ou B. Isso substitui o que a decisão #9 havia fechado (lá, o NE8000 fazia o NAT usando
`.1`) — ver correção na decisão #9 abaixo. Também muda o papel da CCR1036 no
[10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md), que até então era descrita como
"100% privada, sem IP público".

**✅ DHCP: deixou de ser uma decisão relevante.** `/ip dhcp-server print` mostrou que existe
**apenas um DHCP server operante** na GW Servidores (`VLAN1066 - GERADOR MST`, pool
`192.168.90.2-254`); o segundo está inválido e 8 dos 10 pools são órfãos. Um único escopo de DHCP
para uma VLAN cabe sem esforço em qualquer das opções.

**Status:** ✅ **NAT decidido: CCR1036** (corrigido 2026-07-23; substitui a resposta anterior
"NE8000"). NE8000 fica só com `/27` + firewall. DHCP é um único escopo — colocar onde for mais
conveniente operacionalmente. Detalhes em [07-enderecamento-ip.md](07-enderecamento-ip.md).

## 2. ~~Lista de equipamentos Mikrotik a remover~~ — ✅ não precisa de coleta extra

Usuário confirmou que **todo o parque desse trecho é Mikrotik**, não só o gateway. A ideia inicial
era pedir uma lista manual completa + função de cada um — **descartada** (correção do usuário,
2026-07-24): o sinal certo não é uma lista solta, é olhar **por VLAN/interface** se o gateway hoje
é o **NE8000** (já migrado/independente, fora de escopo) ou a **RB3011** (dependente, dentro do
escopo do corte).

**Aplicando esse critério com o que já foi coletado:**
- Com o escopo fechado em "só o trecho da GW Servidores" (decisão já registrada na seção 4), os
  equipamentos MK **de POP remoto** (VLAN713 GW_SOLIDAO, VLAN198 Pantano=>Juca Ana, e as ~50
  dezenas de `MK_POP_*` do QinQ) **não entram nessa decisão** — o `display current-configuration
  interface` do NE8000 (confirmado ao vivo 2026-07-24, bate com
  [`config/ne8000/bgp_netpal-export.txt`](../config/ne8000/bgp_netpal-export.txt)) mostra que cada
  um já tem subinterface própria (`Gi0/1/8.7xx` etc.) com `ospf enable` **direto no NE8000** — o
  gateway já é o NE8000, não dependem do RB3011. Nenhum substituto a planejar aqui.
- ~~O único outro MK **dentro do trecho** (não remoto) já está inventariado: RB2011UiAS~~ → ❌
  **ERRADO (corrigido pelo usuário, 2026-07-24): são TRÊS Mikrotiks no trecho, não dois.** A
  topologia física do rack ([`config/topologia-fisica-rack.md`](../config/topologia-fisica-rack.md))
  revelou um **terceiro MK antes não inventariado: RB BRIDGE 750 (RB750)** — bridge L2 no `ether10`
  do RB3011 que agrega **gerência do NE8000 + Proxmox Zabbix + Proxmox HubSoft**. Os servidores não
  plugam direto no RB3011: passam por **2 bridges intermediárias** — RB2011 no `ether6` (TS SIX,
  CGNAT-1 mgmt, Régua Volt, Dude, RRFlow) e RB750 no `ether10`. Isso **explica** o achado da
  decisão #12 (MACs de HubSoft/Zabbix no mesmo `ether10` — ambos atrás do RB750).

**Status:** ✅ **decidida (usuário, 2026-07-24; corrigida 2026-08-06): RB3011 e RB2011 saem;
RB750 FICA.** O RB750 termina WireGuard em `177.72.104.19` (pool `10.150.150.0/24`, OSPF, NAT) e
**não pode ser removido** até a VPN migrar para a CCR (previsto pós-migração, junto com o WireGuard
da própria CCR). Portanto, em vez de "cada servidor pluga direto no DM4170", os servidores que hoje
passam pelo RB750 (NE8000 mgmt, Proxmox Zabbix, Proxmox HubSoft) já migraram para caminhos próprios
(switch temporário / segundo cabo — 2026-08-05), e o RB750 permanece ativo somente com a função
WireGuard. O RB2011 e o RB3011 saem na janela; o DM4170 absorve a agregação dos servidores que
passavam pelo RB2011 e direto do RB3011. Os MKs remotos de POP seguem
fora de escopo (independentes do RB3011, falam OSPF direto com o NE8000).

**Contagem de portas do DM4170 (servidores diretos):** cruzando a topologia
([`config/topologia-fisica-rack.md`](../config/topologia-fisica-rack.md)), os servidores/gerências
que hoje penduram ~~nos 3 MKs~~ (RB3011/RB2011/RB750 — ✅ **RB750 permanece**, ver Status acima) e
passam a plugar direto:

| # | Equipamento | Hoje pendura em | Meio |
|---|---|---|---|
| 1 | Proxmox Docker/CDNTV | RB3011 ether7 | cobre (SFP-RJ45) |
| 2 | Proxmox DNS | RB3011 ether8 | cobre |
| 3 | Proxmox Zabbix/Zeus | ~~RB750 p3~~ → ✅ caminho próprio (switch temp./segundo cabo, 2026-08-05) | cobre |
| 4 | Proxmox HubSoft | ~~RB750 p4~~ → ✅ caminho próprio (switch temp./segundo cabo, 2026-08-05) | cobre |
| 5 | TS SIX | RB2011 p2 | cobre |
| 6 | Servidor Dude | RB2011 p5 | cobre |
| 7 | Servidor RRFlow | RB2011 p6 | cobre |
| 8 | MGNT CGNAT-1 (Hillstone) | RB2011 p3 | confirmar (cobre/fibra) |
| 9 | Gerência NE8000 | ~~RB750 p2~~ → ✅ caminho próprio (2026-08-05) | confirmar |
| 10 | Gerência OLT CPV | RB3011 ether9 | cobre |

+ **Régua Volt** (RB2011 p4) — ESTRAGADA, **não migra** (dropar). Coleta ao vivo de 2026-08-05
mostrou `ether4` running e um MAC aprendido; isso confirma enlace físico, não funcionamento da
Régua, e não altera a decisão de não migrar. ~10 portas de servidor +
uplinks (QinQ de acesso, trunk NE8000, trunk CCR1036). Cabe folgado no DM4170 24GX+12XS (24 GE +
12 10GE). ⚠️ **Material: ~8 transceivers SFP-RJ45 (1000BASE-T)** pros servidores em cobre — item de
compra a confirmar (ver [02](02-arquitetura-alvo.md), questão física). CGNAT-1 e gerência NE8000
podem já ser fibra — confirmar antes de fechar a lista de transceivers.

**Ainda útil (não bloqueia):** ~~export do RB750 (`/export`) só pra confirmar que ele é bridge L2
burro mesmo~~ → ✅ **export obtido em 2026-07-27** (`config/rb750gr3-wireguard/export-2026-07-27.rsc`)
confirma que o RB750 **NÃO é só L2** — termina WireGuard em `177.72.104.19` (pool `10.150.150.0/24`,
OSPF area1, SRC-NAT). Por decisão do usuário (2026-08-06), o RB750 **permanece** até a VPN migrar
para a CCR pós-migração.

## 3. ~~Redundância / HA~~ — ✅ decidido: sem redundância

Ainda não discutido se o desenho alvo (Datacom + NE8000) deve ter redundância, ou se aceita ponto único de falha como hoje (só que trocando o equipamento).

**✅ Decidido (usuário, 2026-07-24): sem redundância.** Aceita o SPOF do desenho atual — a
migração troca o equipamento (RB3011/RB2011 → DM4170/NE8000), não a topologia de
disponibilidade. Reforça a importância de não introduzir *novos* riscos durante a janela de corte
(ver achados da decisão #13 sobre concentração de função no NE8000).

**Status:** ✅ **fechada (2026-07-24)** — sem redundância, mesmo modelo de disponibilidade de hoje.

## 4. Roteamento dinâmico (OSPF) — ✅ esclarecido pelo export do NE8000

Confirmado: o NE8000 ("BGP_NETPAL") **já é** vizinho OSPF da GW Servidores hoje, pela subinterface
`GigabitEthernet0/1/8.28` (`192.168.116.33/30`, area 0.0.0.1, mesma chave MD5 da area1) — bate
exatamente com o gateway padrão que a GW Servidores usa. Ver detalhes em
[06-ne8000-bgp-core.md](06-ne8000-bgp-core.md).

**Refinado pelo `/ip address` da GW Servidores:** o link **não é um cabo direto**. Do lado Mikrotik,
os dois endereços estão em `sfp1 - UPLINK SW TOPO DO RACK`, ou seja, passam por um switch de topo de
rack. E o segmento carrega **duas sub-redes**, não uma:

| Lado | Endereços | Interface |
|---|---|---|
| GW Servidores | `192.168.116.34/30` + `177.72.104.53/30` | `sfp1` (untagged, multinetting) |
| NE8000 | `192.168.116.33/30` + `177.72.104.54/30` (`sub`) | `Gi0/1/8.28` (dot1q VLAN 28) |

O ~~Datacom~~ **NE8000** passa a reproduzir isso como uma SVI própria na VLAN nova, com IP
primário **e** secundário — ~~o Datacom terá de reproduzir isso como uma SVI na VLAN 28 com IP
primário e secundário~~ → ✅ **corrigido (decisão #13, 2026-07-24):** DM4170 fica só L2; a VLAN 28
do MK **morre com o MK** e não é reutilizada. O NE8000 termina o `/27` numa SVI da VLAN 16 (via
DM4170) e a adjacência OSPF CCR↔NE8000 passa a ser sobre a VLAN 16 (~~`.4`~~ 🆕 `.15`↔`.1`,
área 0.0.0.1, MD5
da area1 — decisão #11).

O que ainda falta decidir:
- ~~O Datacom assume essa adjacência OSPF no lugar da GW Servidores (mesma VLAN/subrede,
  reautenticando com o NE8000), ou o link muda de desenho?~~ → ✅ **resolvido pela decisão #13
  (2026-07-24), reafirmado pelo usuário hoje: o princípio é "IP por VLAN, não por roteador" — cada
  VLAN só atravessa o DM4170 (L2 puro) e é terminada como SVI no NE8000, o mesmo padrão que já vale
  pra `MK_POP_*`. O Datacom **não assume** nenhuma adjacência OSPF — quem reautentica com os POPs é
  o NE8000, o DM4170 só entrega a VLAN.
- Os outros enlaces ponto a ponto hoje nomeados como VLANs no MK (`VLAN713 - GW SOLIDAO`,
  `VLAN198 - Pantano => Juca Ana`) — ✅ **mesmo tratamento confirmado**: são VLANs QinQ como as
  demais, passam pelo DM4170 e terminam no NE8000 (que já tem as subinterfaces equivalentes,
  `.713 MK_POP_SOLIDAO`, `.719 MK_POP_PANTANO`, `.778 MK_POP_JUCA_ANA`). Só falta a confirmação
  física porta-a-porta (fact-check pré-corte, não é mais decisão de desenho). **`VLAN11_eoip` é
  diferente** — não é VLAN QinQ passthrough, é túnel EoIP (proprietário Mikrotik, já morto/fora do
  ar) — não se aplica esse padrão, precisa de caminho novo próprio (ver achado em
  [08](08-vlans-e-portas.md) e [09](09-l2-mapeamento-vlans.md)).
- ~~**Novo:** o escopo cresceu muito... falta `/interface vlan print`~~ → ✅ **mapeado pela coleta 2**
  ([08-vlans-e-portas.md](08-vlans-e-portas.md)): todas as VLANs entram por **uma única porta**
  (`sfp1`, 1 GE) em estrutura QinQ (tag externa = site, interna = serviço). Fisicamente o corte é
  1 trunk + ~5 portas de servidor.
- **Novo (técnico):** confirmar com a Datacom se o DmOS faz **SVI roteada sobre a tag interna de
  QinQ** e quantos IPs secundários aceita por SVI. Se não fizer, ou o switch de topo de rack
  desempacota a tag externa, ou o DM4170 assume o lugar dele.
- ~~**Novo (técnico):** confirmar também **MTU/baby giants no DmOS** — hoje a `sfp1` roda l2mtu 1600
  (outer 1596 / inner 1592) por causa do QinQ; o trunk novo precisa comportar o mesmo~~ → ✅
  **decidido (usuário, 2026-07-24): usar o jumbo frame máximo suportado por cada equipamento** nos
  dois trechos novos (rede de acesso↔DM4170 e DM4170↔NE8000), em vez de replicar o valor exato
  1600/1596/1592 do RB3011 — estratégia fechada, só falta o número concreto de cada equipamento na
  hora de configurar (DmOS/VRP, não é bloqueio de decisão). MSS-clamp equivalente ainda precisa de
  desenho no novo firewall.
- ~~**Novo (arquitetura):** decidir se o DM4170 substitui só o RB3011 ou **também o switch de topo de
  rack** (equipamento ainda não inventariado, por onde passa 100% do tráfego).~~ ✅ **Resolvido por
  escopo (2026-07-23):** o usuário decidiu que a **rede de acesso não será tocada** — fica
  totalmente fora do escopo, independente de qual equipamento seja. O DM4170 entra no lugar exato
  do RB3011 (herda o trunk QinQ). Ver [02-arquitetura-alvo.md](02-arquitetura-alvo.md).
  🆕 **Identidade do switch, cruzamento com o Dude ([11](11-cruzamento-dude-devices.md)):** forte
  candidato é o **Huawei S6730 "Jardim Formoso"** (`192.168.15.6`, mesmo site que a GW Servidores,
  o NE8000, o Dude e o TS SIX) — mas **sem confirmação física** ainda. Como o escopo já exclui
  mexer nele, isso é informativo (dá tranquilidade técnica: S6730 é enterprise, suporta QinQ bem),
  não bloqueante.

**Status:** adjacência principal detalhada (~~VLAN 28~~ → ✅ **morre com o MK; nova adjacência
CCR↔NE8000 sobre a VLAN 16** ~~`.4`~~ 🆕 `.15`↔`.1`, 2026-08-06/07 — ver desenho do OSPF em [10](10-enderecamento-ccr1036.md));
mapa VLAN→porta completo ([09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)). ~~🆕 Com o
escopo fechado em "só a GW Servidores" (2026-07-23), a confirmação de SVI roteada sobre tag
interna de QinQ no DmOS volta a ser o bloqueio técnico nº 1 — é o DM4170 quem herda as SVIs
QinQ do RB3011.~~ → ✅ **superado pela decisão #13 (2026-07-24):** o DM4170 fica só em L2: quem
herda as SVIs QinQ do RB3011 é o **NE8000**, não o DM4170. A confirmação do DmOS deixou de ser
necessária.

🆕 **Achado que simplifica o escopo (2026-07-24):** `/interface bridge host print detail` na
`Bridge IP Publico` ([08](08-vlans-e-portas.md)) mostrou que **nenhum host aprendido vem da
VLAN16** — as ~24 sub-redes secundárias da bridge são 100% tráfego local dos 4 servidores
(`ether6`/`7`/`8`/`10`), não algo que "sobe" pela VLAN16/switch de topo do rack. Ou seja, o que a
SVI do NE8000 precisa carregar de secundárias é bem menor do que se temia — praticamente só o
`/27` público em si. Detalhes e cruzamento com os clusters Proxmox em [08](08-vlans-e-portas.md).

## 5. VPN de equipe (L2TP/IPSec + PPP secrets)

Hoje usuários da equipe (bruno, isaac, leonardo etc.) têm `/ppp secret` neste MK para acesso remoto.
Nem o Datacom nem — tipicamente — um switch L3 fazem esse tipo de VPN de usuário.

- Fica no NE8000 (se ele suportar VPN de usuário)?
- Ou precisa de um servidor/appliance dedicado?

**✅ Esclarecido o que a VPN é.** `/interface l2tp-server server print` confirmou: servidor L2TP
**habilitado neste MK** (termina aqui mesmo), com **`use-ipsec: no`** — ou seja, **não é
L2TP/IPSec**, apesar do nome da regra de firewall. É L2TP simples com 4 usuários locais.

Isso reduz bastante o requisito: o substituto precisa de um **servidor L2TP básico**, não de uma
stack IPSec. Pode inclusive ser um serviço em servidor Linux existente, sem depender de NE8000 nem
de appliance.

✅ **Confirmado (coleta 2): há um segundo serviço — OpenVPN habilitado** (TCP 1194, certificado de
cliente obrigatório, AES-256/SHA1), usando os mesmos 4 usuários.

🆕 **Terceiro serviço no export completo (2026-07-24): PPTP-server também HABILITADO** (`enabled=yes`,
`mschap1`, MTU/MRU 1480) — não tinha aparecido antes (estava no início truncado do export). Então
o RB3011 termina **três VPNs de usuário**: L2TP (sem cripto), OpenVPN (com cert) **e PPTP** (o mais
inseguro dos três — PPTP/mschap1 é quebrável). No redesenho da CCR1036, **PPTP não deve ser
recriado** — descontinuar. Confirmar com o usuário se algum usuário ainda depende de PPTP antes de
simplesmente cortar.

⚠️ Achados de segurança a corrigir ao recriar (não replicar): `use-ipsec: no`, `mschap1` habilitado,
senhas em texto claro — e, pior, **ambos os profiles PPP têm `use-encryption=no`** (até o
"default-encryption" foi alterado): hoje **nenhuma sessão L2TP tem criptografia obrigatória**.
Ver [07-enderecamento-ip.md](07-enderecamento-ip.md).

**Status:** ✅ **Sequência fechada (2026-08-06)** — WireGuard na CCR somente após toda a migração
validada; L2TP/OpenVPN/PPTP não serão recriados na bancada nem na janela. A natureza histórica
(L2TP sem cripto + OpenVPN + PPTP) foi o ponto de partida; PPTP descartado definitivamente.

🆕 **Atenção ao escopo, achado do cruzamento com o Dude ([11](11-cruzamento-dude-devices.md)):**
existem **outras duas VPNs** na rede — "VPN - WireGuard" em `177.72.104.19` e "OpenVPN - 2" em
`177.72.104.12`. ✅ **Corrigido em 2026-08-06:** `.19` **NÃO é** um host Proxmox independente — é o
**próprio RB750** (identity `WIREGUARD`, ver [`config/rb750gr3-wireguard/export-2026-07-27.rsc`](../config/rb750gr3-wireguard/export-2026-07-27.rsc)).
O RB750 permanece ativo até a VPN migrar para a CCR (pós-migração). Já `.12` (OpenVPN-2) é uma VM
no Proxmox Docker — independente do RB3011, só precisa do firewall do NE8000 preservado.

## 6. Automações que rodavam como script no Mikrotik

Duas rotinas hoje são scripts RouterOS, sem equivalente automático em switch/roteador:

- Backup semanal (config + export) via FTP.
- Notificação via API HTTP quando um host monitorado sobe/cai (netwatch → script `dude`).

Nenhum desses recursos existe nativamente em um switch Datacom ou, provavelmente, no NE8000 da
mesma forma. Precisa decidir onde essas automações passam a rodar (ex.: servidor de gerência
existente, Zabbix/Dude/outro NMS já em uso).

**Status:** ✅ **fechada (2026-07-24) — as duas rotinas descartadas.**

**Rotina 1 — Backup semanal FTP:** ✅ **descartada (usuário, 2026-07-24) — não migra.** Mesmo
tratamento da rotina 2: não recriar no desenho novo (nem na CCR1036, nem em outro lugar).
**Nota operacional (registro, não bloqueio):** isso deixa o backup de configuração do DM4170/NE8000
**sem automação equivalente** no dia a dia — se for necessário no futuro, é uma automação nova,
não uma migração desta. Credenciais FTP de backup (`mkbkp`/`hwbkp`) só precisam ser **revogadas**
na fase 4, não rotacionadas (mesmo caso do token FocusChat).

**Rotina 2 — Notificação netwatch → script `dude` → FocusChat:** ✅ **descartada (usuário,
2026-07-24) — não migra.** O usuário nem sabia que essa automação existia; decisão é **remover**,
não recriar no desenho novo. Contexto técnico (por registro): o script na verdade não é disparado
pelo netwatch local do RB3011 (o único netwatch configurado está `disabled=yes` e mexe numa rota,
não chama o script) — os placeholders `[Device.Name]`, `[Probe.Name]`, `[Service.Status]` etc. no
corpo do script são macros do **The Dude** (NMS Mikrotik), então quem dispara essa automação é o
**Dude** (rodando numa VM do cluster Proxmox Zabbix — `Dude-VLSul` ou `Dude-PM-CPV`, ver
[12](12-mapeamento-proxmox.md)) chamando o script remotamente via API do RouterOS no RB3011, que
por sua vez chama `api.focuschat.com.br`. Com o RB3011 saindo, essa cadeia quebra sozinha — e por
decisão do usuário, **não será recriada** (nem no Dude apontando direto pra FocusChat, nem em
outro lugar).

~~🆕 **Achado (2026-07-24, consulta direta ao cluster Proxmox DNS):** o IP `177.72.104.26` é a VM
**API-ZAP** — forte candidato a ser o destino real da API HTTP estilo WhatsApp que o netwatch/script
`dude` usa para notificar.~~ → ❌ **descartado (2026-07-24, releitura do export do RB3011):** o
`/system script` chamado `dude` (o que o netwatch dispara) faz
`/tool fetch url="https://api.focuschat.com.br/core/v2/api/chats/send-text?..."` —
**é uma chamada HTTPS direta pra internet, pra um SaaS de terceiros (FocusChat)**, sem nenhuma
dependência de IP interno. ~~**`API-ZAP` (`.26`) não tem relação com esse script**~~ — ✅
**corrigido 2026-08-06 (consulta direta ao Docker):** o nome "API-ZAP" do Dude apontava pro `.26`,
mas o host `.26` se chama **API-WHATS** (Node.js bot WhatsApp, sem Docker/banco) e o **API-ZAP
real é o `.23` (APLICACOES)** — o nome e a
coincidência de cluster com `AUTOMACOES`/`DEVOPS-01` (`.29`) induziram a uma hipótese errada; o
mistério do `.26` está **resolvido** (2026-08-06, não bloqueia nada).
Token de acesso da FocusChat está em texto claro no export — **não copiar o valor pros docs**
(regra de [01](01-inventario-atual.md)), só rotacionar na fase 4 (já listado em
[04](04-plano-migracao.md) e [13](13-rotina-corte.md)).

## 7. ~~Geo-allowlist (address-list `BRASIL`)~~ — ✅ decidido: descartar

O MK mantém uma lista enorme de faixas de IP nacionais, usada em pelo menos uma regra de firewall
("LIBERA HUBSOFT PARA O BRASIL"). Confirmar o propósito exato (parece anti-fraude/allowlist para
o sistema de billing Hubsoft) e se precisa ser recriada no NE8000.

**✅ Decidido (usuário, 2026-07-24): descartar.** Não recriar a geo-allowlist BRASIL no NE8000 —
coerente com o princípio de redesenho limpo do firewall ([05-limpeza-politicas.md](05-limpeza-politicas.md)),
sem portar regra 1:1. Se o bloqueio anti-fraude do Hubsoft ainda for necessário, deve ser resolvido
no próprio sistema de billing, não replicado no firewall de borda.

🆕 **Achado que reforça a decisão (2026-07-24, releitura do export):** a lista `BRASIL` **nunca é
referenciada** como `src-address-list` em nenhuma regra `chain=forward` do RB3011 — as três regras
"LIBERA HUBSOFT PARA O BRASIL" (`.8` e `.5`) **não têm restrição de origem nenhuma**, aceitam de
qualquer lugar da internet. O nome sugere geo-restrição, mas na prática **não existe** — a lista é
puramente órfã hoje. Achado de segurança à parte: a regra pro `.5` (TCP+UDP, `dst-port=!148` — ou
seja, todas as portas exceto a 148) libera acesso amplo direto ao **IP do próprio hypervisor
Proxmox Zabbix** (confirmado, ver decisão #12) — bem mais exposto do que o nome "Hubsoft" sugere.
**Não portar essa regra.** ~~Restringir ao “serviço real do HubSoft em `.5`”~~ → ❌ premissa
corrigida em 2026-08-05: não havia HubSoft; somente Proxmox `8006` e SSH `45345` escutavam.

**Status:** ✅ **fechada (2026-07-24)** — não migra. Achado de segurança sobre `.5` registrado
também na decisão #12.

## 8. 🚨 Dependências do NE8000 na GW Servidores (NOVO — bloqueia o plano de corte)

Descoberto ao cruzar o `/ip address` da GW Servidores com o export do NE8000: **o core depende do
Mikrotik que vamos remover.** Não é uma dependência de gerência — é de plano de dados e de controle.

1. **`177.72.104.1` é next-hop de rotas estáticas do NE8000**
   (`ip route-static 10.8.0.0/21 177.72.104.1` e `10.254.0.0/22 177.72.104.1`). Esse IP está na
   `Bridge IP Publico` da GW Servidores.
2. **A sessão BGP de FlowSpec (anti-DDoS) atravessa o Mikrotik.** O NE8000 tem
   `peer 177.72.104.27 ... connect-interface 177.72.104.54` e `router-id 177.72.104.54` — ambos na
   subinterface voltada para a GW Servidores. E o route-reflector `177.72.104.27` é um host dentro
   do `177.72.104.0/27`, que só é alcançável porque **a GW Servidores anuncia esse /27 na OSPF
   area 1**. O NE8000 não tem interface própria nesse bloco.
   🆕 (2026-08-07): LoopBacks de gerência `10.200.255.241` (PPPOE) e `10.200.255.242` (BGP_NETPAL)
   criadas — **a gerência não depende mais do `.54`**; na janela QinQ falta só trocar o router-id/
   source do BGP FlowSpec e o NetStream saindo do `.54` (checklist em [13](13-rotina-corte.md)).
   ⚠️ Achado: OSPF da VS BGP_NETPAL está com **Authtype None** na área 0.0.0.1 (sem MD5) — incluir
   na estratégia de rotação da chave da area1 (decisão #11/fase 4).
3. O coletor NetStream/IPFIX (`177.72.104.27:3055`) está no mesmo host.

**O que o substituto precisa fazer, no mesmo instante do corte:**

- [ ] Assumir `177.72.104.1/27`
- [ ] Continuar anunciando `177.72.104.0/27` na OSPF area 0.0.0.1
- [ ] Manter o segmento `177.72.104.52/30` com o NE8000 (`.53` deste lado)
- [ ] Manter `177.72.104.27` alcançável
- [ ] Dar um novo caminho de gerência ao NOC: o túnel EoIP (`177.72.104.1` ↔ `177.93.244.165`) é
      proprietário Mikrotik e morre com o RB3011 — mas já está fora do ar hoje, confirmar se ainda
      é usado ([08-vlans-e-portas.md](08-vlans-e-portas.md))

**Decisão a tomar:** aceitar esse acoplamento e reproduzi-lo no Datacom, ou aproveitar a migração
para **remover a dependência** — por exemplo, dando ao NE8000 um caminho próprio até o
route-reflector e trocando as rotas estáticas por next-hop que não dependa deste segmento.

**Status:** ✅ **Resolvida pela decisão #9** — o usuário decidiu (2026-07-23): o bloco
`177.72.104.0/27` vai para o **NE8000** (Opção B). Isso elimina as quatro dependências listadas
aqui: as rotas estáticas viram resolução *connected*, o RR de FlowSpec (`.27`) fica diretamente
conectado e o anúncio OSPF do `/27` passa ao NE8000.

## 9. Quem fica dono do bloco público `177.72.104.0/27`? (NOVO — define o desenho do NAT)

Conflito descoberto ao rascunhar o plano de corte: hoje o MK é **dono do `/27`** (SVI `.1`) **e**
faz o NAT usando `.1` como endereço. Na migração essas duas funções se separam — NAT vai para o
NE8000, mas o `/27` iria para o Datacom. **O NE8000 não pode usar `.1` como endereço de NAT se o
`.1` estiver numa SVI do Datacom** (o tráfego de retorno para `.1` seria entregue ao Datacom, não
ao NE8000).

- **Opção A — Datacom dono do `/27`** (SVI com `.1` + secundárias): o NAT no NE8000 precisa de
  **outro IP público** (novo pool, de faixa roteada ao NE8000), e os dois DST-NAT
  (Dude `:18291`, TS SIX `:15389`) mudam de endereço — todo mundo que acessa precisa reconfigurar.
- **Opção B — NE8000 dono do `/27`**: a VLAN 16 sobe em **L2** pelo Datacom até o NE8000, que
  termina o `/27` (`.1` + secundárias) numa subinterface. Efeitos em cascata, todos positivos:
  - as rotas estáticas do NE8000 via `.9`/`.12`/`.19` viram resolução *connected* (some parte da
    dependência descrita na decisão #8);
  - o RR de FlowSpec (`.27`) fica **diretamente conectado** ao NE8000;
  - o anúncio OSPF do `/27` passa naturalmente para o NE8000;
  - o firewall fica exatamente no gateway dos servidores.
  - Custos: tráfego inter-VLAN de/para servidores faz hairpin no NE8000 (1 salto a mais, em 10GE),
    e as ~24 sub-redes de gerência da antiga `Bridge IP Publico` precisam ir junto como secundárias
    ou ser redesenhadas.

**Recomendação preliminar: Opção B** — desfaz de uma vez as quatro dependências críticas da
decisão #8 e simplifica a janela do núcleo (fase 3 do [04-plano-migracao.md](04-plano-migracao.md)).

🆕 **Correção (usuário, 2026-07-23): o NE8000 termina o `/27`, mas não faz o NAT.** A afirmação
original desta decisão ("`.1` continua sendo o IP de NAT, port-forwards não mudam **no NE8000**")
foi substituída pela decisão #1: o NAT roda na **CCR1036**. Continua válido que o NE8000 é dono do
`/27` — ele só não é mais quem traduz endereço.

✅ **Mecanismo de NAT fechado (usuário, 2026-07-27):** a CCR **fica dentro do `/27`** —
mesmo modelo dos servidores (VLAN 16), com IP `177.72.104.4`. **Não** é host-route `/32`
por link privado separado.

🚨 **REVISADO (2026-08-07): o `177.72.104.4` NÃO pode ser usado pela CCR — troca para
`177.72.104.15`.** O dump do NE8000 (PPPOE_NETPAL, `config/ne8000/pppoe_netpal-config-2026-08-07.txt`)
revelou o `LoopBack1 = 177.72.104.4/32` anunciado no OSPF (`network 177.72.104.4 0.0.0.0`) —
o `.4` já é do NE8000. **Checagem ao vivo 2026-08-07** (`config/ne8000/check-177.72.104.15-livre-2026-08-07.md`):
`177.72.104.15` livre (ping 100% sem resposta no NE8000 e RB3011; ARP do RB3011 dinâmico sem MAC).
**Novo IP da CCR: `177.72.104.15`** (usuário, 2026-08-07). ⚠️ A CCR já estava configurada com
`.4` em bancada — **reconfigurar para `.15`** antes do trunk subir (base 2026-08-06 dos scripts 01–09).

- NE8000: dono/gateway do `177.72.104.0/27` (SVI VLAN 16)
- CCR: ~~`177.72.104.4`~~ → 🆕 **`177.72.104.15`** na VLAN 16, ✅ caminho confirmado em 2026-08-06
  pelo trunk DM4170↔CCR — SRC-NAT/DST-NAT usam `.15`; o NE8000 mantém `.1/27` no mesmo domínio
  L2 pelo trunk DM4170↔NE8000
- ~~Link direto CCR↔NE8000 como trânsito separado~~ → ❌ **descartado em 2026-08-06**. A CCR tem
  somente o trunk com o DM4170; por ele chegam a VLAN 16, as redes privadas e o caminho até o
  NE8000
- ~~rota `/32` via P2P `10.254.254.x`~~ → ❌ **descartado** (usuário 2026-07-27): primeiro
  rejeitou o `10.254.254.x`, depois definiu CCR **dentro** do `/27` (não `/32` isolado)

Mesmo padrão L2 dos hosts `.9`/`.12`/`.27` no broadcast do bloco — o NE8000 alcança
~~`.4`~~ `.15` por ARP na VLAN 16.

✅ **Caminho do tráfego privado fechado (usuário, 2026-08-06):** a CCR é o **gateway L3 das redes
privadas de servidores** recebidas pelo trunk do DM4170, incluindo VLAN 100
`192.168.254.0/24` com gateway `192.168.254.1`. Assim o tráfego passa naturalmente pelo SRC-NAT
na CCR e sai como ~~`.4`~~ 🆕 **`.15`** pela VLAN 16 no mesmo trunk até o gateway `.1` no NE8000.
Não há PBR nem gateway privado no NE8000 para essas redes locais. (IP trocado 2026-08-07.)

📋 **Acesso roteado e OSPF desenhados, ainda não aplicados (usuário, 2026-08-06):** OSPF entre NE8000 `.1` e CCR ~~`.4`~~ 🆕 **`.15`**
diretamente sobre o `/27`/VLAN 16, área `0.0.0.1`; VLANs privadas anunciadas passivamente pela
CCR. Como a VLAN 16 é compartilhada, a CCR aceita protocolo OSPF somente da origem `.1`. Acesso
encaminhado às redes privadas fica restrito a `177.72.104.19/32`, `177.93.244.165/32` e
`10.150.150.0/24`; não liberar o `/27` inteiro.

📋 **VLAN 15/NTP reclassificada para a CCR (desenho confirmado, configuração pendente):** o NTP
`192.168.116.10/30` roda em container dentro da VM Docker, pela cadeia
`ens21`→`vmbr15`→`enp8s0f1.15`. A CCR assume `192.168.116.9/30`, anuncia
`192.168.116.8/30` passivamente no OSPF e permite UDP/123 para toda a rede roteada NetPal. A lista
exata de prefixos de origem ainda precisa ser consolidada antes da regra de firewall.

~~**Ainda aberto (DST-NAT):** port-forwards Dude/TS SIX hoje no `.1` — passam pro `.4` (quem acessa
de fora atualiza) ou o NE8000 também roteia `.1/32` pra CCR? A confirmar.~~ → ✅ **Resolvido
(usuário, 2026-08-06): os DST-NAT movem para a CCR ~~`.4`~~ 🆕 **`.15`** (2026-08-07).** Quem acessa
de fora atualiza o IP de destino para `177.72.104.15`; o NE8000 não recebe NAT server nem rota
`.1/32` (NAT fica só na CCR, conforme decisão). Ver [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md).

**Status:** ✅ **Opção B** (NE8000 dono do `/27`) + ✅ **CCR dentro do `/27` com
~~`.4`~~ 🆕 **`.15`** na VLAN 16** (2026-07-27; troca 2026-08-07 pelo LoopBack1 `.4/32` do NE8000)
+ ✅ caminho L2 via DM4170 + gateways privados na CCR (2026-08-06) +
✅ **DST-NAT Dude/TS SIX na CCR `.15`** (2026-08-06/07).

## 10. ~~Possível sobreposição no `177.72.104.60/30`~~ (enlace Juca Ana) — ✅ resolvido

Cruzamento pendente apontado em [08-vlans-e-portas.md](08-vlans-e-portas.md): o MK tem
`177.72.104.61/30` na `VLAN198 - Pantano => Juca Ana` (QinQ) e o NE8000 **também anuncia**
`network 177.72.104.60 0.0.0.3` na OSPF. Se os dois anunciam o mesmo /30, há risco de conflito
de rota — e de loop — no momento do corte, quando a origem do anúncio mudar.

**✅ Investigado (2026-07-24):** `display current-configuration interface` no NE8000 (ao vivo,
confirma o export estático em [`config/ne8000/bgp_netpal-export.txt`](../config/ne8000/bgp_netpal-export.txt))
mostra que **nenhuma das ~90 subinterfaces de `Gi0/1/8` tem IP no `177.72.104.60/30`** — o
`network 177.72.104.60 0.0.0.3` é uma *statement* OSPF inerte (não ativa hello em nenhuma
interface local, já que nenhuma bate com o range). O dono real e único do segmento hoje é o MK
(`.61/30` na `VLAN198 - Pantano => Juca Ana`) — não há conflito. Já propagado em
[04-plano-migracao.md](04-plano-migracao.md) e [08-vlans-e-portas.md](08-vlans-e-portas.md); só
faltava fechar aqui.

**Achado à parte, digno de nota:** o NE8000 tem `FTP client-source -a 177.72.104.61` e
`sftp client-source -a 177.72.104.61` configurados globalmente — tenta originar sessões de
FTP/SFTP client com um IP que **não é dele**, é do MK. A confirmar se isso é usado de fato antes
do corte (se for, quebra no dia da troca).

🆕 **Decisão do usuário (2026-07-24): mover o `177.72.104.60/30` do RB3011 para o NE8000.** A
`VLAN198 - Pantano => Juca Ana` deixa de ter o `.61/30` no MK — o NE8000 assume o segmento como
interface própria (SVI/subinterface, coerente com a decisão #13: toda VLAN QinQ termina no NE8000).
Efeitos:
- O `network 177.72.104.60 0.0.0.3` da OSPF **deixa de ser inerte** e passa a ter interface local
  de verdade — vira anúncio legítimo.
- **Resolve o achado do FTP/sftp client-source:** com o NE8000 dono do `.61`, o
  `FTP client-source -a 177.72.104.61` passa a apontar pro **próprio IP** dele — deixa de ser
  anomalia e vira consistente. É forte indício de que a migração desse `/30` pro NE8000 **já estava
  planejada** (o client-source foi pré-configurado pra isso). Não quebra no corte — pelo contrário,
  conserta.
- **Efeito no corte:** este `/30` sai da lista de coisas a replicar no caminho do DM4170 — não é
  VLAN de gerência de servidor local nem passthrough comum; é um P2P público que nasce direto como
  interface do NE8000. Propagar em [09](09-l2-mapeamento-vlans.md), [08](08-vlans-e-portas.md) e
  [`config/rb3011/relacao-vlan-ip.md`](../config/rb3011/relacao-vlan-ip.md).

**Status:** ✅ **resolvido (2026-07-24)** — sem conflito real; `.60/30` **migra pro NE8000** (não
só "sem conflito", agora com dono definido). O achado do FTP/SFTP client-source fica resolvido pela
mesma mudança (NE8000 vira dono do `.61`).

## 11. ~~Estratégia da chave OSPF MD5 da area1 no corte~~ — ✅ decidido: Opção A

A chave MD5 da area1 é a **mesma em toda a rede** (dezenas de interfaces no NE8000 e nos MKs de
POP). O plano joga a rotação para a fase 4 ("rede toda, coordenar!"), mas o
[06-ne8000-bgp-core.md](06-ne8000-bgp-core.md) sugere usar chave nova na adjacência do Datacom.
Trocar a chave **só** na adjacência nova significa conviver com duas chaves na área — o que é
válido (MD5 é por-interface), mas precisa ser decisão explícita, não acidental.

- **Opção A** — manter a chave atual no corte (menos variáveis na janela) e rotacionar na fase 4,
  interface por interface ou com rollover de key-id.
- **Opção B** — já nascer com chave nova na adjacência DM4170↔NE8000 e ir migrando as demais
  interfaces aos poucos (convivência de duas chaves por tempo indeterminado).

**Recomendação preliminar: Opção A** — a janela do núcleo já tem variáveis demais; a chave não é
uma vulnerabilidade urgente.

**✅ Decidido (usuário, 2026-07-24): Opção A.** Mantém a chave atual na adjacência DM4170↔NE8000
durante o corte; rotação da chave fica pra fase 4 ("rede toda, coordenar!"), interface por
interface ou com rollover de key-id.

**Status:** ✅ **fechada (2026-07-24) — Opção A.**

## 13. 🆕 DM4170 faz L3 (SVI sobre QinQ) ou fica só L2, empurrando o roteamento pro NE8000?

O desenho em [02-arquitetura-alvo.md](02-arquitetura-alvo.md) hoje assume que o DM4170 termina
**SVI roteada sobre a tag interna do QinQ** para as ~50 VLANs de site (OSPF area1 incluso) — e essa
é exatamente a origem do **bloqueio técnico nº 1** (confirmar com a Datacom se o DmOS suporta isso
e quantos IPs secundários aceita por SVI). Levantada uma alternativa: e se o DM4170 fizer **só L2**
(QinQ termination — traduzir outer+inner tag em VLANs simples) e o **NE8000 assumir o roteamento**
(SVIs + OSPF area1 dos POPs) dessas VLANs, exatamente como já faz hoje para as VLANs de POP que já
tem em paralelo (`Gi0/1/8.719 MK_POP_PANTANO`, `.778 MK_POP_JUCA_ANA` etc.)?

- **Opção A — DM4170 faz L3 (desenho atual do [02](02-arquitetura-alvo.md)):** DM4170 termina as
  SVIs QinQ e fala OSPF area1 com os POPs; sobe pro NE8000 só por um link de núcleo dedicado.
  - Risco: depende 100% da confirmação do DmOS (bloqueio nº1) — se o DmOS não suportar SVI sobre
    tag interna, o plano inteiro trava.
  - Ganho: distribui a função de roteamento entre dois equipamentos (não concentra tudo no NE8000).
- **Opção B — DM4170 só L2:** DM4170 faz apenas QinQ termination (função L2, suporte muito mais
  garantido em qualquer switch); as ~50 VLANs sobem como trunk 802.1q simples até o NE8000, que
  termina cada uma como subinterface roteada (SVI/OSPF) — **padrão que o NE8000 já usa hoje** para
  dezenas de VLANs de POP.
  - Ganho: **elimina o bloqueio técnico nº1** — QinQ termination em L2 é feature padrão, não
    depende de confirmação especial da Datacom. Reaproveita capacidade já comprovada do NE8000.
  - Risco: concentra ainda mais função crítica no NE8000 (já é o core BGP/OSPF/FlowSpec/firewall
    da ISP inteira) — SPOF maior, reforça a urgência da decisão #3 (redundância/HA). Qualquer
    tráfego VLAN-a-VLAN (se existir) passaria a dar hairpin DM4170→NE8000→DM4170 — mas como a
    topologia é essencialmente router-on-a-stick (cada VLAN é um p2p de POP até o core, sem
    tráfego lateral entre POPs), esse custo é provavelmente desprezível na prática.

**✅ Decidido (usuário, 2026-07-24): Opção B — DM4170 fica só em L2.** Nenhuma SVI no DM4170:
ele faz apenas QinQ termination (traduz outer+inner tag em VLANs simples) e entrega tudo — as ~50
VLANs de acesso e as VLANs simples de serviço — como trunks 802.1q aos roteadores. ~~15 NTP,
18 SERVERINO e 1066 GERADOR terminariam todas no NE8000.~~ → **Refinado em 2026-08-06:** 18/1066
seguem no NE8000; VLAN 15/NTP e redes privadas locais terminam na CCR. Isso **elimina o bloqueio
técnico nº1** (SVI sobre tag interna QinQ no
DmOS) — deixa de ser pré-requisito do corte.

**Efeitos em cascata (a propagar):**
- [02-arquitetura-alvo.md](02-arquitetura-alvo.md) seções 2/3 e a tabela de equipamentos —
  reescrever para refletir DM4170 = só L2.
- [04-plano-migracao.md](04-plano-migracao.md) — remover confirmação DmOS da lista de
  pré-requisitos; mapa função→destino muda "Roteamento inter-VLAN" pro NE8000.
- [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md) — VLANs QinQ e simples de acesso vão ao
  NE8000; redes privadas locais vão à CCR.
- [08-vlans-e-portas.md](08-vlans-e-portas.md) — a pendência "confirmar com a Datacom" deixa de
  bloquear.
- ~~Cresce a lista de subinterfaces/adjacências OSPF do NE8000 (estimativa original: +27 QinQ + 3
  simples; refinada para +27 QinQ + 2 simples) — dimensionar capacidade.~~ →
  ✅ **confirmado (usuário, 2026-07-24): capacidade livre**, sem restrição de licença/hardware
  para essa ordem de grandeza. Deixa de ser bloqueio do plano de corte.
- Decisão #3 (redundância/HA) fica mais urgente — o NE8000 concentra ainda mais função crítica.

**Status:** ✅ **fechada — Opção B (2026-07-24).**

## 12. 🆕 Clusters Proxmox sem gerência prevista na CCR1036

Confirmado o modelo (usuário, 2026-07-23): cada cluster Proxmox tem **um IP privado de gerência do
hypervisor** + várias VMs com IP público próprio (que não passam pela CCR1036, saem por segunda
NIC direto na VLAN 16). Cruzando os clusters no Dude ([11](11-cruzamento-dude-devices.md)) contra o
plano de portas da CCR1036 ([10](10-enderecamento-ccr1036.md)), **2 de 4 clusters ficaram de fora**:

| Cluster | IP de gerência | Estava no plano? |
|---|---|---|
| Proxmox Docker | `192.168.116.122/30` | ✅ sim (`ether3`) |
| Proxmox HubSoft | `192.168.115.210/30` | ❌ não |
| Proxmox DNS | `192.168.115.138/30` | ❌ não |
| Proxmox Zabbix | não identificado no Dude | (coberto pela "mgmt privada nova" já prevista em `ether5`) |

**O que falta:** ✅ **Os dois confirmados (2026-07-24)** — `ip -4 -o addr show` rodado direto nos
hosts físicos `px-hubsoft` e `proxmox-dns` mostra `vmbr0` com `192.168.115.210` e `192.168.115.138`
respectivamente, mesmo padrão do Docker (é a gerência do hypervisor, não de uma VM). Falta agora
só reservar VLAN/subinterface no NE8000 pra cada um (decisão de portas/VLAN, não mais incerteza de
IP). 🆕
**Nota (2026-07-24):** as referências a `ether3`/`ether5`/`ether7`/`ether8` **abaixo** eram do
plano de portas físicas antigo da CCR1036 — com a correção do usuário (servidores agora plugam no
**DM4170**, que entrega VLANs por trunk pra CCR1036), essas passam a ser **VLANs no trunk**, não
portas físicas dedicadas. Ver [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md) atualizado.

🆕 **Achado adicional (mesma investigação):** dentro dos clusters há também **VMs privadas** (sem
IP público) que não cabem no `/30` de gerência do hypervisor — `Radius HubSoft`
(`192.168.115.214`), `Dude VLSUL` (`192.168.17.38`), `Dude PM CPV` (`192.168.17.42`),
`Servidor Monsta` (`192.168.115.62`). Cada uma está numa sub-rede própria, diferente da do
hypervisor. Não está definido se saem pela mesma porta física do hypervisor (bridge/VLAN adicional
dentro do Proxmox) ou por outro caminho — precisa de confirmação antes de fechar o endereçamento
desses clusters. Mapeamento completo (todos os IPs, hypervisor + VMs, dos 4 clusters) em
[12-mapeamento-proxmox.md](12-mapeamento-proxmox.md).

🆕 **Achado mais recente:** o cluster **Zabbix** pode não ter gerência privada nenhuma hoje — o
device `"Proxmox Zabbix"` no Dude está no IP **público** `177.72.104.5`, com MAC de fabricante
real (Hewlett Packard), sugerindo que é o próprio hypervisor físico com a interface direto no
bloco público, não uma VM. Se confirmado, migrar esse cluster não é só "trocar gateway" — é
**redesenhar** pra ele ganhar gerência privada pela primeira vez. Ver
[12-mapeamento-proxmox.md](12-mapeamento-proxmox.md) para os detalhes e as duas hipóteses
levantadas.

🆕 **Recomendação (2026-07-23): VLAN, não troca física.** O Proxmox suporta bridge VLAN-aware
nativamente — dá pra colocar a gerência nova numa VLAN privada e manter as 8 VMs públicas em
outra (VLAN 16), na mesma NIC física, bastando o switch de topo de rack tratar essa porta como
trunk com as duas tags. É o mesmo padrão que os outros 3 clusters (Docker, HubSoft, DNS) já usam
— só o Zabbix está fora do padrão hoje. Sem cabeamento novo, sem "virada" disruptiva.

~~**Único risco a checar:** serviço amarrado em `.5`.~~ ✅ **Resolvido em 2026-08-05:** inspeção
direta encontrou somente Proxmox `8006` e SSH `45345`; HTTP/HTTPS 80/443 recusavam conexão.

✅ **Checklist item 1 investigado (2026-07-24, releitura do export do RB3011)** — achado
**revisto** depois de confirmar que `.5` é literalmente o IP do hypervisor Proxmox:
- As duas regras de firewall pra `.5`: `LIBERA CALLSYS` (dst-port `!45345`) — 🆕 **confirmado
  morto (usuário)**, não migra. ~~`LIBERA HUBSOFT PARA O BRASIL` confirmado vivo~~ → ❌
  **reclassificado como resíduo em 2026-08-05**. A regra era **mais aberta do que parecia**: não tem
  `src-address-list` nenhum (a lista `BRASIL` no nome é órfã, nunca é referenciada em regra
  `chain=forward` — ver decisão #7) e libera **todas as portas exceto a 148**, de qualquer origem
  na internet, direto no IP do hypervisor. Isso inclui a porta `8006` (GUI/API do Proxmox) — não
  por regra dedicada, mas porque a regra "Hubsoft" é ampla demais e não exclui ela.
- O backup FTP semanal (`script backup_ftp`) aponta pro host `177.72.104.131` ("Storage BCP") —
  **não tem relação com `.5`**.
- No Dude, `.5` é monitorado só como *up/down* genérico ("Proxmox Zabbix") — sem probe específico
  de porta/serviço.

**Risco encerrado pela migração:** a exposição era da gerência, não de uma aplicação HubSoft.
O IP `.5` foi removido do hypervisor em 2026-08-05 e as regras não devem ser portadas.

✅ **Confirmado (usuário, 2026-07-23): standalone, ~10 VMs.** Não é nó de cluster Proxmox — troca
de IP não exige reconfigurar corosync/quorum, é a operação mais simples possível desse tipo. A
contagem de VMs bate com o mapeamento do [12](12-mapeamento-proxmox.md) (8 públicas + 3 privadas).

**Checklist da troca:**
1. Confirmar se algo aponta pro `.5` como host (GUI/API porta `8006`, backup, allowlist de firewall).
2. Criar a VLAN/interface de gerência privada nova **em paralelo** (bridge VLAN-aware do Proxmox
   não exige reboot) — não editar a interface pública existente direto.
3. Validar alcance pela VLAN nova antes de remover o IP público da interface antiga.
4. Atualizar o Dude (monitora pelo `.5` hoje) e qualquer allowlist de firewall.
5. Reportar aqui o IP privado novo para fechar o [12](12-mapeamento-proxmox.md) e a decisão #9
   (porta/VLAN dedicada na CCR1036, mesmo padrão de `ether7`/`ether8`).

**Status:** ✅ checklist executado em 2026-08-05; IP privado `.10`, `.5` removido e Dude precisa
ser atualizado de `.5` para `.10`.

🆕 **Confirmação direta 2026-07-24** ([`scripts/proxmox-mapear-vms.sh`](../scripts/proxmox-mapear-vms.sh)
e [`scripts/docker-mapear-containers.sh`](../scripts/docker-mapear-containers.sh), rodados nos
**4 clusters** — dados brutos em `config/proxmox-*/`): **os 4 clusters foram consultados
diretamente, não só inferidos pelo Dude.**

- **HubSoft e Zabbix** (13 VMs): bateram exatamente com o Dude, incluindo as 4 VMs privadas órfãs
  (Radius HubSoft `192.168.115.214`, Dude VLSUL `192.168.17.38`, Dude PM CPV `192.168.17.42`,
  Servidor Monsta `192.168.115.62`). **Nenhuma VLAN tag em nenhuma VM** — público e privado
  dividem o mesmo `vmbr0` sem separação.
- **Docker/CDNTV**: os 5 sistemas já esperados bateram, **mais 2 novos** (`CdnTV-Origin`
  `177.72.104.107`, `CdnTV-Edge` `177.72.104.108`, fora do `/27`). A VM "Docker-Netpal" em si roda
  dezenas de containers (NetBox, phpIPAM, Portainer, stack PowerDNS completo, Smokeping, NTP
  server da rede toda, UniFi Controller, Wiki) em **redes macvlan com VLAN tag** (`18`, `38`) —
  diferente do padrão achatado do HubSoft/Zabbix. Ver [12](12-mapeamento-proxmox.md) para o
  inventário completo.
  🆕 **Atualização operacional (usuário, 2026-08-05):** `DNS2-Recursivo-104.21`
  (`177.72.104.21`) foi removido intencionalmente e não é mais usado — **não recriar/não migrar**.
  O nome histórico da rede Docker `IP-DNS-177.72.104.21` pode permanecer, pois os outros cinco
  containers ativos ainda usam essa macvlan; o nome da rede não significa que o IP `.21` esteja
  ocupado.
- **DNS**: 4 VMs confirmadas, incluindo a resolução de `.26` (~~API-ZAP~~ → ✅ **API-WHATS**,
  2026-08-06; o API-ZAP real é o `.23` = APLICACOES — ver decisão #6 acima) e a
  descoberta de que `.28`+`.58` (antes tratados como possivelmente 2 sistemas) são o mesmo host
  (`NS-UNBOUND`). 🆕 **Complemento confirmado diretamente em 2026-08-05:** `.59/32` também é IP
  secundário/loopback da mesma VM `NS-UNBOUND`; a rota do RB3011 via `.28` explica a ausência de
  ARP próprio para `.59`.

**Conclusão sobre a hipótese "VLAN, não troca física" (generalização):** ✅ correto pra
HubSoft/Zabbix (achatado, sem VLAN nenhuma) — ❌ **não generaliza** pro Docker/CDNTV, que já usa
VLAN tag em parte das interfaces. Cada cluster precisa ser tratado caso a caso, não como um
padrão único da casa.

**Status:** ✅ **os 4 clusters Proxmox têm endereçamento 100% confirmado por consulta direta.**
🆕 **VLANs servidores fechadas (usuário, 2026-07-27) — modelo 2 VLANs:** privada=**100**,
pública=**16** (confirmado livre/existente no SW_JDF). Substitui a ideia de 210/138/116/999
por cluster. Ver [16](16-etapa1-proxmox-vlans-datacom.md).

🆕 **IPs dos hypervisors (usuário, 2026-07-27):** **todos os Proxmox só com IP privado** na
VLAN 100 — nenhum hypervisor com IP no `/27`. ✅ **Subnet fechada: `192.168.254.0/24`**
(`.1` GW · `.10` Zabbix · `.11` Docker · `.12` DNS · `.13` HubSoft). Docker/DNS/HubSoft saem
dos `/30`; Zabbix sai do `.5`. IP público/fixo só nas VMs (`tag=16`). Ver [16](16-etapa1-proxmox-vlans-datacom.md).
HubSoft+Zabbix na **mesma madrugada** (mesmo RB750).

✅ **Execução Docker + DNS concluída (2026-08-05):** Docker está em `.11/24` e DNS em `.12/24`,
ambos somente na VLAN 100, com gateway `.1`; os `/30` antigos `.122` e `.138` foram removidos dos
hosts. No Proxmox DNS, as VMs 101/102/103/105 estão `running` e com `tag=16`; `.24`, `.26`, `.29`
e `.28/.58/.59` respondem sem perda. O `NS-UNBOUND` voltou a resolver com `NOERROR` após desativar
o transporte IPv6 sem rota (`do-ip6: no`). ~~A pendência operacional ficava em HubSoft e
Zabbix.~~ ✅ Ambos foram concluídos depois pelo switch temporário.
Evidência:
[`config/proxmox-dns/fase2-concluida-2026-08-05.txt`](../config/proxmox-dns/fase2-concluida-2026-08-05.txt).

⚠️ **Pré-check HubSoft (2026-08-05):** host `px-hubsoft` saudável em `.210/30`, `vmbr0`
VLAN-aware e somente `eno1` conectado; VMs 101 RADIUS (`.214`) e 102 HubSoft (`.16`) estão
`running`, mas sem QEMU Agent. Todos os gateways/serviços e internet responderam. O TTL 63 de
`.214` confirmou que o RADIUS usa outra rede, `192.168.115.212/30`, cujo gateway `.213` também
está na `Bridge IP Publico` do RB3011. O script antigo movia apenas `.209/30` e estava incompleto.
Além disso, ativar VLAN filtering no RB750 para migrar só a porta p4 reclassifica também o tráfego
untagged do Zabbix, WireGuard e gerência do NE8000; portanto **HubSoft não pode ser virado
isoladamente pelo procedimento antigo**. ✅ **Escopo reafirmado pelo usuário em 2026-08-05:**
esta rodada é somente organização/inventário dos IPs; DM4170 e CCR não entram agora, não haverá
recabeamento nem mudança no RB750. Para o futuro, os caminhos seguros continuam sendo porta nova
direta no DM4170, segundo cabo temporário ou corte coordenado HubSoft+Zabbix. Evidência:
[`config/proxmox-hubsoft/precheck-migracao-vlan100-2026-08-05.txt`](../config/proxmox-hubsoft/precheck-migracao-vlan100-2026-08-05.txt).

❌ **Tentativa controlada abortada (2026-08-05):** foi criado temporariamente no RB3011 um
handoff da VLAN 100 tagged sobre a `Bridge IP Publico`, contando com a RB750 flat para transportar
a tag até `ether4`. O `px-hubsoft` recebeu `.13/24` temporário em `vmbr0.100`, mas não alcançou
`.1` (3/3 perdidos). Rollback completo no host e RB3011; `.209`, RADIUS `.214` e HubSoft `.16`
responderam 3/3 depois. **Sem alteração persistente e sem nova tentativa hoje.** Evidência:
[`config/proxmox-hubsoft/tentativa-vlan100-rollback-2026-08-05.txt`](../config/proxmox-hubsoft/tentativa-vlan100-rollback-2026-08-05.txt).

🔎 **Diagnóstico refinado na mesma data:** a primeira tentativa não saía da NIC porque faltava
VLAN 100 no `vmbr0 self`. Após adicionar a associação temporária, `tcpdump` confirmou ARP tagged
na `eno1` e o sniffer confirmou os mesmos quadros chegando à RB750 `ether4`. Ainda assim não houve
resposta de `.1`; desativar hw-offload em `ether4/ether5` e declarar VLAN 100 explicitamente com
`vlan-filtering=yes` na RB750 também não resolveu. Tudo foi novamente revertido e validado. A
~~falha final está depois da entrada `ether4` da RB750 ou no handoff entre as bridges do RB3011;
não há evidência suficiente para apontar um único equipamento sem captura adicional.~~

✅ **Causa isolada por captura no RB3011 (2026-08-05):** com `ether10 hw=no`, os ARPs VLAN 100
chegaram até o RB3011 e foram decapsulados corretamente em `vlan100-rb750-test` (RX, sem tag,
56 bytes). A porta virtual estava `learning=yes` e `forwarding=yes`, sem bridge filter, bridge NAT
ou IP firewall. Porém, os mesmos quadros apareceram na `bridge-servidores` como **QinQ
`vlan=16,100`**, com 64 bytes, e nunca chegaram à `vlan100-servidores`. O handoff VLAN 100 reverso
entre `Bridge IP Publico` e `bridge-servidores` interage com o `vlan16-servidores` já existente
entre as mesmas duas bridges, criando empilhamento das tags 16+100. Portanto, ~~hw-offload era a
causa forte~~ ✅ offload e RB750 foram descartados como causa única; **não criar um segundo handoff
VLAN entre essas bridges**. Rollback final confirmou RB3011 limpo, Proxmox novamente somente em
`.210/30`, e gateway `.209`, RADIUS `.214` e HubSoft `.16` com 3/3 respostas. Evidência completa:
[`config/proxmox-hubsoft/diagnostico-vlan100-preparacao-2026-08-05.txt`](../config/proxmox-hubsoft/diagnostico-vlan100-preparacao-2026-08-05.txt).

✅ **Alternativa temporária executada e HubSoft concluído (2026-08-05):** foi intercalado um switch
gigabit não gerenciável na `ether8`, que já entrega VLAN 100 native e VLAN 16 tagged. O DNS volta
ao switch e foi validado; a `eno2` do R720 HubSoft recebeu `vmbr1` com `.13/24`. A VM HubSoft
`.16` migrou para `vmbr1/tag 16`; a VM RADIUS `.214` migrou untagged e seu gateway `.213/30` foi
movido no RB3011 para `vlan100-servidores`. Aplicação HubSoft e autenticação RADIUS foram validadas.
Por fim, default route passou a `.1`, `.210/30` saiu e nenhuma VM permaneceu em `vmbr0`. Como o
cabo não podia ser retirado, `ether4 - Proxmox HubSoft` foi desativada na RB750; a `eno1` confirmou
`NO-CARRIER` e todos os testes seguiram sem perda. Evidências:
[`config/proxmox-hubsoft/plano-switch-temporario-2026-08-05.md`](../config/proxmox-hubsoft/plano-switch-temporario-2026-08-05.md) e
[`config/proxmox-hubsoft/teste-vmbr1-segundo-cabo-2026-08-05.txt`](../config/proxmox-hubsoft/teste-vmbr1-segundo-cabo-2026-08-05.txt).

🆕 **Zabbix também suporta segundo cabo (pré-check 2026-08-05):** o `proxmox3` tem quatro portas
Broadcom. `enp3s0f0` sustenta `vmbr0`/`.5`; `enp3s0f1` já está configurada como `10.1.1.2/24` e
~~não deve ser reutilizada~~ ✅ **o usuário confirmou que não é usada; a configuração é órfã**.
`enp4s0f0` e `enp4s0f1` estão livres, sem IP e sem carrier. Portanto,
`enp4s0f0` pode testar `.10/24` em bridge separada pelo mesmo switch temporário, mantendo `.5` e
as VMs no cabo antigo. Isso confirma viabilidade física, não autoriza ainda mover as VMs: o
`vmbr0` atual não é VLAN-aware e as redes privadas do cluster ainda precisam de tratamento.
Evidência: [`config/proxmox-zabbix/precheck-segundo-cabo-2026-08-05.txt`](../config/proxmox-zabbix/precheck-segundo-cabo-2026-08-05.txt).

✅ **Porta escolhida pelo usuário:** reutilizar `enp3s0f1` (NIC 2, MAC `44:1E:A1:48:2F:02`) para
o segundo cabo. O endereço órfão `10.1.1.2/24` já foi removido do estado ao vivo, com backup de
`/etc/network/interfaces`; a configuração persistente e a bridge `.10/24` aguardam link físico.
`enp4s0f0` e `enp4s0f1` permanecem como reserva.

✅ **Zabbix concluído (2026-08-05):** `enp3s0f1` recebeu `vmbr1/.10`, VLAN-aware; as VMs
102–108/110 públicas estão em `tag=16`, e 100/101/109 privadas estão untagged. Os gateways
`.37/30`, `.41/30` e `.61/30` foram movidos para `vlan100-servidores`. `.5/27` saiu do host,
default route passou a `.1`, `ether3` foi desativada na RB750 e `enp3s0f0` confirmou
`NO-CARRIER`. Zabbix HTTP/HTTPS, Docs HTTP, SFTP TCP/45345, Monsta web e todos os IPs foram
validados. Evidência:
[`config/proxmox-zabbix/teste-vmbr1-segundo-cabo-2026-08-05.txt`](../config/proxmox-zabbix/teste-vmbr1-segundo-cabo-2026-08-05.txt).

**Status final da decisão #12:** ✅ **concluída para os 4 Proxmox.**

🆕 **Achado que resolve parte da pendência HubSoft (2026-07-24):** `/interface bridge host print`
no RB3011 mostrou que os MACs do cluster HubSoft aparecem aprendidos no **mesmo `ether10` do
cluster Zabbix** — ou seja, HubSoft nunca teve cabo dedicado, compartilha o segmento físico com o
Zabbix. ✅ **Switch intermediário identificado (topologia física do usuário, 2026-07-24): é o
RB BRIDGE 750 (RB750)** — o `ether10` do RB3011 vai pro RB750, que agrega Zabbix (p3), HubSoft (p4)
e a gerência do NE8000 (p2). Ver [`config/topologia-fisica-rack.md`](../config/topologia-fisica-rack.md).
Não precisa reservar porta nova dedicada pro HubSoft na CCR1036 — só garantir que a VLAN de
gerência dele viaje junto com a do Zabbix. ✅ Sobre o **DNS** (`ether8`): a topologia mostra que ele
**pluga direto** no RB3011 (não compartilha com ninguém, é o host Proxmox DNS / HP 360 G7).

## 14. 🆕 Firewall dos servidores locais: subir sem regra dedicada, endurecer depois

**✅ Decidido (usuário, 2026-07-24): servidores locais sobem sem firewall dedicado inicialmente.**
Em vez de pré-montar e ativar as zonas/regras por servidor na janela de corte (como o
[04-plano-migracao.md](04-plano-migracao.md) assumia — "pré-criar zonas de firewall... desativado
até a janela"), a estratégia agora é: os servidores atrás do DM4170/CCR1036/NE8000 voltam a
funcionar primeiro (conectividade), e as regras de firewall por zona/serviço (diretriz 3/4 do
[05-limpeza-politicas.md](05-limpeza-politicas.md)) são construídas e aplicadas **depois**,
incrementalmente — não é pré-requisito da janela de corte.

**Motivação (contexto do achado da decisão #7/#12):** reduz o risco da janela — menos coisa nova
pra validar no mesmo momento do corte físico. Também é coerente com o estado atual real: o achado
de hoje mostrou que o RB3011 já tem pelo menos uma regra ("Hubsoft" em `.5`) que na prática está
totalmente aberta (sem origem restrita) — subir sem firewall dedicado não é uma regressão de
segurança tão grande quanto pareceria à primeira vista, já que o baseline de hoje já não é
fechado.

**Efeitos em cascata (a propagar):**
- [04-plano-migracao.md](04-plano-migracao.md) — Fase 0, item 3: não é mais "pré-criar zonas
  desativadas para ativar na janela"; firewall dos servidores vira trabalho **pós-corte**.
- [05-limpeza-politicas.md](05-limpeza-politicas.md) — Passo 1 (confirmar sistemas vivos) deixa de
  ser pré-requisito do corte (já estava sendo tratado como adiado) — agora fica formalmente
  desacoplado: é insumo pro endurecimento pós-corte, não bloqueia agendar a data.
- **Atenção:** isso não se aplica ao firewall de **gerência** (ACL `IPV4_NOC_NETPAL`/`RANGENETPAL`
  equivalente) nem ao NAT/DST-NAT essenciais (Dude, TS SIX) — esses continuam no escopo da janela,
  só as regras específicas por servidor/sistema é que ficam pra depois.

**Status:** ✅ **fechada (2026-07-24).**
