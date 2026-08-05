# Cruzamento com o Dude (`Devices.csv`)

> Fonte: [`Devices.csv`](Devices.csv) — export do servidor The Dude (`RB DUDE`, `192.168.116.30`,
> hoje pendurado na GW Servidores, DST-NAT `.1:18291`). 714 linhas, monitoramento ativo
> (`Flag`: up/down/acknowledged/unknown). Cruzado contra os achados de
> [07-enderecamento-ip.md](07-enderecamento-ip.md) e [08-vlans-e-portas.md](08-vlans-e-portas.md).

## 🎯 Achado principal: forte candidato ao switch de topo do rack

Bloqueio em aberto desde [08](08-vlans-e-portas.md) e repetido em [01](01-inventario-atual.md),
[02](02-arquitetura-alvo.md), [03](03-decisoes-pendentes.md) (#4) e [04](04-plano-migracao.md).

O Dude tem uma família de switches **Huawei S6730**, um por site, todos com a mesma nota
padronizada (macros de CLI Huawei para ativar/desativar backup PTP-fibra/rádio):

| Device (Dude) | IP | Site (Maps) |
|---|---|---|
| **S6730 Jardim Formoso** | `192.168.15.6` | **DC Capivari do Sul** |
| S5720 CDN JDF | `192.168.15.26` | DC Capivari do Sul |
| S6730 GGV | `192.168.115.134` | DC Granja Vargas |
| S6730 Bacupari | `192.168.15.122` | DC Bacupari |
| S6730 Mostardas | `192.168.15.78` | DC Mostardas / Praia Mostardas / Praia São Simão |
| S6730 PWW | `192.168.115.2` | DC Palmares do Sul |

O **S6730 Jardim Formoso** está no mesmo grupo/site (`DC Capivari do Sul`) que `GW Servidores`
(`192.168.116.34`), `RB DUDE` (`192.168.116.30`), `TS SIX` (`192.168.66.14`),
`RB Bridge Servidores` (`192.168.116.22`) e `BGP - Jardim Formoso` (`177.72.104.54` — o **NE8000**,
confirmado abaixo). É o candidato mais forte a ser **o switch de topo de rack**.

⚠️ **Não é confirmação física.** O IP de gerência `192.168.15.6` não aparece como nenhum dos `/30`
diretamente conectados na `/ip address` do RB3011 ([07](07-enderecamento-ip.md)) — ou seja, não dá
para provar o link só pelos dados coletados; o caminho de gerência até esse switch não é direto pela
GW Servidores. **Ainda precisa de confirmação física** (rastrear o cabo da `sfp1`), mas agora há um
alvo concreto em vez de "equipamento desconhecido".

**Consequência relevante:** se confirmado, o switch de topo do rack **não é Mikrotik — é um Huawei
S6730** (mesmo fabricante do NE8000). Isso muda a suposição implícita nos docs anteriores de que
seria "mais um Mikrotik". Um S6730 é um switch enterprise com suporte robusto a QinQ — bom sinal
para a viabilidade técnica do lado da rede de acesso (o RB3011 é que fazia a parte não-trivial,
roteando sobre a tag interna).

**Achado operacional lateral:** as notas do Dude mostram que cada site tem **fibra e rádio como
enlaces primário/backup com chaveamento manual** (macros "ATIVA/DESATIVA PTP FO" e "ATIVA/DESATIVA
BACKUP DE RÁDIO", digitadas via CLI Huawei). Não há failover automático. Relevante para a decisão #3
(redundância) — o padrão operacional da casa já é backup manual, não automático.

## ⚠️ Divergência de nomes: RB3011 (firewall) vs Dude (monitoramento ao vivo)

Cruzando os IPs do bloco público que o [07](07-enderecamento-ip.md) já tinha nomeado (via comentário
de regra de firewall no RB3011) contra o nome do mesmo IP no Dude, **vários não batem**:

| IP | Nome no firewall RB3011 (pode ser antigo) | Nome no Dude (monitoramento ativo) |
|---|---|---|
| `.7` | Servidor Fusion Voip | **DOCS Cloud** |
| `.9` | Servidor Fusion Voip Multistore | **Servidor VPN** |
| `.16` | Servidor sala | **HubSoft** |
| `.17` | MADE4IT | **Fusion - VoIP - PM MST** |
| `.20` | SBC VOIP | **SFTP - Netpal - OPA** |
| `.8` | Hubsoft (regras "LIBERA HUBSOFT PARA O BRASIL") | *(não existe no Dude)* |

**Leitura mais provável:** o Dude reflete o que está de pé **hoje**; os comentários do firewall do
RB3011 refletem a config de quando cada regra foi escrita, possivelmente anos atrás, e não foram
atualizados quando os serviços foram remanejados. `.8` não aparecer no Dude é o sinal mais forte —
sugere que o **Hubsoft real hoje é `.16`** e `.8` é resíduo de uma regra de firewall para um host que
não existe mais (ou mudou de IP). **Isso muda o Passo 1 do [05-limpeza-politicas.md](05-limpeza-politicas.md):
o Dude, não o comentário do firewall, deveria ser a fonte de verdade sobre "o que está vivo".**

✅ **Confirmado por consulta direta ao Docker (2026-07-24):** `.16` = HubSoft real, correto. Mas
`.8` **não é resíduo morto** — é o **Smokeping**, um sistema vivo que simplesmente nunca foi
adicionado ao Dude (por isso "não aparecer no Dude" não provava que estava morto, só que não era
monitorado). Lição: ausência no Dude ≠ sistema morto — só ausência de monitoramento. Ver
[07](07-enderecamento-ip.md) e [12](12-mapeamento-proxmox.md) para o levantamento completo.

Casos que batem ou são plausivelmente o mesmo serviço (nomes diferentes, mesma família):
`.13` TIP VOIP = Zeus-TIP-VoIP · `.14` Fusion elaborados ≈ Fusion-VoIP-PM CPV · `.18` Fusion geral ≈
Fusion-VoIP-0800 NETPAL · `.25` Fusion simples ≈ Fusion-VoIP-Painéis Simples · `.30` OPA Suite = Opa
ChatBot · `.58` DNS loopback = DNS MASTER.

## ✅ IPs "sem nome" do levantamento anterior — resolvidos

Do [07-enderecamento-ip.md](07-enderecamento-ip.md), pendência "identificar os serviços por trás dos
IPs accept sem nome":

| IP | Era | Agora (Dude) |
|---|---|---|
| `.6` | sem nome | **Zabbix** |
| `.22` | sem nome | **Fusion - VoIP - Elaborados - Full** |
| `.23` | sem nome | **Aplicações /etc/scripts** |
| `.24` | sem nome | **OLT CLOUD** (Web Server) |
| `.29` | sem nome | **AUTOMACOES** (Web Server) — ~~provável relação com a decisão #6 (netwatch→API)~~ descartado (2026-07-24): o script `dude` chama direto um SaaS externo (`api.focuschat.com.br`), sem host local envolvido |
| `.105.217` | sem nome | **GW CC BCP** / GW Escritório BCP |

~~Ainda sem nome mesmo depois do cruzamento (não aparecem no Dude): `.26`, `.57`, `.59`,
`.105.221`.~~ ✅ **`.26` resolvido (2026-07-24, consulta direta ao Docker): é API-ZAP** —
~~provável destino da notificação da decisão #6~~ descartado (2026-07-24): a notificação vai
direto pra internet, não pra `.26`; função real de API-ZAP segue desconhecida. Seguem sem identificação em qualquer fonte
(Dude, firewall antigo, consulta direta aos 4 clusters Proxmox **e** `/ip arp print` no RB3011,
que não retornou nenhuma entrada para os três): `.57`, ~~`.59`~~, `.105.221`. `.59` foi
✅ **resolvido em 2026-08-05:** loopback `/32` da VM `NS-UNBOUND`, roteado via `.28`, portanto
sem ARP próprio por desenho; não era residual. Para `.57` e `.105.221`, permanece o indício de
resíduo morto, mas não definitivo.

## 🚨 Duas VPNs adicionais, fora do RB3011 — impacto na decisão #5

```
177.72.104.12  →  "OpenVPN - 2"    (Proxmox, mapa "Proxmox Docker")
177.72.104.19  →  "VPN - WireGuard" (mapa "DC Capivari do Sul")
```

Isso **não são** o L2TP nem o OpenVPN embutidos no RouterOS da GW Servidores (aqueles rodam *no
próprio MK*, atrás de `.1`). São **hosts próprios**, com IP público dedicado, hospedados em Proxmox
— totalmente independentes do equipamento que está saindo.

**Por que importa:** a decisão #5 partiu do princípio de que só existiam duas VPNs (L2TP e OpenVPN,
ambas no RB3011, ambas indo para a CCR1036). Esse cruzamento mostra que pode haver uma **terceira e
quarta** solução de VPN na operação, que **não dependem do RB3011 para existir** — só precisam que o
roteamento/firewall desses hosts (`.12`, `.19`) continue funcionando depois do corte. Ou seja,
provavelmente **não migram para a CCR1036**; só precisam ser preservados no NAT/firewall novo do
NE8000 como qualquer outro servidor do `/27`.

**Ação:** confirmar com o usuário se `.12`/`.19` são serviços à parte (ex.: VPN para clientes
corporativos, não "VPN de equipe") — isso os tiraria do escopo da decisão #5 e os poria junto com os
demais servidores do Passo 1 do [05](05-limpeza-politicas.md).

## ✅ Confirmações cruzadas (reforçam achados anteriores)

| Nome no Dude | IP | Confirma |
|---|---|---|
| `GW Servidores` | `192.168.116.34` | O próprio RB3011, IP da `sfp1` — bate com [07](07-enderecamento-ip.md) |
| `RB Bridge Servidores` | `192.168.116.22` | O RB2011 — bate com o export dele |
| `RB DUDE` | `192.168.116.30` | O servidor The Dude, alvo do DST-NAT `.1:18291` |
| `TS SIX` | `192.168.66.14` | Alvo do DST-NAT `.1:15389` |
| `BGP - Jardim Formoso` | `177.72.104.54` | O **NE8000** (mesmo IP da subinterface `Gi0/1/8.28`, decisão #4/#8) |
| `CGNAT 1/2 - Jardim Formoso` | `177.72.104.66` / `.102` | Batem exatamente com os `ip route-static` de CGNAT do NE8000 ([06](06-ne8000-bgp-core.md)) |
| `BRAS - PPPoE - Jardim Formoso` | `10.200.255.240` | Identifica o alvo antes anônimo da regra `accept chain=forward dst-address=10.200.255.240` no RB3011 |

## ✅ Resolvido: "Callcenter" não está no Dude porque ainda não existe

O `Devices.csv` não tem nenhum device chamado "Callcenter" — só o mapa/categoria `Proxmox Zabbix`,
que agrupa vários hosts, não um host específico. A ausência tinha duas explicações possíveis (nome
divergente, como os outros casos deste documento, ou sistema inexistente); o usuário confirmou
(2026-07-23): **é sistema novo, a ser implantado** — por isso não aparece em nenhum inventário
atual. Não é um caso de nomenclatura desatualizada como os demais desta página. Ver
[10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md).

## Pendências que este cruzamento levanta

- [ ] Confirmar fisicamente se o S6730 Jardim Formoso (`192.168.15.6`) é de fato o switch de topo do
      rack ligado à `sfp1` da GW Servidores.
- [ ] Revisar o Passo 1 do [05-limpeza-politicas.md](05-limpeza-politicas.md) usando o Dude como
      fonte de verdade — em especial confirmar se `.8` (Hubsoft antigo) está mesmo morto.
- [ ] Confirmar se `.12` (OpenVPN-2) e `.19` (WireGuard) são "VPN de equipe" (decisão #5) ou
      serviços à parte que só precisam de firewall/NAT preservado.
- [ ] Identidade final de `.57`, `.105.221` (sem nome em nenhuma fonte). `.26` = API-ZAP e
  `.59` = loopback da VM NS-UNBOUND, ambos resolvidos por consulta direta aos Proxmox.
- [x] ~~Confirmar identidade de "Callcenter"~~ — ✅ sistema novo, a implantar (não existe hoje).
