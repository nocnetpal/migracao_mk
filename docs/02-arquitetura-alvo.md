# Arquitetura alvo (depois da migração)

> **Atualizado em 2026-07-23** — desenho definido pelo usuário: saem RB3011 ("GW Servidores") e
> RB2011 ("RB Bridge Servidores"); entram **Datacom DM4170** (no lugar do RB3011) e
> **Mikrotik CCR1036** ligada ao DM4170 por trunk. ~~Ligação direta ao NE8000~~ descartada em
> 2026-08-06. O bloco `177.72.104.0/27` vai para o
> **NE8000** (decisões #9/#8 fechadas) — mas **só como IP público + firewall; o NAT (SRC-NAT/DST-NAT)
> vai para a CCR1036**, correção do usuário em 2026-07-23 sobre a decisão #1. Firewall redesenhado
> enxuto e legível, **sem** a geo-allowlist `BRASIL` ([05](05-limpeza-politicas.md)). Estrutura
> deste documento: **físico → L2 → L3**.
>
> **Escopo (definido pelo usuário):** a migração é **apenas da GW Servidores**. A **rede de
> acesso não é tocada** — tudo que já existe em produção (agregação QinQ, subinterfaces
> `MK_POP_*` do NE8000) continua exatamente como está.

## 1. Estrutura física

> 🆕 **Correção do usuário (2026-07-24):** os servidores locais **não penduram mais direto na
> CCR1036**. Todos entram no **DM4170** (que passa a ser o ponto físico único de agregação —
> POPs + servidores), e o DM4170 tem **duas saídas**: uma pro NE8000 (já existia) e uma nova pra
> **CCR1036**. ✅ **Correção final confirmada pelo usuário em 2026-08-06:** não haverá link direto
> CCR↔NE8000. A CCR tem um único uplink, o trunk com o DM4170; por ele recebe a VLAN 16 com
> `177.72.104.4/27`, as redes privadas e o caminho até o gateway `.1` no NE8000.

```
                      Internet / Core (AS 52828)
                                │
                            NE8000 ── core BGP/OSPF (produção), CGNAT de assinantes,
                            │        terminação QinQ dos POPs (INTACTO — não mexer)
                            │        + ganha: /27 (IP público), firewall de servidores
                            │        + 🆕 ganha: SVI + OSPF area1 de TODAS as VLANs de
                            │        acesso (decisão #13 — DM4170 não roteia nada)
                  10GE      │
                  (novo)    │
                            │
                        DM4170 ─── CCR1036 ── NAT (SRC-NAT/DST-NAT)
                    (só L2: QinQ   trunk     WireGuard só pós-migração
                     termination,  link
                     nenhuma SVI)
                    │         │
       trunk QinQ   │         └─ 🆕 servidores locais (VLANs de gerência
       (o cabo que  │            privada, tagged) — TS SIX, Proxmox CDNTV,
        hoje está   │            DNS recursivo, Callcenter/Zabbix, OLT ZTE
        na sfp1     │
        do MK)      │
                     rede de acesso (QinQ) — fora do escopo,
                     nenhuma alteração
```

### Cabeamento previsto

| # | Link | Meio/velocidade | Estado |
|---|------|-----------------|--------|
| 1 | Rede de acesso (toda) | — | **⛔ FORA DO ESCOPO** — nenhuma alteração, inclusive o que existir de caminho para o NE8000 |
| 2 | Rede de acesso ↔ DM4170 (trunk QinQ) | o **mesmo cabo** que hoje termina na `sfp1` do RB3011 muda para o DM4170 na janela (1GE hoje) | troca de cabo no corte |
| 3 | NE8000 ↔ DM4170 (núcleo) | SFP+ 10GE, direto | **novo** |
| 4 | 🆕 Servidores locais → **DM4170** | portas GE ópticas do DM4170, cada servidor numa VLAN de gerência privada própria (tagged) | 🆕 recabeamento no corte — muda de destino (era CCR1036) |
| 5 | 🆕 **DM4170 ↔ CCR1036** | trunk 802.1q novo — carrega VLAN 16 (`.4/27`) + VLANs privadas dos servidores | **novo** — caminho do IP público confirmado em 2026-08-06 |
| 6 | ~~NE8000 ↔ CCR1036 direto~~ | — | ❌ descartado em 2026-08-06; CCR sai somente pelo DM4170 |

### ⚠️ Questões físicas em aberto

1. ~~**Porta livre na rede de acesso para um segundo trunk**~~ — ✅ **resolvido por escopo
   (2026-07-23):** a rede de acesso **não será mexida**; o DM4170 recebe o mesmo cabo do RB3011
   na janela. Consequência: não há trunk paralelo — a migração fatiada por VLAN do
   [04](04-plano-migracao.md) vira **janela única com troca de cabo** (rollback = religar o cabo
   no RB3011).
2. ~~**Os servidores locais são cobre (RJ45) e o DM4170 é todo óptico**~~ → 🆕 **revisado
   (2026-07-24):** os servidores agora entram no **DM4170**, não na CCR1036 — mas o DM4170
   (24GX+12XS) **é 100% óptico**, sem porta RJ45 nenhuma. Assumindo que o cabeamento de cobre dos
   servidores usa **transceiver SFP-RJ45 (1000BASE-T)** nas portas ópticas do DM4170 — solução
   padrão de mercado, mas **vale confirmar com o usuário** antes de fechar a lista de material.
   A CCR1036 deixa de precisar de portas RJ45 pros servidores (só precisa da porta do trunk pro
   DM4170 e da porta pro NE8000) — **isso pode simplificar a escolha de variante da CCR1036**
   (ponto 6 abaixo).
3. ~~**Variante do DM4170** (12×10GE vs 4×10GE+2×40GE)~~ → ✅ **confirmado (usuário, 2026-07-24):
   DM4170 24GX+12XS** — 24 portas GE ópticas (SFP) + 12 portas 10GE ópticas (SFP+), sem 40GE.
   Uplink 10GE pro NE8000 usa uma das 12 SFP+; sobram 11. O novo link pro CCR1036 (item 5 da
   tabela) e as portas dos servidores locais saem das 24 GE SFP.
4. **Caminho da segunda NIC pública** (VLAN 16) dos servidores que precisam de IP público —
   segue fora do escopo do DM4170/CCR1036; a cargo do usuário (provavelmente ligada diretamente à
   rede de acesso, que já transporta a VLAN 16).
5. O **EoIP do NOC morre** com o RB3011 (proprietário Mikrotik, já está down hoje) — o acesso de
   gerência remota precisa de substituto (candidato: VPN na CCR1036).
6. ✅ **Variante da CCR1036 decidida (usuário, 2026-07-24): 8G-2S+.** Com os servidores saindo do
   plano de portas dela (ponto 2 acima), a demanda por RJ45 caiu bastante: só sobra o trunk pro
   DM4170 e o link pro NE8000 — a 8G-2S+ (mais barata) cobre.

## 2. Camada L2

> ✅ **Decisão #13 fechada (usuário, 2026-07-24): DM4170 fica só em L2** — nenhuma SVI nele.
> Ele só termina o QinQ (traduz outer+inner tag em VLANs simples) e entrega as ~50 VLANs de acesso
> e as VLANs simples ao roteador responsável. O **NE8000** termina as VLANs de acesso e as simples
> 18 SERVERINO/1066 GERADOR; ✅ a **VLAN 15 NTP foi reclassificada em 2026-08-06 para a CCR**, pois
> o serviço `.10` é container local no Docker. Cada destino termina como subinterface roteada +
> OSPF area1 onde aplicável) — mesmo padrão que o NE8000 já usa hoje pras VLANs de POP em
> paralelo (`Gi0/1/8.719 MK_POP_PANTANO`, `.778 MK_POP_JUCA_ANA` etc.). **Isso elimina o
> bloqueio técnico nº1** (SVI sobre tag interna QinQ no DmOS) — deixa de ser pré-requisito do
> corte. Custo aceito: mais função crítica concentrada no NE8000 (reforça a urgência da decisão
> #3, redundância/HA). Discussão completa na
> [decisão #13](03-decisoes-pendentes.md#13--dm4170-faz-l3-svi-sobre-qinq-ou-fica-só-l2-empurrando-o-roteamento-pro-ne8000).
>
> ✅ **Detalhado em [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)** — as 60 VLANs do
> RB3011 classificadas uma a uma: 27 QinQ + 2 simples migram para SVIs no **NE8000** (via trunk
> L2 pelo DM4170); VLAN 15 e redes privadas locais terminam na CCR1036; 16 viram só transporte, 11 não
> migram, +3 VLANs novas a criar. Resumo:

**Trunk rede de acesso ↔ DM4170 (herda o papel da `sfp1` do MK) — DM4170 é passagem, não termina nada:**
- **QinQ dos sites** (outer = localidade, inner = serviço): o DM4170 só faz **QinQ termination**
  (função L2 padrão, sem incerteza de suporte) e entrega cada VLAN interna já destagueada (ou
  como novo QinQ próprio, a definir na config) num trunk 802.1q até o NE8000, que termina a **SVI
  roteada** de cada uma.
- **VLAN 16 (IP Público)**: entra taggeada pelo trunk da rede de acesso e **atravessa o DM4170 em
  L2 até o NE8000**, que termina o `177.72.104.0/27` (decisão #9, Opção B) — sem mudança aqui,
  já era L2 nesse trecho mesmo antes da decisão #13. A "Bridge IP Publico" vira uma VLAN comum de
  trânsito. Servidores locais que precisarem de IP público (ex.: Proxmox Zabbix/CDNTV) usam uma
  **segunda NIC** conectada à VLAN 16 na rede de acesso — **não passam pela CCR1036**.
- **VLANs simples de serviço:** 18 SERVERINO e 1066 GERADOR atravessam o DM4170 em L2 e terminam
  no **NE8000**. ~~VLAN 15 NTP no NE8000~~ → ✅ reclassificada para a **CCR** em 2026-08-06:
  gateway `192.168.116.9/30` do container Docker `.10`, rede passiva no OSPF CCR↔NE8000.
- **MTU**: ✅ **decidido (usuário, 2026-07-24) — usar o jumbo frame máximo suportado por cada
  equipamento** nos trunks rede de acesso ↔ DM4170 **e** DM4170 ↔ NE8000 (o QinQ precisa sobreviver
  a um salto L2 a mais até ser terminado), em vez de replicar o valor exato do RB3011 (l2mtu 1600
  → 1596/1592 na `sfp1`). Número concreto de cada equipamento fica pra hora de configurar.

**Links novos:**
- **NE8000 ↔ DM4170**: trunk 802.1q com as ~50 VLANs QinQ + VLANs simples destinadas ao NE8000 +
  VLAN 16 (L2).
  O DM4170 **não participa de nenhuma adjacência OSPF** (decisão #13 — é só L2, sem SVI); cada
  VLAN vira uma subinterface roteada diretamente no NE8000, que fala OSPF com os POPs do outro
  lado do trunk (o DM4170 só encaminha os frames). Não reutilizar a VLAN 28 do MK, que morre com ele.
- 🆕 **DM4170 ↔ CCR1036**: trunk 802.1q novo, carrega a **VLAN 16** (`177.72.104.4/27`) e as VLANs
  privadas dos servidores locais (`vlan10`, `vlan66`, `vlan109`, `vlan116`, `vlan999`) — caminho
  L2 do IP público confirmado pelo usuário em 2026-08-06. Os servidores plugam fisicamente no
  DM4170; o switch só encaminha essas VLANs até a CCR1036.
- ~~**NE8000 ↔ CCR1036 direto**~~: ❌ descartado em 2026-08-06. Todo o caminho da CCR até o
  NE8000 passa em L2 pelo DM4170.
- **VLAN de gerência** padronizada (modelo da ACL `IPV4_NOC_NETPAL` — passo 3 do
  [05](05-limpeza-politicas.md)).

**Não migra (L2 morto):** VLAN13, 17, 21-outer, 51, 53, 92, 250, 742/770, 772 + `VLAN11_eoip` +
bridges `EOIP-NOC`/`loopNETPAL` (lista completa no [09](09-l2-mapeamento-vlans.md)).

## 3. Camada L3 (rascunho — detalhar na próxima etapa)

| Função | Equipamento | Detalhe |
|--------|-------------|---------|
| Dono do `177.72.104.0/27` + firewall de servidores | **NE8000** | `.1` (e as demais) na subinterface da VLAN 16; as ~24 sub-redes de gerência da antiga bridge vão como secundárias ou são redesenhadas. Hosts com IP público dedicado (Hubsoft, Fusion, VOIP etc.) seguem direto, sem NAT. Política nova enxuta por zonas, sem geo-allowlist ([05](05-limpeza-politicas.md)) |
| 🆕 Gateway das redes privadas + NAT | **CCR1036** | CCR termina as VLANs privadas locais (VLAN 100 = `192.168.254.1/24` e demais redes a consolidar), portanto o tráfego atravessa naturalmente o SRC-NAT e sai como `177.72.104.4/27` pela VLAN 16 no mesmo trunk DM4170↔CCR. Sem PBR no NE8000. DST-NAT Dude/TS SIX ainda depende de `.1` vs `.4` |
| 🆕 Roteamento das VLANs de acesso (QinQ, enlaces /30 de POP, gerências de OLT/SW) + VLANs simples de serviço + OSPF area1 | **NE8000** (decisão #13, 2026-07-24 — antes seria o DM4170) | SVIs QinQ + SVIs simples; herda as adjacências OSPF dos POPs (mesmo padrão que já usa hoje pra `MK_POP_*`); redistribute connected/static (ou anúncios explícitos — oportunidade de limpeza); DM4170 só entrega o trunk 802.1q, **não termina nada** |
| Adjacência(s) OSPF de acesso | NE8000 ↔ POPs (via trunk L2 do DM4170) | Mesma chave MD5 da area1 (estratégia: decisão #11); DM4170 é só L2 nesse caminho, não participa da adjacência |
| Rotas estáticas `10.8.0.0/21`, `10.254.0.0/22`, `10.30.0.0/30`, `10.150.150.0/24` | NE8000 | **viram resolução connected** quando o `/27` subir (next-hops `.9`/`.12`/`.19` são hosts do /27) — revisar se ainda fazem sentido |
| VPN de equipe | **CCR1036, pós-migração** | WireGuard somente depois de toda a migração concluída; não entra na bancada nem na janela inicial |
| ~~Automações (backup FTP, netwatch→API)~~ | — | ✅ **Descartadas (usuário, 2026-07-24)** — as duas, não migram. Não entram na config nova |
| DHCP (`VLAN1066 - GERADOR MST`, 1 escopo) | DM4170 ou NE8000 | Trivial — decidir na config |
| FlowSpec/NetStream (`177.72.104.27`) | NE8000 | RR fica **diretamente conectado** — validar sessão BGP e fluxo `:3055` no corte |

## Equipamentos: saem e entram

| Equipamento | Papel hoje | Destino |
|---|---|---|
| RB3011 "GW Servidores" | Agregação L3 (~50 VLANs QinQ), NAT, firewall, VPNs | **sai** — funções divididas entre DM4170 (QinQ termination + agregação física, só L2), NE8000 (SVIs de acesso + OSPF + `/27` + firewall público) e CCR1036 (gateways privados + NAT; WireGuard pós-migração). Automações não migram |
| RB2011 "RB Bridge Servidores" | Bridge L2 dos servidores (TS SIX, Dude, RRFlow, CGNAT-1 mgmt) | **sai** — absorvido pelo DM4170 (decisão #2, 2026-07-24) |
| 🆕 RB750 "RB Bridge 750" | Bridge L2 (gerência NE8000, Proxmox Zabbix, Proxmox HubSoft) | **sai** — 3º MK descoberto na topologia física (2026-07-24), também absorvido pelo DM4170 |
| Rede de acesso (agregação L2/QinQ) | Transporta todas as VLANs dos sites | **⛔ fora do escopo** — nenhuma alteração |
| Datacom DM4170 | — | **entra**: substitui **os 3 MKs** (RB3011 + RB2011 + RB750) fisicamente — decisão #2 (2026-07-24): absorve **toda** a agregação de servidores direto, sem bridge intermediária. **Só faz L2** (decisão #13) — QinQ termination + switching dos ~10 servidores locais, nenhuma SVI. Variante **24GX+12XS** (24× GE SFP + 12× 10GE SFP+, todo óptico). ⚠️ **~8 servidores em cobre → precisam de transceiver SFP-RJ45 (1000BASE-T)** — item de compra (ver decisão #2). [Datasheet](datacom-dm4170-datasheet.pdf) |
| **Mikrotik CCR1036** (variante **8G-2S+**, decidida 2026-07-24) | — | **entra**: gateway das redes privadas + NAT com `177.72.104.4/27`, tudo por um único trunk com o DM4170. Sem link direto com o NE8000. WireGuard só pós-migração. ~~Automações~~ descartadas (decisão #6) |
| NE8000 "BGP_NETPAL" | Core BGP/OSPF, CGNAT assinantes, terminação QinQ de POPs | **fica e ganha**: `/27` (IP público) + firewall de servidores + 🆕 **SVI/OSPF de todas as VLANs de acesso** (decisão #13 — o que seria do DM4170). **NAT não fica aqui** (vai para a CCR1036). O que já existe (QinQ `MK_POP_*`) **não se mexe** |

> 🚨 **Dimensionamento** (mantido da revisão anterior): a GW Servidores tem **101 endereços em
> ~52 interfaces (~45 VLANs)** atendendo POPs, OLTs, switches, rádios e clientes corporativos
> ([07](07-enderecamento-ip.md)). A estratégia de corte em janela única do
> [04](04-plano-migracao.md) lida com isso: toda a config chega pré-montada e testada.

## Ainda não definido

- ~~**SVI roteada sobre tag interna QinQ no DmOS** (bloqueio nº 1)~~ → ✅ **caiu com a decisão
  #13 (2026-07-24)**: DM4170 fica só L2, não precisa mais dessa confirmação com a Datacom.
  ~~MTU/baby giants continua valendo~~ → ✅ **estratégia decidida (2026-07-24): jumbo frame máximo
  de cada equipamento**, número concreto fica pra hora de configurar.
- 🆕 **Detalhar a config de QinQ termination no DM4170** (decisão #13): como cada VLAN interna
  chega ao NE8000 — destagueada em 802.1q simples, ou re-encapsulada. ~~Quantas VLANs/subinterfaces
  o NE8000 aguenta a mais~~ → ✅ **confirmado (2026-07-24): capacidade livre**, sem restrição de
  licença/hardware.
- ~~Redundância/HA (decisão #3 — não discutido~~ → ✅ **decidido (2026-07-24): sem redundância.**
  Desenho alvo mantém pontos únicos: 1 NE8000, 1 DM4170, 1 CCR1036 — aceito conscientemente, mesmo
  com o NE8000 concentrando ainda mais função crítica pela decisão #13.
- ~~Confirmação do papel da CCR1036 nas automações~~ → ✅ automações descartadas (decisão #6).
