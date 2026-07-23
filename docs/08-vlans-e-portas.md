# Topologia L2 — VLANs, QinQ e portas da GW Servidores

> Fonte: coleta manual 2 —
> [`gw-servidores-vlans-portas-ppp-ovpn-ospf.txt`](../config/rb3011/gw-servidores-vlans-portas-ppp-ovpn-ospf.txt).
> Este documento fecha a maior parte das lacunas apontadas em
> [07-enderecamento-ip.md](07-enderecamento-ip.md).

## Achado central: é um router-on-a-stick numa única porta de 1 GE

Apesar das ~60 interfaces VLAN, **fisicamente quase tudo entra e sai por uma única porta**: a
`sfp1 - UPLINK SW TOPO DO RACK` (1 GE óptico). O RB3011 não é o ponto de fan-out da rede — o
**switch de topo de rack** é. O Mikrotik só pendura dezenas de VLANs (simples e QinQ) nesse único
trunk e roteia entre elas.

**Implicações diretas:**

1. **O corte físico é muito mais simples do que a escala sugeria**: o Datacom precisa de **um
   trunk** para o mesmo switch de topo de rack (idealmente já em 10 GE) + meia dúzia de portas de
   acesso para os servidores hoje ligados direto no MK (`ether6`–`ether10`).
2. **Todo o tráfego agregado da rede de acesso hoje divide 1 Gbps** nessa SFP. A troca pelo DM4170
   elimina esse gargalo — argumento concreto de performance para o projeto.
3. **O switch de topo de rack virou a peça mais importante ainda não inventariada.** Tudo passa por
   ele e ele não aparece em nenhum export até agora. Identificar: modelo, se é Mikrotik (sai
   também?), e se o DM4170 deveria **substituí-lo** em vez de (ou além de) substituir o RB3011 —
   os 24×SFP + uplinks 10 GE do DM4170 fazem exatamente o papel dele.

## Portas físicas — metade do equipamento está queimada

| Porta | Estado | Uso |
|---|---|---|
| `ether1`–`ether5` | 💀 **"ESTRAGADA"** (comentário do próprio operador) | `ether1` ainda tem IP configurado ("REGUA VOLT") — config morta |
| `ether6` | OK (slave) | PC TS SIX |
| `ether7` | OK (slave) | Proxmox – DOCKER – CDNTV |
| `ether8` | OK (slave) | Servidor DNS recursivo (com `VLAN10` taggeada por cima) |
| `ether9` | OK (roteada) | Gerência OLT ZTE |
| `ether10` | OK (slave) | Callcenter / Proxmox Zabbix |
| `sfp1` | OK | **Uplink único** para o SW topo do rack |

**5 das 10 portas ethernet estão fisicamente danificadas.** O equipamento que segura a agregação
L3 da rede inteira está com metade das portas queimadas e sem redundância — isso muda o tom do
projeto de "melhoria planejada" para **substituição urgente de hardware em degradação**.

⚠️ Config inconsistente encontrada de brinde: `ether6` e `ether7` são *slaves* de bridge mas têm IP
atribuído direto na porta (o DHCP `dhcp2` já falha por isso — "can not run on slave interface").
Os IPs de gerência dos mesmos servidores que funcionam de verdade estão na `Bridge IP Publico`.

## Estrutura QinQ: VLAN de "site" por fora, serviço por dentro

O desenho é hierárquico — **tag externa = localidade/POP, tag interna = serviço**:

