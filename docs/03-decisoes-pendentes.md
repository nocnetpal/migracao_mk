# Decisões pendentes

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

## 2. Lista de equipamentos Mikrotik a remover

Usuário confirmou que **todo o parque desse trecho é Mikrotik**, não só o gateway. Falta:

- Lista completa dos equipamentos.
- Função de cada um hoje.
- Se algum precisa de substituto funcional além do Datacom/NE8000 (ex.: um MK fazendo hotspot não tem equivalente natural em switch L3).

**Status:** aguardando envio do usuário.

## 3. Redundância / HA

Ainda não discutido se o desenho alvo (Datacom + NE8000) deve ter redundância, ou se aceita ponto único de falha como hoje (só que trocando o equipamento).

**Status:** não discutido.

## 4. Roteamento dinâmico (OSPF) — ✅ esclarecido pelo export do NE8000

Confirmado: o NE8000 ("BGP_NETPAL") **já é** vizinho OSPF da GW Servidores hoje, pela subinterface
`GigabitEthernet0/1/8.28` (`192.168.116.33/30`, area 0.0.0.1, mesma chave MD5 `ntprb1030`) — bate
exatamente com o gateway padrão que a GW Servidores usa. Ver detalhes em
[06-ne8000-bgp-core.md](06-ne8000-bgp-core.md).

**Refinado pelo `/ip address` da GW Servidores:** o link **não é um cabo direto**. Do lado Mikrotik,
os dois endereços estão em `sfp1 - UPLINK SW TOPO DO RACK`, ou seja, passam por um switch de topo de
rack. E o segmento carrega **duas sub-redes**, não uma:

| Lado | Endereços | Interface |
|---|---|---|
| GW Servidores | `192.168.116.34/30` + `177.72.104.53/30` | `sfp1` (untagged, multinetting) |
| NE8000 | `192.168.116.33/30` + `177.72.104.54/30` (`sub`) | `Gi0/1/8.28` (dot1q VLAN 28) |

O Datacom terá de reproduzir isso como uma SVI na VLAN 28 com IP primário **e** secundário.

O que ainda falta decidir:
- O Datacom assume essa adjacência OSPF no lugar da GW Servidores (mesma VLAN/subrede,
  reautenticando com o NE8000), ou o link muda de desenho?
- Os outros enlaces ponto a ponto hoje nomeados como VLANs no MK (`VLAN713 - GW SOLIDAO`,
  `VLAN198 - Pantano => Juca Ana`, `VLAN11_eoip`) — o NE8000 já tem subinterfaces equivalentes
  (`.713 MK_POP_SOLIDAO`, `.719 MK_POP_PANTANO`, `.778 MK_POP_JUCA_ANA`), mas a correspondência
  exata porta-a-porta ainda precisa ser confirmada fisicamente antes do corte.
- ~~**Novo:** o escopo cresceu muito... falta `/interface vlan print`~~ → ✅ **mapeado pela coleta 2**
  ([08-vlans-e-portas.md](08-vlans-e-portas.md)): todas as VLANs entram por **uma única porta**
  (`sfp1`, 1 GE) em estrutura QinQ (tag externa = site, interna = serviço). Fisicamente o corte é
  1 trunk + ~5 portas de servidor.
- **Novo (técnico):** confirmar com a Datacom se o DmOS faz **SVI roteada sobre a tag interna de
  QinQ** e quantos IPs secundários aceita por SVI. Se não fizer, ou o switch de topo de rack
  desempacota a tag externa, ou o DM4170 assume o lugar dele.
- **Novo (técnico):** confirmar também **MTU/baby giants no DmOS** — hoje a `sfp1` roda l2mtu 1600
  (outer 1596 / inner 1592) por causa do QinQ; o trunk novo precisa comportar o mesmo, e o
  MSS-clamp do mangle precisa de equivalente no novo desenho.
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

**Status:** adjacência principal detalhada (VLAN 28, duas sub-redes, via rede de acesso);
mapa VLAN→porta completo ([09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)). 🆕 Com o
escopo fechado em "só a GW Servidores" (2026-07-23), a confirmação de **SVI roteada sobre tag
interna de QinQ no DmOS volta a ser o bloqueio técnico nº 1** — é o DM4170 quem herda as SVIs
QinQ do RB3011. ~~Plano B: o switch de agregação desempacota a tag externa~~ — **inválido**: a
rede de acesso não será mexida; a confirmação do DmOS é praticamente obrigatória.

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
cliente obrigatório, AES-256/SHA1), usando os mesmos 4 usuários. A decisão cobre **duas VPNs**.

⚠️ Achados de segurança a corrigir ao recriar (não replicar): `use-ipsec: no`, `mschap1` habilitado,
senhas em texto claro — e, pior, **ambos os profiles PPP têm `use-encryption=no`** (até o
"default-encryption" foi alterado): hoje **nenhuma sessão L2TP tem criptografia obrigatória**.
Ver [07-enderecamento-ip.md](07-enderecamento-ip.md).

**Status:** natureza do serviço esclarecida (L2TP sem criptografia + OpenVPN com certificado).
✅ **Destino definido (2026-07-23):** a **Mikrotik CCR1036** nova, ligada diretamente ao NE8000,
hospeda a VPN de equipe recriada (redesenho, não porte — sem mschap1, criptografia obrigatória).

