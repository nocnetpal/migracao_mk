# Arquitetura alvo (depois da migração)

> **Atualizado em 2026-07-23** — desenho definido pelo usuário: saem RB3011 ("GW Servidores") e
> RB2011 ("RB Bridge Servidores"); entram **Datacom DM4170** (no lugar do RB3011) e
> **Mikrotik CCR1036** ligada diretamente ao NE8000. O bloco `177.72.104.0/27` vai para o
> **NE8000** (decisões #9/#8 fechadas) — mas **só como IP público + firewall; o NAT (SRC-NAT/DST-NAT)
> vai para a CCR1036**, correção do usuário em 2026-07-23 sobre a decisão #1. Firewall redesenhado
> enxuto e legível, **sem** a geo-allowlist `BRASIL` ([05](05-limpeza-politicas.md)). Estrutura
> deste documento: **físico → L2 → L3**.
>
> **Escopo (definido pelo usuário):** a migração é **apenas da GW Servidores**. A **rede de
> acesso não é tocada** — tudo que já existe em produção (agregação QinQ, subinterfaces
> `MK_POP_*` do NE8000) continua exatamente como está.

## 1. Estrutura física

```
                      Internet / Core (AS 52828)
                                │
                            NE8000 ── core BGP/OSPF (produção), CGNAT de assinantes,
                            │  │     terminação QinQ dos POPs (INTACTO — não mexer)
                            │  │     + ganha: /27 (IP público) e firewall de servidores
                  10GE      │  │        1GE
                  (novo)    │  │       (novo)
                            │  │
                        DM4170  CCR1036 ── NAT (SRC-NAT/DST-NAT) + VPN de equipe
                            │      │      (recriada) + automações (backup, netwatch→API)
            trunk QinQ      │      │
            (o cabo que     │      └─ servidores locais em COBRE (RJ45) —
             hoje está na   │         TS SIX, Proxmox CDNTV, DNS recursivo,
             sfp1 do MK)    │         Callcenter/Zabbix, gerência OLT ZTE
                            │
                     rede de acesso (QinQ) — fora do escopo,
                     nenhuma alteração
```

### Cabeamento previsto

| # | Link | Meio/velocidade | Estado |
|---|------|-----------------|--------|
| 1 | Rede de acesso (toda) | — | **⛔ FORA DO ESCOPO** — nenhuma alteração, inclusive o que existir de caminho para o NE8000 |
| 2 | Rede de acesso ↔ DM4170 (trunk QinQ) | o **mesmo cabo** que hoje termina na `sfp1` do RB3011 muda para o DM4170 na janela (1GE hoje) | troca de cabo no corte |
| 3 | NE8000 ↔ DM4170 (núcleo) | SFP+ 10GE, direto | **novo** |
| 4 | NE8000 ↔ CCR1036 | 1GE, direto (RJ45 ou SFP) | **novo** |
| 5 | CCR1036 → servidores locais | 5 portas RJ45 de **gerência privada** (TS SIX, Proxmox CDNTV, DNS recursivo, Callcenter/Zabbix, gerência OLT ZTE — hoje `ether6`–`ether10` do RB3011). Servidores que precisarem de IP público usam uma **segunda NIC** ligada à VLAN 16 na rede de acesso | recabeamento no corte |

### ⚠️ Questões físicas em aberto

1. ~~**Porta livre na rede de acesso para um segundo trunk**~~ — ✅ **resolvido por escopo
   (2026-07-23):** a rede de acesso **não será mexida**; o DM4170 recebe o mesmo cabo do RB3011
   na janela. Consequência: não há trunk paralelo — a migração fatiada por VLAN do
   [04](04-plano-migracao.md) vira **janela única com troca de cabo** (rollback = religar o cabo
   no RB3011).
2. ~~**Os servidores locais são cobre (RJ45) e o DM4170 é todo óptico** — com o RB2011 saindo, o
   cobre perde o destino.~~ ✅ **Resolvido:** a CCR1036 tem portas RJ45 (12× GE no 12G-4S, 8× no
   8G-2S+) — os servidores locais penduram nela. Sobra confirmar a variante (12G-4S vs 8G-2S+).
3. **Variante do DM4170** (12×10GE vs 4×10GE+2×40GE) — define que porta vira o uplink 10GE.
4. **Caminho da segunda NIC pública** (VLAN 16) dos servidores que precisam de IP público —
   fora do escopo da CCR1036; a cargo do usuário (provavelmente ligada diretamente à rede de
   acesso, que já transporta a VLAN 16).
5. O **EoIP do NOC morre** com o RB3011 (proprietário Mikrotik, já está down hoje) — o acesso de
   gerência remota precisa de substituto (candidato: VPN na CCR1036).

## 2. Camada L2

> ✅ **Detalhado em [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)** — as 60 VLANs do
> RB3011 classificadas uma a uma: 27 migram para SVIs QinQ no DM4170, 5 de serviço/servidores,
> 16 viram só transporte, 11 não migram, +3 VLANs novas a criar. Resumo:

**Trunk rede de acesso ↔ DM4170 (herda o papel da `sfp1` do MK):**
- **QinQ dos sites** (outer = localidade, inner = serviço): o DM4170 termina **SVI roteada sobre
  a tag interna** — ⚠️ **bloqueio técnico nº 1 do projeto**: confirmar com a Datacom se o DmOS
  suporta isso e quantos IPs secundários aceita por SVI (decisão #4). ~~Plano B: a rede de
  acesso desempacota a tag externa~~ — **inválido**: exigiria mexer nela, e ela está fora do
  escopo. A confirmação do DmOS é, portanto, praticamente obrigatória.
- **VLAN 16 (IP Público)**: entra taggeada pelo trunk da rede de acesso e **sobe em L2 pelo
  DM4170 até o NE8000**, que termina o `177.72.104.0/27` (decisão #9, Opção B). A "Bridge IP
  Publico" vira uma VLAN comum de trânsito. Servidores locais que precisarem de IP público
  (ex.: Proxmox Zabbix/CDNTV) usam uma **segunda NIC** conectada à VLAN 16 na rede de acesso —
  **não passam pela CCR1036**.
- **VLANs simples de serviço** (15 NTP, 18 SERVERINO, 1066 GERADOR MST): SVIs no DM4170.
- **MTU**: baby giants (≥1600) no trunk rede de acesso ↔ DM4170 e no caminho QinQ (hoje l2mtu
  1600 → 1596/1592 na `sfp1`).

**Links novos:**
- **NE8000 ↔ DM4170**: carrega a VLAN 16 (L2) + VLAN dedicada de núcleo/OSPF (adjacência
  DM4170↔NE8000 — não reutilizar a VLAN 28 do MK, que morre com ele).
- **NE8000 ↔ CCR1036**: VLAN ponto a ponto privada (VPN/serviços) + VLANs de **gerência privada**
  dos servidores locais (`vlan10`, `vlan66`, `vlan109`, `vlan116`, `vlan999`). **Nenhuma VLAN
  pública** passa por este link.
- **VLAN de gerência** padronizada (modelo da ACL `IPV4_NOC_NETPAL` — passo 3 do
  [05](05-limpeza-politicas.md)).

**Não migra (L2 morto):** VLAN13, 17, 21-outer, 51, 53, 92, 250, 742/770, 772 + `VLAN11_eoip` +
bridges `EOIP-NOC`/`loopNETPAL` (lista completa no [09](09-l2-mapeamento-vlans.md)).

## 3. Camada L3 (rascunho — detalhar na próxima etapa)

| Função | Equipamento | Detalhe |
|--------|-------------|---------|
| Dono do `177.72.104.0/27` + firewall de servidores | **NE8000** | `.1` (e as demais) na subinterface da VLAN 16; as ~24 sub-redes de gerência da antiga bridge vão como secundárias ou são redesenhadas. Hosts com IP público dedicado (Hubsoft, Fusion, VOIP etc.) seguem direto, sem NAT. Política nova enxuta por zonas, sem geo-allowlist ([05](05-limpeza-politicas.md)) |
| 🆕 NAT (SRC-NAT/DST-NAT) | **CCR1036** | ✅ Corrigido (usuário, 2026-07-23) — **não fica no NE8000**. SRC-NAT das redes privadas e DST-NAT (Dude `:18291`, TS SIX `:15389`) rodam na CCR1036. Mecanismo de roteamento do IP público até a CCR1036 ainda **a definir** — ver decisão #9 em [03](03-decisoes-pendentes.md) e [10](10-enderecamento-ccr1036.md) |
| Roteamento das VLANs de acesso (QinQ, enlaces /30 de POP, gerências de OLT/SW) + OSPF area1 | **DM4170** | SVIs QinQ; herda as adjacências OSPF dos POPs; redistribute connected/static (ou anúncios explícitos — oportunidade de limpeza); default via NE8000 |
| Adjacência OSPF principal | DM4170 ↔ NE8000 | Link direto 10GE novo, VLAN dedicada, area 0.0.0.1, MD5 (estratégia da chave: decisão #11) |
| Rotas estáticas `10.8.0.0/21`, `10.254.0.0/22`, `10.30.0.0/30`, `10.150.150.0/24` | NE8000 | **viram resolução connected** quando o `/27` subir (next-hops `.9`/`.12`/`.19` são hosts do /27) — revisar se ainda fazem sentido |
| VPN de equipe (L2TP+OpenVPN recriados) | **CCR1036** | Redesenho limpo: sem mschap1, criptografia obrigatória, certs novos ou CA exportada |
| Automações (backup FTP, netwatch→API) | **CCR1036** | RouterOS roda os scripts de hoje com ajuste mínimo — a confirmar |
| DHCP (`VLAN1066 - GERADOR MST`, 1 escopo) | DM4170 ou NE8000 | Trivial — decidir na config |
| FlowSpec/NetStream (`177.72.104.27`) | NE8000 | RR fica **diretamente conectado** — validar sessão BGP e fluxo `:3055` no corte |

## Equipamentos: saem e entram

| Equipamento | Papel hoje | Destino |
|---|---|---|
| RB3011 "GW Servidores" | Agregação L3 (~50 VLANs QinQ), NAT, firewall, VPNs | **sai** — funções divididas entre DM4170 (SVIs QinQ + OSPF), NE8000 (/27 + firewall) e CCR1036 (**NAT** + VPN/automações + cobre) |
| RB2011 "RB Bridge Servidores" | Switch L2 burro dos servidores | **sai** — a CCR1036 assume as portas de cobre para **gerência privada** dos servidores locais |
| Rede de acesso (agregação L2/QinQ) | Transporta todas as VLANs dos sites | **⛔ fora do escopo** — nenhuma alteração |
| Datacom DM4170 | — | **entra**: substitui o RB3011 (SVIs QinQ, OSPF). 24× GE SFP + 4× 10GE SFP+ + 2× 40GE QSFP+ (ou variante 12× 10GE — a confirmar), fontes redundantes, L2/L3/MPLS em wire-speed. [Datasheet](datacom-dm4170-datasheet.pdf) |
| **Mikrotik CCR1036** (variante a confirmar: 12G-4S ou 8G-2S+) | — | **entra**: **NAT** (🆕 corrigido 2026-07-23) + VPN de equipe + automações + **gerência privada** dos servidores em cobre. Deixa de ser "100% privada" — precisa de rota/IP público para o NAT funcionar (a definir, [10](10-enderecamento-ccr1036.md)) |
| NE8000 "BGP_NETPAL" | Core BGP/OSPF, CGNAT assinantes, terminação QinQ de POPs | **fica e ganha**: `/27` (IP público) + firewall de servidores. **NAT não fica aqui** (corrigido — vai para a CCR1036). O que já existe (QinQ `MK_POP_*`) **não se mexe** |

> 🚨 **Dimensionamento** (mantido da revisão anterior): a GW Servidores tem **101 endereços em
> ~52 interfaces (~45 VLANs)** atendendo POPs, OLTs, switches, rádios e clientes corporativos
> ([07](07-enderecamento-ip.md)). A estratégia de corte em janela única do
> [04](04-plano-migracao.md) lida com isso: toda a config chega pré-montada e testada.

## Ainda não definido

- **SVI roteada sobre tag interna QinQ no DmOS** (bloqueio nº 1 — decisão #4) + limite de IPs
  secundários por SVI + MTU/baby giants.
- Variantes: CCR1036 (12G-4S vs 8G-2S+) e DM4170 (12×10GE vs 4×10GE+2×40GE).
- Redundância/HA (decisão #3 — não discutido; o desenho alvo mantém pontos únicos: 1 NE8000,
  1 DM4170, 1 CCR1036).
- Confirmação do papel da CCR1036 nas automações (decisão #6).