```
sfp1 (1 GE, trunk)
├── VLAN13 DUDE · VLAN15 NTP · VLAN17 MONSTA · VLAN18 SERVERINO · VLAN1066 GERADOR MST
├── VLAN16 IP PUBLICO ──────────── (slave → braço da "Bridge IP Publico" no SW topo do rack)
├── VLAN22 PWW ─────┬─ .27 SW FO Shopping   ─ .52 Clientes IP Público PWW
│                   ├─ .90 Consepro          ─ .92 Bridge CC PWW
├── VLAN25 CPV ─────┬─ .30 Rádios CPV        ─ .51 Clientes IP Público CPV
│                   ├─ .93 POP JDF/Rancho Velho ─ .196 BB CPV ─ .200 Prédio Maicon
├── VLAN26 FSB ─────── .35 Gerência OLT FSB
├── VLAN31 GGV ─────── .21 OLT ZTE GGV
├── VLAN33 BCP ─────┬─ .708 Serraria ─ .712 Casca ─ .738 Solidão 101
│                   ├─ .753 Bacupari ─ .765 Serraria=>BCP ─ .775 Aguapé
├── VLAN35 FSB ─────┬─ .721 Faz. Cardoso ─ .731 Cavalhada
├── VLAN37 OLT BCP ─── .53 Galeria Krupp
├── VLAN39 LBCP ────── .539 Gerência OLT LBCP
├── VLAN43 MST ─────┬─ .49 Clientes IP Público MST ─ .54 Marcos Solon ─ .250 Ger. OLT MST
│                   ├─ .718 Valim ─ .719 Pantano ─ .720 Povos ─ .742/.770 TAN
│                   ├─ .772 Tio Joca ─ .2020 EDD TIM MST
├── VLAN44 SLD ─────── .713 GW SOLIDÃO
├── VLAN46 TVR ─────┬─ .600 AP Centro TVR ─ .50 Gerência TVR ─ .198 Pantano=>Juca Ana (IP público!)
├── VLAN40 PSLD · VLAN41 CCB · VLAN42 CASCA · VLAN47 PRAIA MST · VLAN48 P. SÃO SIMÃO
└── (demais VLANs simples de gerência)
```

**No fio da `sfp1` trafegam frames com dupla tag 802.1Q** (ex.: POP Bacupari = outer 33 + inner
753). Os l2mtu confirmam: sfp1=1600 → outer=1596 → inner=1592.

### ⚠️ Risco técnico novo — confirmar com a Datacom ANTES do desenho final

O DM4170 suporta QinQ (datasheet), mas o que o MK faz aqui é mais específico:
**interface L3 roteada (com IP e OSPF) em cima da tag interna de um QinQ**. Confirmar se o DmOS
suporta SVI/subinterface roteada com dupla tag. Se não suportar, há duas saídas:
- o switch de topo de rack passa a "desempacotar" a tag externa e entregar tags simples ao Datacom; ou
- o DM4170 assume o papel do switch de topo de rack e recebe os links dos sites diretamente.

### Armadilhas de numeração (cuidado ao migrar)

- **VLAN-ID 21 existe duas vezes** em níveis diferentes: outer (`VLAN21 - GERENCIA - GGV` na sfp1)
  e inner (`VLAN21 - OLT ZTE GGV` dentro da VLAN31).
- **VLAN-ID 35 idem**: outer (`VLAN35 - FSB`) e inner (`VLAN 35 GERENCIA OLT FSB` dentro da VLAN26).
- **Dois transportes para FSB** (`VLAN26` e `VLAN35`, ambas nomeadas FSB).
- **`VLAN742` e `VLAN770` têm o mesmo nome** ("MK POP TAN") — uma provavelmente substituiu a outra.

### VLANs sem função L3 (candidatas a NÃO migrar)

Interfaces VLAN ativas mas **sem IP, sem bridge** — config morta a expurgar no redesenho:

`VLAN13 - DUDE`, `VLAN17 - MONSTA`, `VLAN21 - GERENCIA - GGV`, `VLAN51 - Cliente IP Publico CPV`,
`VLAN53 - Galeria Krupp`, `VLAN92 - Bridge CC PWW`, `VLAN250 - Gerencia OLT MST`,
`VLAN742`/`VLAN770` (TAN, uma das duas), `VLAN772 - Tio Joca`

Também sem IP: bridge `loopNETPAL` (vestigial?) e a citada IP morta na `ether1`.

## Composição da `Bridge IP Publico` — ✅ fechada

`/interface bridge port print` confirmou os membros:

| Membro | HW offload | Papel |
|---|---|---|
| `VLAN16 - IP PUBLICO` (tag 16 na sfp1) | **não** | Extensão do domínio L2 público até o SW topo do rack |
| `ether6` (PC TS SIX), `ether7` (Proxmox DOCKER/CDNTV), `ether8` (DNS recursivo), `ether10` (Callcenter/Zabbix) | sim | Servidores locais |
| `ether1`, `ether2`, `ether4` | — | Queimadas, inativas na bridge |

