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

### ~~⚠️ Risco técnico novo — confirmar com a Datacom ANTES do desenho final~~ ✅ resolvido (decisão #13)

O DM4170 suporta QinQ (datasheet), mas o que o MK faz aqui é mais específico:
**interface L3 roteada (com IP e OSPF) em cima da tag interna de um QinQ**. Seria preciso
confirmar se o DmOS suporta SVI/subinterface roteada com dupla tag — mas ✅ **essa confirmação
deixou de ser necessária (usuário, 2026-07-24, decisão #13 em
[03-decisoes-pendentes.md](03-decisoes-pendentes.md)): o DM4170 fica só em L2**, fazendo apenas
QinQ termination (feature padrão, sem incerteza de suporte); quem termina a SVI roteada de cada
VLAN passa a ser o **NE8000**, que já faz exatamente isso hoje para as VLANs de POP em paralelo.

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

## Composição da `Bridge IP Publico` — ✅ fechada, e revista com dados reais de tráfego

`/interface bridge port print` confirmou os membros:

| Membro | HW offload | Papel |
|---|---|---|
| `VLAN16 - IP PUBLICO` (tag 16 na sfp1) | **não** | Extensão do domínio L2 público até o SW topo do rack |
| `ether6` (PC TS SIX), `ether7` (Proxmox DOCKER/CDNTV), `ether8` (DNS recursivo), `ether10` (Callcenter/Zabbix) | sim | Servidores locais |
| `ether1`, `ether2`, `ether4` | — | Queimadas, inativas na bridge |

> 🆕 **Confirmado por `/interface bridge host print detail` (2026-07-24, dados brutos em
> [`config/rb3011/gw-servidores-bridge-host-arp.txt`](../config/rb3011/gw-servidores-bridge-host-arp.txt)):
> **nenhum host aprendido vem da `VLAN16`** — todas as ~40 entradas dinâmicas (`D E`) estão em
> `ether6`, `ether7`, `ether8` ou `ether10`. As únicas entradas em `VLAN16` são locais (`DL`, MAC do
> próprio roteador). **Isso derruba a hipótese anterior** de que boa parte das ~24 sub-redes
> secundárias chegava via switch de topo do rack pela VLAN16 — não chega. **100% do tráfego da
> bridge hoje é local a esses 4 servidores.**
>
> Cruzando os MACs com os 4 clusters Proxmox mapeados ([12](12-mapeamento-proxmox.md)):
> `ether7` = cluster Docker/CDNTV (5/5 VMs batem), `ether8` = cluster DNS (4/4 batem), `ether6` =
> TS SIX (servidor à parte). **`ether10` é compartilhado entre o cluster Zabbix (11/11) e o
> cluster HubSoft (2/2)** — devem estar atrás do mesmo pequeno switch, não em cabos dedicados
> separados. Isso explica por que o HubSoft nunca apareceu com porta própria no plano da CCR1036
> ([10](10-enderecamento-ccr1036.md), decisão #12 em [03](03-decisoes-pendentes.md)).

O que isso fecha:

- **O domínio L2 "público" = VLAN 16 + os 4 servidores locais**, mas **hoje só os 4 servidores
  geram tráfego real** nesse domínio — a VLAN16 está "vazia" de hosts aprendidos, apesar de existir
  como membro da bridge.
- 🆕 **Simplifica o desenho da SVI do NE8000 (decisão #9):** as ~24 sub-redes secundárias da antiga
  `Bridge IP Publico` **não precisam subir em L2 pelo DM4170** — são 100% tráfego dos 4 servidores
  locais, ou seja, ficam inteiramente do lado da CCR1036 (ou o que substituir `ether6`/`7`/`8`/`10`).
  A VLAN16/DM4170/NE8000 só precisa mesmo do `/27` público em si, não de todo o multinetting
  privado que se temia antes.
- **Tradução direta para o Datacom**: VLAN 16 taggeada no trunk (pro `/27` público) + as sub-redes
  privadas dos 4 servidores vão para a CCR1036, não para uma SVI secundária no NE8000. A "Bridge IP
  Publico" deixa de existir como conceito.
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
- [x] ~~Confirmar com a Datacom: SVI roteada sobre QinQ interno e limite de IPs secundários por
      SVI~~ → ✅ **caiu (decisão #13, 2026-07-24):** DM4170 fica só L2, quem termina a SVI é o
      NE8000.
- [x] ~~Possível sobreposição no `177.72.104.60/30`~~ → 🆕 **investigado (2026-07-24):** o NE8000
      **não tem nenhuma interface configurada** nesse /30 — o `network 177.72.104.60 0.0.0.3` na
      OSPF é uma statement inerte (não ativa hello em nenhuma interface local, já que nenhuma bate
      com o range). O dono real e único hoje é o MK (`.61/30` na `VLAN198 - Pantano => Juca Ana`).
      **Achado à parte, digno de nota:** o NE8000 tem `FTP client-source -a 177.72.104.61` e
      `sftp client-source -a 177.72.104.61` configurados globalmente — ou seja, o NE8000 tenta
      originar suas próprias sessões de FTP/SFTP client com um IP que **não é dele** (é do MK).
      Não é o conflito de rota temido, mas ou é config órfã/quebrada, ou sinaliza que o NE8000 já
      foi preparado para um dia assumir esse /30 diretamente. → 🆕 **Confirmado pela decisão do
      usuário (2026-07-24): o `177.72.104.60/30` sai do RB3011 e passa a ser interface do NE8000**
      (o `.61`), o que torna o `FTP/sftp client-source -a .61` consistente (aponta pro próprio IP).
      A hipótese "NE8000 já foi preparado pra assumir" estava certa. A VLAN198 não é "replicada"
      no caminho — o `/30` público nasce direto no NE8000 (decisão #10/#13).
- [x] ~~Estado real do EoIP do NOC~~ → segue **fora do ar**, mas o próprio NE8000 já libera
      `177.93.244.165` diretamente na ACL `IPV4_NOC_NETPAL` (linha acima) — ou seja, o NOC já tem
      um caminho de gerência que **não depende do túnel nem do RB3011**. Reforça que o túnel é
      dispensável; falta só confirmar com o usuário se algum serviço específico ainda usa o túnel
      em si (não só o acesso do NOC).
