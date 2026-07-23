# L2 — Mapeamento VLAN a VLAN (RB3011 → desenho alvo)

> Fonte: coleta 2 ([`config/rb3011/gw-servidores-vlans-portas-ppp-ovpn-ospf.txt`](../config/rb3011/gw-servidores-vlans-portas-ppp-ovpn-ospf.txt),
> 60 interfaces VLAN) + análise de IPs do [07](07-enderecamento-ip.md). Desenho alvo:
> [02-arquitetura-alvo.md](02-arquitetura-alvo.md) — **o DM4170 entra no lugar do RB3011**
> (herda o trunk QinQ da rede de acesso); a rede de acesso **não é tocada**.

## Legenda de destinos

| Destino | Significado |
|---|---|
| **DM4170 (SVI QinQ)** | Sobe QinQ pelo trunk rede de acesso ↔ DM4170; DM4170 termina SVI roteada na tag interna — ⚠️ depende da confirmação DmOS (decisão #4) |
| **DM4170 (SVI)** | VLAN simples taggeada no trunk; DM4170 termina L3 |
| **NE8000 (L2)** | VLAN 16: atravessa o DM4170 em L2 e termina no NE8000 (decisão #9B) |
| **CCR1036** | Porta local na CCR1036 (servidor em cobre) + tag no link CCR1036↔NE8000 |
| **Transporte** | Tag existe só em L2 na rede de acesso/trunk — nenhuma SVI a criar |
| **✝ Não migra** | Morta (sem IP/sem bridge) ou tecnologia que morre com o MK |

## 1. VLANs de serviço / servidores (5)

| VLAN | Nome | Hoje | Destino L2 | L3 | Obs |
|---|---|---|---|---|---|
| 16 | IP PUBLICO | sfp1 → slave da `Bridge IP Publico` | tag 16: rede de acesso → DM4170 → **sobe em L2 ao NE8000** | **NE8000** `.1/27` (decisão #9B) | A bridge morre; vira VLAN comum de trânsito. Servidores locais que precisarem de IP público usam **segunda NIC** na VLAN 16 (rede de acesso), não passam pela CCR1036 |
| 15 | NTP SERVER | sfp1 (simples) | tag 15 no trunk rede de acesso ↔ DM4170 | **DM4170** (SVI) | |
| 18 | SERVERINO | sfp1 (simples) | tag 18 no trunk rede de acesso ↔ DM4170 | **DM4170** (SVI) | |
| 1066 | GERADOR MST | sfp1 (simples) | tag 1066 no trunk rede de acesso ↔ DM4170 | **DM4170** (SVI) | Único DHCP vivo (`192.168.90.0/24`) — escopo migra junto (decidir onde: DM4170 ou NE8000) |
| 10 | SERVIDOR DNS RECURSIVO | taggeada sobre `ether8` | porta tagged na **CCR1036** + tag 10 no link CCR1036↔NE8000 | NE8000 | Gerência privada do servidor local |

> ⚠️ **Ponto em aberto (VLAN 16):** hoje o domínio L2 "IP Público" = VLAN16 vinda da rede de
> acesso + 4 servidores locais no RB3011. No alvo, o braço da rede de acesso atravessa o DM4170
> em L2 até o NE8000, e os servidores locais que precisarem de IP público usam uma **segunda NIC**
> ligada diretamente à VLAN 16 na rede de acesso — **fora da CCR1036**.

## 2. VLANs de acesso — QinQ, migram para SVIs no DM4170 (27)

Tag externa = site (transporte na rede de acesso), tag interna = serviço. **O DM4170 herda o
papel do RB3011: SVI roteada sobre a tag interna.** Ordenadas por site:

| Site (outer) | Inner | Nome | Obs |
|---|---|---|---|
| 22 PWW | 27 | SW FO Shopping | |
| 22 PWW | 52 | Clientes IP Público PWW | IPs públicos de clientes passam a rotear no DM4170 |
| 22 PWW | 90 | RB Bridge Consepro PWW | |
| 25 CPV | 30 | Gerência Rádios CPV | |
| 25 CPV | 93 | GERENCIA POP JDF e enlace Rancho Velho | |
| 25 CPV | 196 | RB Banco do Brasil CPV | cliente corporativo |
| 25 CPV | 200 | RB Bridge Prédio Maicon | cliente CEEE |
| 26 FSB | 35 | Gerência OLT FSB | ⚠️ inner 35 = mesmo ID do outer 35 |
| 31 GGV | 21 | OLT ZTE GGV | ⚠️ inner 21 = mesmo ID do outer 21 (morta) |
| 33 BCP | 708 | MK POP Serraria | |
| 33 BCP | 712 | MK POP Casca | |
| 33 BCP | 738 | MK POP Solidão 101 | |
| 33 BCP | 753 | MK POP Bacupari | |
| 33 BCP | 765 | Serraria => BCP | |
| 33 BCP | 775 | MK POP Aguapé | |
| 35 FSB | 721 | MK POP Faz. Cardoso | |
| 35 FSB | 731 | MK POP Cavalhada | |
| 39 LBCP | 539 | Gerência OLT LBCP | |
| 43 MST | 49 | Clientes IP Público MST | idem nota de clientes |
| 43 MST | 54 | Marcos Solon | |
| 43 MST | 718 | MK POP Valim | |
| 43 MST | 719 | MK POP Pantano | NE8000 tem `.719 MK_POP_PANTANO` (link separado, **não mexer**) — conferir se é o mesmo enlace |
| 43 MST | 720 | MK POP Povos | |
| 43 MST | 2020 | Gerência EDD MST (TIM) | cliente corporativo |
| 44 SLD | 713 | GW SOLIDÃO | NE8000 tem `.713 MK_POP_SOLIDAO` (link separado, **não mexer**) — conferir se é o mesmo enlace |
| 46 TVR | 50 | Gerência TVR | |
| 46 TVR | 198 | Pantano => Juca Ana (IP público `.61/30`) | ⚠️ **decisão #10** — NE8000 também anuncia `177.72.104.60/30` (na `.778 MK_POP_JUCA_ANA`?); resolver antes do corte |
| 46 TVR | 600 | AP Centro TVR Rei dos Pampas | |

> Quais dessas VLANs formam adjacência OSPF hoje → cruzar com `/routing ospf network` do export
> ([07](07-enderecamento-ip.md)). No DM4170, as SVIs com adjacência precisam de OSPF ativo
> (p2p + MD5, mesma chave — decisão #11); as demais ficam passivas (só redistribute connected).

## 3. VLANs outer de site — só transporte (16)

Existem para carregar as tags internas. **Nenhuma SVI a criar** — vivem na rede de acesso e no
trunk rede de acesso ↔ DM4170 como tag externa:

`22 PWW` · `25 CPV` · `26 FSB` · `31 GGV` · `33 BCP` · `35 FSB` · `37 OLT BCP` · `39 LBCP` ·
`40 PSLD` · `41 CCB` · `42 CASCA` · `43 MST` · `44 SLD` · `46 TVR` · `47 PRAIA MST` ·
`48 PRAIA SÃO SIMÃO`

> ⚠️ Hoje essas VLANs outer também existem na `sfp1` do MK só para serem "pai" das internas. No
> alvo, a rede de acesso entrega o QinQ intacto ao DM4170 (double-tag + MTU baby giant — decisão
> #4). ~~Plano B: a rede de acesso desempacota a tag externa~~ — **inválido**: ela está fora do
> escopo (não será mexida). A confirmação de SVI sobre tag interna no DmOS é praticamente
> obrigatória.

## 4. Não migra (11)

| VLAN | Nome | Motivo |
|---|---|---|
| 11 | VLAN11_eoip (GERENCIA SW DATACOM) | EoIP é proprietário MK e o túnel já está down — gerência do Datacom antigo ganha caminho novo (pendente) |
| 13 | DUDE | Sem IP/sem bridge |
| 17 | MONSTA | Sem IP/sem bridge |
| 21 (outer) | GERENCIA - GGV | Sem IP/sem bridge |
| 51 | Cliente IP Público CPV | Sem IP/sem bridge |
| 53 | Galeria Krupp | Sem IP/sem bridge |
| 92 | Bridge CC PWW | Sem IP/sem bridge |
| 250 | Gerência OLT MST | Sem IP/sem bridge |
| 742 **ou** 770 | MK POP TAN (×2, mesmo nome) | Uma substituiu a outra — descobrir qual está viva antes de descartar |
| 772 | MK POP Tio Joca | Sem IP/sem bridge |

Morrem junto (não são VLAN, mas constam): bridges `EOIP-NOC` e `loopNETPAL` (sem portas), IP morto
da `ether1` ("REGUA VOLT"), e a **VLAN 28** (link MK↔NE8000, que deixa de existir com o MK).

## 5. VLANs novas a criar no desenho alvo

| VLAN | Uso | IDs |
|---|---|---|
| Núcleo DM4170 ↔ NE8000 | Adjacência OSPF principal + trânsito inter-VLAN → NE8000 | **a definir** (não reutilizar 28) |
| Serviços CCR1036 ↔ NE8000 | Ponto a ponto da VPN/serviços da CCR1036 | **a definir** |
| Gerência | VLAN única de management (modelo `IPV4_NOC_NETPAL` — passo 3 do [05](05-limpeza-politicas.md)) | **a definir** |

## 6. Armadilhas e pendências L2

- **IDs duplicados em níveis diferentes**: `21` (outer GGV morta × inner OLT ZTE GGV), `35`
  (outer FSB × inner Gerência OLT FSB). No DM4170, a tupla (outer, inner) é única — sem conflito
  real, mas cuidado na documentação.
- **TAN duplicada**: `742` e `770` com o mesmo nome — identificar a viva (ping/gerência no site).
- **Decisão #10** (`177.72.104.60/30` na VLAN198 × anúncio OSPF do NE8000) — bloqueia a migração
  da VLAN198. Investigar de onde o NE8000 anuncia esse /30 (candidata: `.778 MK_POP_JUCA_ANA`).
- **Links homônimos no NE8000** (`.713`, `.719`, `.778`): são enlaces separados que **não serão
  tocados** — mas confirmar se algum é o mesmo segmento físico da VLAN correspondente do MK, para
  não criar dois caminhos L3 para o mesmo lugar.
- **MTU**: baby giants (≥1600) no trunk rede de acesso ↔ DM4170 e no caminho QinQ; MSS-clamp
  equivalente no NE8000 (hoje é mangle no MK).
- **Gerência do Datacom antigo** (hoje `192.168.15.49/30` via EoIP): precisa de VLAN/caminho novo
  — provavelmente pendurar na VLAN de gerência nova.

**Resumo numérico:** 60 VLANs hoje → **27 migram** para SVIs QinQ no DM4170 · **5** de
serviço/servidores · **16** viram só transporte · **11** não migram · **+3 novas** a criar.