O que isso fecha:

- **O domínio L2 "público" = VLAN 16.** Todos os servidores com IP do `/27` que não estão nas
  portas locais (Hubsoft, Fusion, DNS, RB2011 etc.) estão **atrás do SW topo do rack, na VLAN 16**.
  As ~25 sub-redes da bridge (o `/27` + gerências `/30`) são um único segmento L2 nessa VLAN.
- **Tradução direta para o Datacom**: VLAN 16 taggeada no trunk + portas de acesso untagged
  (VLAN 16) para os 4 servidores locais + **uma SVI** com `177.72.104.1/27` e as ~24 sub-redes
  secundárias. A "Bridge IP Publico" deixa de existir como conceito — vira uma VLAN normal.
- **Mais um ganho de performance**: o membro `VLAN16` não tem hw-offload, então hoje todo frame
  bridgeado entre os servidores locais e o resto do segmento público passa pela **CPU** do RB3011.
  No DM4170 isso é switching em hardware.
- As bridges `EOIP-NOC` e `loopNETPAL` **não têm nenhuma porta** — vestigiais, não migrar.

## Túnel EoIP com o NOC — e a reclassificação do `177.93.244.165`

```
eoip-tunnel1: local-address=177.72.104.1  remote-address=177.93.244.165  tunnel-id=1212
└── VLAN11_eoip → "GERENCIA SW DATACOM" (192.168.15.49/30)
```

- **`177.93.244.165` é o endpoint do NOC/site remoto**, não um atacante: além de fechar o EoIP, ele
  está na ACL de gerência do NE8000 (`IPV4_NOC_NETPAL rule 10`) e na lista `SIXTELECOM`. As
  "tentativas de login falhas" registradas no RB2011 eram quase certamente acesso legítimo com
  senha errada. *(Corrige o achado de segurança do [01-inventario-atual.md](01-inventario-atual.md).)*
- A gerência do **Datacom já existente na rede** chega por dentro desse túnel (VLAN 11).
- ⚠️ **O túnel está FORA agora** (`eoip-tunnel1` e `VLAN11_eoip` sem flag R). Ou o remoto está
  down, ou é config abandonada. Confirmar antes de planejar a gerência do novo DM4170.
- Mais uma dependência do IP `177.72.104.1` (além de NAT, DST-NAT e next-hop do NE8000): é o
  endpoint local deste túnel.

## OSPF — o mistério das redes "fora do OSPF" está resolvido

```
router-id=172.16.200.5  distribute-default=never
redistribute-connected=as-type-1   redistribute-static=as-type-1
```

- **`redistribute-connected=as-type-1`**: TODAS as ~100 sub-redes conectadas são injetadas na
  OSPF como rotas externas E1 — por isso POPs e gerências alcançam tudo sem constar em
  `/routing ospf network`. A lista de `network` só controla em quais interfaces o OSPF fala hello.
- **`redistribute-static` também ativo** — as rotas estáticas (10.8.0.0/21 etc.) são propagadas.
- O Datacom precisará do equivalente (redistribute connected/static em OSPF) **ou** de um desenho
  mais explícito — oportunidade de limpeza, já que E1 "atacado" propaga inclusive lixo.
- `distribute-default=never` + rota estática default via `192.168.116.33` (NE8000): o MK não
  origina default na área; o default da rede vem de outro lugar.

## Pendências que restam deste levantamento

- [x] ~~`/interface bridge port print`~~ — ✅ coletado, ver seção "Composição da Bridge IP Publico".
- [ ] Identificar o **switch de topo de rack** (modelo/função — possivelmente mais um Mikrotik).
- [ ] Confirmar com a Datacom: **SVI roteada sobre QinQ interno** e limite de IPs secundários por SVI.
- [ ] Possível sobreposição no `177.72.104.60/30`: o MK tem `.61/30` na VLAN198 (QinQ p/ Juca Ana)
      e o NE8000 também anuncia `network 177.72.104.60 0.0.0.3` na OSPF — entender quem é quem
      nesse /30 antes do corte.
- [ ] Estado real do EoIP do NOC (down agora — abandonado ou incidente?).