🆕 **Atenção ao escopo, achado do cruzamento com o Dude ([11](11-cruzamento-dude-devices.md)):**
existem **outras duas VPNs** na rede, hospedadas em servidores Proxmox à parte (não no RB3011) —
"VPN - WireGuard" em `177.72.104.19` e "OpenVPN - 2" em `177.72.104.12`. Essas **provavelmente não
fazem parte desta decisão**: não dependem do RB3011 para existir, só precisam que o firewall/NAT
novo do NE8000 preserve o acesso a esses hosts (tratamento igual a qualquer outro servidor do
Passo 1 do [05](05-limpeza-politicas.md)). Confirmar com o usuário antes de fechar de vez.

## 6. Automações que rodavam como script no Mikrotik

Duas rotinas hoje são scripts RouterOS, sem equivalente automático em switch/roteador:

- Backup semanal (config + export) via FTP.
- Notificação via API HTTP quando um host monitorado sobe/cai (netwatch → script `dude`).

Nenhum desses recursos existe nativamente em um switch Datacom ou, provavelmente, no NE8000 da
mesma forma. Precisa decidir onde essas automações passam a rodar (ex.: servidor de gerência
existente, Zabbix/Dude/outro NMS já em uso).

**Status:** em aberto. 🆕 A **CCR1036** nova do desenho alvo (ver decisão #5) é a candidata
natural a rodar essas automações — RouterOS roda os mesmos scripts de hoje com ajuste mínimo.

## 7. Geo-allowlist (address-list `BRASIL`)

O MK mantém uma lista enorme de faixas de IP nacionais, usada em pelo menos uma regra de firewall
("LIBERA HUBSOFT PARA O BRASIL"). Confirmar o propósito exato (parece anti-fraude/allowlist para
o sistema de billing Hubsoft) e se precisa ser recriada no NE8000.

**Status:** em aberto.

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
`/27` — ele só não é mais quem traduz endereço. Mecanismo provável (a confirmar, mesmo padrão já
usado hoje pelo MK para `.9`/`.12`/`.19` na decisão #8): o NE8000 mantém o `/27` conectado, e o IP
público específico usado para NAT (`.1`, se for mantido) fica **roteado via next-hop para a
CCR1036** através do link privado novo NE8000↔CCR1036 — a CCR1036 faz a tradução de fato. Os
port-forwards (Dude, TS SIX) só "não mudam de endereço" se essa mesma lógica for aplicada a eles.

**Pendência nova:** confirmar (a) se `.1` continua sendo o IP usado para NAT ou se a CCR1036 recebe
outro IP do `/27`, e (b) a rota específica desse IP até a CCR1036. Ver
[10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md).

**Status:** ✅ **Decidido: Opção B** (usuário, 2026-07-23) — o NE8000 termina o
`177.72.104.0/27`; a VLAN 16 sobe em L2 pelo DM4170. `.1` continua sendo o IP de NAT e os
port-forwards não mudam. Resolve também a decisão #8.

## 10. Possível sobreposição no `177.72.104.60/30` (enlace Juca Ana)

Cruzamento pendente apontado em [08-vlans-e-portas.md](08-vlans-e-portas.md): o MK tem
`177.72.104.61/30` na `VLAN198 - Pantano => Juca Ana` (QinQ) e o NE8000 **também anuncia**
`network 177.72.104.60 0.0.0.3` na OSPF. Se os dois anunciam o mesmo /30, há risco de conflito
de rota — e de loop — no momento do corte, quando a origem do anúncio mudar.

**O que falta:** identificar em qual interface do NE8000 esse /30 existe (subinterface
`.719 MK_POP_PANTANO` ou equivalente) e quem é o dono legítimo do segmento.

**Status:** em aberto — virou pré-requisito do [04-plano-migracao.md](04-plano-migracao.md).

## 11. Estratégia da chave OSPF MD5 (`ntprb1030`) no corte

A chave MD5 da area1 é a **mesma em toda a rede** (dezenas de interfaces no NE8000 e nos MKs de
POP). O plano joga a rotação para a fase 4 ("rede toda, coordenar!"), mas o
[06-ne8000-bgp-core.md](06-ne8000-bgp-core.md) sugere usar chave nova na adjacência do Datacom.
Trocar a chave **só** na adjacência nova significa conviver com duas chaves na área — o que é
válido (MD5 é por-interface), mas precisa ser decisão explícita, não acidental.

- **Opção A** — manter `ntprb1030` no corte (menos variáveis na janela) e rotacionar na fase 4,
  interface por interface ou com rollover de key-id.
- **Opção B** — já nascer com chave nova na adjacência DM4170↔NE8000 e ir migrando as demais
  interfaces aos poucos (convivência de duas chaves por tempo indeterminado).

**Recomendação preliminar: Opção A** — a janela do núcleo já tem variáveis demais; a chave não é
uma vulnerabilidade urgente.

**Status:** em aberto (recomendação: A).

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

**O que falta:** confirmar se `192.168.115.210` e `192.168.115.138` são mesmo os IPs de gerência
dos hypervisors (mesmo padrão do Docker) e reservar porta/VLAN/subinterface no NE8000 pra cada um
— provisoriamente `ether7` e `ether8` da CCR1036 (cabe na variante 12G-4S recomendada).

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

**Status:** em aberto — pendência de endereçamento, não bloqueia o restante do plano.
