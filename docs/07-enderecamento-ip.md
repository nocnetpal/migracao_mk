# Endereçamento IP — GW Servidores (RB3011)

> Levantamento de todos os IPs públicos e privados encontrados no export
> [`config/rb3011/gw-servidores-export.rsc`](../config/rb3011/gw-servidores-export.rsc), exceto a
> lista `BRASIL` (centenas de faixas de terceiros, já decidido descartar — ver
> [05-limpeza-politicas.md](05-limpeza-politicas.md)).

## IPs públicos (177.72.104.0/21, 177.93.240.0/21, 1.1.1.0/24)

### Bloco `177.72.104.0/27` — servidores/serviços com IP público dedicado

| IP | Serviço | Fonte |
|---|---|---|
| `.1` | IP público geral da GW Servidores — masquerade (SRC-NAT) e alvo dos DST-NAT (Dude `:18291`, TS SIX `:15389`) | NAT rules |
| `.5` | **Compartilhado**: Hubsoft (`dst-port=!148`) e CallSys (`dst-port=!45345`) — mesmo IP, portas diferentes | firewall filter |
| `.6` | Accept `dst-port=80,443` — ✅ **Zabbix** (Dude, [11](11-cruzamento-dude-devices.md)) | firewall filter |
| `.7` | Servidor Fusion Voip (`80,45345,443,3478`) — ⚠️ Dude mostra "DOCS Cloud", nome não bate, confirmar | firewall filter |
| `.8` | Hubsoft (billing/ERP) — ⚠️ **não aparece no Dude**, provável morto/substituído por `.16` | firewall filter, FORA_DO_NAT |
| `.9` | Servidor Fusion Voip Multistore; também gateway da rota `10.8.0.0/21` — ⚠️ Dude mostra "Servidor VPN", nome não bate, confirmar | firewall filter, /ip route |
| `.12` | Regra de **drop** restringindo `443,22` a quem não é RANGENETPAL; também gateway da rota `10.254.0.0/22` — ✅ **"OpenVPN - 2"** (Dude) — VPN à parte, não do RB3011, ver [11](11-cruzamento-dude-devices.md) | firewall filter, /ip route |
| `.13` | TIP VOIP — ✅ confirmado ("Zeus - TIP - VoIP" no Dude) | firewall filter |
| `.14` | Fusion Netpal — clientes elaborados — ✅ plausível ("Fusion - VoIP - PM CPV" no Dude) | firewall filter |
| `.16` | Servidor sala — ⚠️ Dude mostra **"HubSoft"**; hipótese: é o Hubsoft real hoje, não `.8` | firewall filter |
| `.17` | MADE4IT — ⚠️ Dude mostra "Fusion - VoIP - PM MST", nome não bate, confirmar | firewall filter |
| `.18` | Fusion Netpal (geral) — ✅ plausível ("Fusion - VoIP - 0800 NETPAL" no Dude) | firewall filter |
| `.19` | FORA_DO_NAT; gateway das rotas `10.30.0.0/30` e `10.150.150.0/24` — ✅ **"VPN - WireGuard"** (Dude) — VPN à parte, não do RB3011, ver [11](11-cruzamento-dude-devices.md) | FORA_DO_NAT, /ip route |
| `.20` | SBC VOIP — ⚠️ Dude mostra "SFTP - Netpal - OPA", nome não bate, confirmar | firewall filter |
| `.22` | Accept sem nome — ✅ **"Fusion - VoIP - Elaborados - Full"** (Dude) | firewall filter |
| `.23` | Accept sem nome — ✅ **"Aplicações /etc/scripts"** (Dude) | firewall filter |
| `.26`, `.57` | Accept sem nome — ainda **não identificado** (também ausente do Dude) | firewall filter |
| `.24` | Accept `443,80,45345,21` — ✅ **"OLT CLOUD"** (Dude, Web Server) | firewall filter |
| `.25` | Fusion Netpal — clientes simples — ✅ plausível ("Fusion - VoIP - Painéis Simples" no Dude) | firewall filter |
| `.27` | Accept sem nome — **mesmo IP usado pelo NE8000 como Route-Reflector interno** (`177.72.104.27`, AS 52828) e destino do NetStream export; ✅ confirmado no Dude como **"RRFlow"** — não é coincidência, é o mesmo host/função. Ver decisão #8/#9 em [03](03-decisoes-pendentes.md). | firewall filter, [06-ne8000-bgp-core.md](06-ne8000-bgp-core.md), [11](11-cruzamento-dude-devices.md) |
| `.28` | DNS NetPal; gateway das rotas `.56/30`, `.58/32`, `.59/32` | DNS_AUT, /ip route |
| `.29` | ✅ **"AUTOMACOES"** (Dude, Web Server) — possível relação com a decisão #6 | firewall filter |
| `.30` | OPA Suite (chat) — porta `45345` restrita à lista `REDE LIBERADA_OPA_SUITE` — ✅ confirmado ("Opa ChatBot" no Dude) | firewall filter |
| `.58`, `.59` | DNS NetPal — loopbacks — `.58` ✅ confirmado ("DNS MASTER" no Dude); `.59` ainda sem confirmação | DNS_AUT |
| `.52/30`, `.60/30` | Enlaces ponto-a-ponto anunciados na OSPF area1 | /routing ospf network |
| `.56/30` | Rota de DNS (regra desabilitada); único prefixo aceito pelo filtro de rota OSPF de saída | /ip route, /routing filter |
| `.105.217` | Accept sem nome — ✅ **"GW CC BCP" / "GW Escritório BCP"** (Dude) | firewall filter |
| `.105.221` | Accept sem nome — ainda **não identificado** (também ausente do Dude) | firewall filter |
| `.131` | Servidor de backup FTP — **mesmo servidor usado pelo NE8000** para backup de config — ✅ confirmado ("Storage BCP" no Dude) | RANGENETPAL, script `backup_ftp` |

> 🆕 **Cruzamento completo com o monitoramento ao vivo (Dude) em
> [11-cruzamento-dude-devices.md](11-cruzamento-dude-devices.md)**: resolve a maioria dos "sem
> nome" acima, mas também revela que vários nomes do firewall (⚠️) **não batem** com o que está
> rodando hoje — sinal de que o RB3011 tem regras desatualizadas. Usar o Dude como fonte de
> verdade no Passo 1 do [05-limpeza-politicas.md](05-limpeza-politicas.md).

### Blocos maiores

| Bloco | Uso |
|---|---|
| `177.72.104.0/21` | `IP_PUBLICO` — allowlist de gerência (SSH/API/Winbox/FTP) |
| `177.93.240.0/21` | `IP_PUBLICO` — idem, segundo bloco público da operação |
| `177.72.104.0/27` | `SIXTELECOM` (allowlist de parceiro) e `BELLUNO` (regra de firewall) — mesmo /27 dos servidores acima |
| `177.72.104.0/22` + `177.93.240.0/21` | `REDE LIBERADA_OPA_SUITE` |
| `177.93.242.0/24` | `CGNAT` — referenciado numa regra de drop ("DROPA CGNAT"), consistente com o CGNAT de assinantes visto no NE8000 |

### ⚠️ `1.1.1.0/24` usado como endereçamento interno

Aparece em três lugares: allowlist de SSH (`1.1.1.0/24`), allowlist de API, e como **gateway de rota
estática** (`add distance=1 dst-address=192.168.88.0/24 gateway=1.1.1.3`). Esse não é um bloco
RFC1918 — é IP público real (hoje o DNS `1.1.1.1` da Cloudflare/APNIC). Usar como numeração interna é
arriscado: se algum dia esse tráfego vazar para a internet real, ou se algum host da rede tentar
mesmo acessar `1.1.1.1` (DNS público), pode haver conflito de rota. **Recomendo tratar como decisão
explícita da migração**: renumerar esse trecho para RFC1918 de verdade, ou confirmar que já está
isolado o suficiente para não importar.

## IPs privados (RFC1918)

| Faixa | Uso |
|---|---|
| `192.168.115.0/24` | Vários `/30` (enlaces OSPF: `.12`, `.16`, `.36`, `.40`, `.60`, `.100`, `.104`, `.124`, `.136`, `.140`); hosts `.98` (NAT) e `.214` (`FORA_DO_NAT_RADIUS`) |
| `192.168.116.0/24` | `RANGENETPAL`; `/30`s de enlace (`.4`, `.8`, `.16`, `.20`, `.24`, `.28`, `.32` — este é o link direto com o NE8000 —, `.36`, `.120`, `.196`); hosts `.30` (servidor "The Dude") e `.33` (gateway padrão = NE8000) |
| `192.168.66.0/28` | `NAT` + `RANGENETPAL`; host `.14` = servidor "TS SIX" |
| `192.168.83.0/24`, `192.168.84.0/24` | `RANGENETPAL` |
| `192.168.90.0/24` | `NAT` + rede OSPF |
| `192.168.123.0/30` a `.24/30` | Enlaces OSPF (área1) |
| `192.168.15.0/24`, `/30`, `/16/30`, `/48/30`; hosts `.18`, `.35` | Mistura de redes OSPF e uma regra de accept específica (`.18`) |
| `192.168.17.36/30`, `.44/30` | Enlaces OSPF |
| `192.168.22.48/28` | `NAT` |
| `192.168.25.0/29` | `NAT` |
| `192.168.1.0/24` | Rede OSPF area1 |
| `10.7.0.0/24` | **Pool de VPN L2TP/PPP da equipe** — `bruno` (`.7`), `vpnbruno` (`.3`), `isaac` (`.4`), `leonardo` (`.200`), local-address `.1`. Também em `NAT`, `RANGENETPAL` e OSPF. |
| `10.8.0.0/21` | Rota estática via `.9` |
| `10.30.0.0/30`, `10.150.150.0/24` | Rota estática via `.19` |
| `10.254.0.0/22` | Rota estática via `.12` |
| `10.200.255.240`, `.248/30`, `.252/30` | Accept no firewall / redes OSPF |
| `10.66.64.0/21` | `PPPOE_BLOQUEADOS` |
| `172.16.200.5/32` | Rede OSPF (provável loopback de algum equipamento) |
| `172.18.255.160/27` | Rede OSPF |
| `172.31.254.28/30`, `.32/30`, `.200/30` | Redes/enlaces OSPF |

## Outras anomalias encontradas

- **`182.168.83.0/24` e `182.168.84.0/24`** na lista `FORA_DO_NAT` (linhas 745–746 do export) — quase
  certamente erro de digitação de `192.168.83.0/24` / `192.168.84.0/24` (que já existem como
  `RANGENETPAL`). `182.168.0.0/16` é um bloco público real de terceiros. Se portado 1:1 pro NE8000,
  a regra viraria um "bypass de NAT" para endereços públicos de outra empresa — **não portar sem
  confirmar antes**.
- **`.5` compartilhado por dois sistemas** (Hubsoft e CallSys, diferenciados só por porta) reforça que
  o NAT atual não é puramente 1:1 por servidor — há multiplexação por porta em pelo menos um IP.
  Relevante para o desenho de zonas do [05-limpeza-politicas.md](05-limpeza-politicas.md).
- ~~**`.27` coincide com o Route-Reflector do NE8000**~~ — ✅ **resolvido, e não era coincidência.**
  `177.72.104.27` é um host real dentro do `/27` que fica na `Bridge IP Publico` da GW Servidores, e
  é simultaneamente o **route-reflector de FlowSpec do NE8000** e o **coletor NetStream**. É uma
  dependência de core, detalhada na seção "O NE8000 depende da GW Servidores" acima.

## ⚠️ O export da GW Servidores está truncado (falta todo o início do arquivo)

Não é só a seção `/ip address` que falta — **o arquivo começa no meio de uma seção**. A linha 1 de
[`gw-servidores-export.rsc`](../config/rb3011/gw-servidores-export.rsc) é
`add address=69.61.14.80/29 list=BRASIL`, sem o cabeçalho `/ip firewall address-list` acima dela. A
primeira seção com header no arquivo é `/ip firewall filter` (linha 773).

O `/export` do RouterOS emite as seções numa ordem fixa, então dá para deduzir com precisão o que
foi cortado — **tudo que vem antes de `/ip firewall address-list`**:

| Seção ausente | Por que importa para a migração |
|---|---|
| `/interface vlan` | **VLAN-IDs e interface pai de cada enlace.** Resolveria diretamente a pendência de mapeamento físico da decisão #4 ([03-decisoes-pendentes.md](03-decisoes-pendentes.md)) |
| `/ip address` | IPs reais de cada interface (loopback, `Bridge IP Publico`, cada VLAN) |
| `/interface bridge` + `/interface bridge port` | Quais portas compõem a `Bridge IP Publico` |
| `/interface eoip` | Endpoints e tunnel-id do túnel `VLAN11_eoip` |
| `/interface ethernet` | Nomes/estado das portas físicas |
| `/ip pool` + `/ip dhcp-server` | **Fecharia a decisão #1**: saber se este MK roda DHCP server ou não |
| `/interface l2tp-server server` + `/ppp profile` | **Fecharia a decisão #5**: como a VPN está realmente configurada |
| `/routing ospf instance` + `/routing ospf area` | Router-id e definição da `area1` (hoje só vemos referências a ela) |
| `/ip dns` | Se o MK atua como resolver/cache DNS |

### O que a estrutura do arquivo também permite concluir (ausências reais, não truncamento)

O export tem uma segunda leva de seções **depois** do firewall. Nessa faixa preservada, algumas
seções esperadas simplesmente não aparecem — e aí a ausência é informação real:

- **`/ip ipsec peer` e `/ip ipsec identity`** apareceriam entre `/ip firewall service-port`
  (linha 864) e `/ip route` (linha 869). **Não estão lá.** Ou seja, este MK **não tem IPSec
  configurado**, apesar da regra de firewall chamada "LIBERA L2TP IPSEC" e de o
  [01-inventario-atual.md](01-inventario-atual.md) descrever a VPN como "L2TP/IPSec". Ver análise
  abaixo.
- `/ip proxy`, `/ip smb`, `/ip traffic-flow`, `/ip upnp` também estão na faixa preservada e ausentes
  → o MK realmente não usa nenhum deles (não exporta NetFlow, por exemplo).

**Status:** ✅ **parcialmente resolvido.** Coleta manual em
[`gw-servidores-ip-address-pool-dhcp-l2tp.txt`](../config/rb3011/gw-servidores-ip-address-pool-dhcp-l2tp.txt)
trouxe `/ip address`, `/ip pool`, `/ip dhcp-server` e `/interface l2tp-server server`. Ver análise
nas seções seguintes.

**Atualização (coleta 2):** `/interface vlan`, `/ppp profile`, `/interface ovpn-server server`,
`/routing ospf instance/area`, `/interface eoip` e `/interface print brief` também foram coletados —
ver [`gw-servidores-vlans-portas-ppp-ovpn-ospf.txt`](../config/rb3011/gw-servidores-vlans-portas-ppp-ovpn-ospf.txt)
e a análise em [08-vlans-e-portas.md](08-vlans-e-portas.md). `/interface bridge port print` também
veio — **a coleta da GW Servidores está completa.**

## 🚨 A escala real da GW Servidores é muito maior que o desenho assumia

O `/ip address print` retornou **101 endereços em ~52 interfaces** — sendo **~45 interfaces VLAN**.
O [02-arquitetura-alvo.md](02-arquitetura-alvo.md) descreve o Datacom assumindo "roteamento entre
VLANs" e lista as interfaces conhecidas como oito (`sfp1`, `ether3`, `Bridge IP Publico`, `VLAN13`,
`VLAN713`, `VLAN11_eoip`, `VLAN198`, `loopback`) — que era tudo que aparecia na seção OSPF do export
truncado. **A realidade é uma ordem de grandeza maior.**

Este equipamento não é um "gateway de servidores". Ele é o **roteador de agregação L3 de toda a rede
de acesso**, atendendo pelo menos:

| Categoria | Exemplos encontrados |
|---|---|
| **Enlaces para POPs/torres** | Bacupari (VLAN753), Casca (712), Solidão 101 (738), Aguapé (775), Serraria (708), Valim (718), Cavalhada (731), Faz. Cardoso (721), Povos (720), Pantano (719), JDF/Rancho Velho (93), Solidão (713), Juca Ana (198) |
| **Gerência de OLTs** | ZTE CPV, PWW, PWW Nova, BCP, CCB, CASCA, MST, FSB, GGV, Praia MST, Praia São Simão, Praia Solidão, Lagoa do Bacupari, Solidão |
| **Gerência de switches/rádios** | SW Shopping, SW4370 Solidão, S5735 Lagoa Bacupari, SW Aguapé/Povos/Pantano/Serraria/Bacupari, SW FO Shopping, SW TVR, SW Jardim Formoso, Rádios CPV |
| **Clientes corporativos** | Banco do Brasil (PWW, CPV, MST), Consepro PWW, CEEE (Shopping, FSB, BCP, Prédio Maicon), Shopping, TIM (EDD MST) |
| **Servidores/infra interna** | Proxmox (HUB, DOCKER/CDNTV, VOIP, DNS, PNETLAB), Graylog, LibreNMS, Wiki (x2), NTP, DNS recursivo, RADIUS Hubsoft, The Dude, TS Callcenter |

**Implicação para o projeto:** migrar isso para o Datacom não é "recriar algumas SVIs". São ~45
VLANs, dezenas de enlaces ponto a ponto e uma malha de gerência que atravessa várias localidades
(CPV, PWW, MST, BCP, FSB, Solidão, Bacupari…). O [04-plano-migracao.md](04-plano-migracao.md)
precisa ser dimensionado com base nisso, e vale reavaliar se um corte único é viável ou se a
migração precisa ser fatiada por VLAN/POP.

> ✅ **Resolvido pela coleta 2** ([08-vlans-e-portas.md](08-vlans-e-portas.md)): todas essas VLANs
> entram por **uma única porta** (`sfp1`, 1 GE), em estrutura QinQ — o fan-out real é feito pelo
> switch de topo de rack. O corte físico é bem mais simples do que a escala sugeria; o desafio
> passa a ser reproduzir o QinQ roteado no DmOS.

### `Bridge IP Publico` concentra ~25 sub-redes

A interface `Bridge IP Publico` sozinha carrega o bloco público `177.72.104.1/27` **mais ~24
sub-redes privadas** (`192.168.115.x`, `192.168.116.x`, `192.168.123.x`, `192.168.17.x`,
`10.200.255.x`). É um único domínio L2 com multinetting pesado.

No Datacom isso vira **uma SVI com um IP primário e ~24 secundários** — verificar se o DmOS suporta
essa quantidade de endereços secundários por interface. Se não suportar, esse trecho precisa ser
redesenhado (o que provavelmente é saudável de qualquer forma).

## ⚠️ Divergências entre `/ip address` e as redes anunciadas em OSPF

Cruzando `/ip address` com `/routing ospf network`, aparecem inconsistências que valem limpeza — e
que ajudam a explicar o que realmente precisa ser reproduzido no Datacom.

**Redes anunciadas em OSPF sem interface correspondente** (7 órfãs — provavelmente resíduo de
enlaces desativados):

`192.168.115.12/30`, `192.168.115.36/30`, `192.168.123.24/30`, `192.168.15.0/30`,
`192.168.15.16/30`, `172.18.255.160/27`, `192.168.1.0/24`

Além dessas, `10.200.255.248/30` está anunciada mas o endereço correspondente
(`10.200.255.249/30`, "DNS - NOVO") está **desabilitado** (`X`).

**O inverso também ocorre — ✅ e foi explicado pela coleta 2:** a maioria das sub-redes de POP e
gerência não aparece em nenhum `/routing ospf network`, mas o instance tem
**`redistribute-connected=as-type-1` e `redistribute-static=as-type-1`** — ou seja, **todas as ~100
sub-redes conectadas (e as rotas estáticas) são injetadas na OSPF como externas E1** de qualquer
forma. A lista de `network` só define onde o OSPF forma adjacência.

**Por que importa:** o Datacom precisará redistribuir connected/static no OSPF (ou de um desenho
explícito de anúncios — oportunidade de limpeza, já que o E1 "atacado" de hoje propaga inclusive as
redes órfãs listadas acima). Detalhe em [08-vlans-e-portas.md](08-vlans-e-portas.md).

## 🚨 O NE8000 depende da GW Servidores para funções de core

Este é o achado mais crítico do levantamento até agora. Cruzando o `/ip address` da GW Servidores
com o export do NE8000, o núcleo da rede **depende do Mikrotik que vamos remover**:

### 1. `177.72.104.1` é next-hop de rotas estáticas do NE8000

```
ip route-static 10.8.0.0   255.255.248.0 177.72.104.1
ip route-static 10.254.0.0 255.255.252.0 177.72.104.1
```

`177.72.104.1/27` está na interface `Bridge IP Publico` da GW Servidores. Não é "só o IP de
masquerade" — é um **next-hop que o roteador de core usa**. Quem assumir o papel precisa herdar
esse endereço, ou essas duas rotas quebram no corte.

### 2. A sessão BGP de FlowSpec (anti-DDoS) passa pelo Mikrotik

```
peer 177.72.104.27 description RR_FLOW_IPv4
peer 177.72.104.27 connect-interface 177.72.104.54
router-id 177.72.104.54
```

- `177.72.104.54` fica na subinterface `Gi0/1/8.28`, que é **exatamente o link com a GW Servidores**
  (o outro lado é `177.72.104.53/30` em `sfp1`). Ou seja, o **router-id BGP do NE8000 e a origem da
  sessão iBGP estão na interface voltada para o Mikrotik**.
- `177.72.104.27` (o route-reflector de FlowSpec) é um host **dentro do `177.72.104.0/27`**, que
  mora na `Bridge IP Publico` da GW Servidores.
- O NE8000 **não tem nenhuma interface própria dentro de `177.72.104.0/27`** (verificado em todo o
  export) e não origina esse prefixo em OSPF. O único equipamento que anuncia `177.72.104.0/27` na
  area 1 é a própria GW Servidores
  (`/routing ospf network add area=area1 network=177.72.104.0/27`).

**Consequência:** se a GW Servidores cair ou sair sem substituto equivalente, o NE8000 perde a
sessão de FlowSpec — que é justamente o mecanismo de mitigação de DDoS, junto com o peer
`ADYLNET_DDOS`. O mesmo vale para o NetStream/IPFIX, exportado para `177.72.104.27:3055`.

### O que isso impõe ao plano de corte

Qualquer que seja o desenho final, o substituto precisa, **no mesmo instante do corte**:

1. Assumir `177.72.104.1/27` (next-hop das rotas estáticas do NE8000 e gateway dos servidores).
2. Continuar anunciando `177.72.104.0/27` na OSPF area 0.0.0.1.
3. Manter o segmento `177.72.104.52/30` ↔ NE8000 ativo (`.53` deste lado, `.54` no NE8000).
4. Manter alcançável o host `177.72.104.27` (RR de FlowSpec + coletor NetStream).

*(O `177.72.104.1` também é o endpoint local do túnel EoIP com o NOC — ver
[08-vlans-e-portas.md](08-vlans-e-portas.md) —, mas esse túnel está fora do ar atualmente e EoIP é
tecnologia proprietária Mikrotik, sem equivalente no Datacom/NE8000: o acesso do NOC precisará de
outra solução de qualquer forma.)*

Isso reforça que o corte **não pode ser feito por partes** nesse ponto específico — ou reforça a
necessidade de uma janela com plano de rollback muito claro.

### Detalhe do link com o NE8000 (refina a decisão #4)

O link não é um cabo direto. Ambos os endereços da ponta Mikrotik estão em
`sfp1 - UPLINK SW TOPO DO RACK`, ou seja, **passam por um switch de topo de rack**:

| Lado | Endereço | Interface |
|---|---|---|
| GW Servidores | `192.168.116.34/30` | `sfp1 - UPLINK SW TOPO DO RACK` |
| GW Servidores | `177.72.104.53/30` | `sfp1` (mesmo segmento L2, multinetting) |
| NE8000 | `192.168.116.33/30` | `Gi0/1/8.28` (dot1q VLAN 28) |
| NE8000 | `177.72.104.54/30` | `Gi0/1/8.28` (endereço `sub`/secundário) |

Ou seja: o NE8000 entrega **VLAN 28 taggeada**, o switch de topo de rack entrega **untagged** no
`sfp1` do Mikrotik, e o segmento carrega **duas sub-redes** (uma privada de gerência, uma pública).
O Datacom precisará reproduzir esse multinetting — uma SVI com IP primário e secundário.

## ✅ A VPN **não** é "L2TP/IPSec" — confirmado

A dedução feita a partir da ausência de `/ip ipsec peer` no export foi confirmada diretamente por
`/interface l2tp-server server print`:

```
               enabled: yes
        authentication: chap,mschap1,mschap2
       default-profile: default-encryption
             use-ipsec: no          <-- IPSec DESLIGADO
          ipsec-secret: ntp1030     <-- configurado, mas nunca usado
```

Duas conclusões:

1. **`enabled: yes`** → a VPN **termina sim neste Mikrotik**. A regra `chain=forward` no firewall é
   para o tráfego dos clientes já conectados, não para repasse do túnel.
2. **`use-ipsec: no`** → apesar do nome da regra "LIBERA L2TP IPSEC" e da documentação anterior,
   **não há IPSec**. É L2TP puro; a única proteção do conteúdo é o MPPE negociado pelo PPP.

Isso simplifica a decisão #5: o que precisa de novo lar é um **servidor L2TP simples com 4 usuários
locais**, não uma stack L2TP/IPSec. É um requisito bem menor do que o documentado até agora.

### Achados de segurança na VPN

| Item | Situação | Risco |
|---|---|---|
| `use-ipsec: no` | L2TP sem IPSec | Túnel sem criptografia de transporte; depende só de MPPE |
| `authentication: chap,mschap1,mschap2` | CHAP e MS-CHAPv1 aceitos | Ambos são algoritmos quebrados. Deveria ser **apenas `mschap2`** |
| `ipsec-secret: ntp1030` | Definido mas inativo | Segredo exposto no equipamento sem função; note a semelhança com a chave OSPF `ntprb1030` — padrão de reuso de credencial |
| Senhas dos `/ppp secret` | Texto claro no export | Rotacionar todas ao desativar o equipamento |

> **Confirmado pela coleta 2 — e é pior do que parecia:** `/ppp profile print` mostrou que **os
> dois profiles têm `use-encryption=no`**, inclusive o chamado "default-encryption" (que foi
> alterado — o padrão de fábrica desse profile exige MPPE). A única diferença real entre eles é o
> clamp de MSS. Conclusão: **nenhum usuário da VPN tem criptografia obrigatória** — sem IPSec e sem
> MPPE exigido, as sessões L2TP podem trafegar em texto claro. A distinção entre usuários com um
> profile ou outro é irrelevante na prática.

### ✅ Segundo serviço de VPN confirmado: OpenVPN habilitado

`/interface ovpn-server server print` (coleta 2) confirmou: **servidor OpenVPN ativo** — porta
1194 (ROS6 = TCP apenas), `require-client-certificate=yes`, cipher AES-256, auth SHA1, profile
`default-encryption`. Ou seja, a decisão #5 envolve **dois** serviços de acesso remoto a realocar:
L2TP (sem criptografia obrigatória) e OpenVPN (este sim com certificado de cliente e cifra
decente).

Curiosamente o pool `ovpn-pool` (`192.168.77.x`) parece **órfão mesmo assim**: nenhum profile
referencia pool/endereços, então os clientes OVPN devem receber os IPs fixos dos próprios
`/ppp secret` (10.7.0.x) — os mesmos 4 usuários servem para as duas VPNs.

## ✅ DHCP: praticamente inexistente — decisão #1 fica trivial

`/ip dhcp-server print` mostra apenas **dois** servidores, e **um deles está inválido**:

| # | Nome | Interface | Pool | Situação |
|---|---|---|---|---|
| 0 | `dhcp1` | `VLAN1066 - GERADOR MST` | `dhcp_pool8` (`192.168.90.2-254`) | ✅ Único funcionando |
| 1 | `dhcp2` | `ether6 - PC TS SIX` | `dhcp_pool9` (`192.168.66.2-14`) | ❌ `I` — *"DHCP server can not run on slave interface"* (ether6 é membro de bridge) |

**Ou seja: existe exatamente um DHCP server operante, servindo uma única VLAN** (geradores em
Mostardas). Isso praticamente encerra a decisão #1 — DHCP não é um fator de peso na escolha de
arquitetura; qualquer das opções (NE8000 ou Datacom) atende sem esforço.

### Pools órfãos (candidatos a limpeza)

Dos 10 pools, **8 não são usados por nenhum DHCP server**:

- `POOLESCRITORIOBCP`, `POOLESCRITORIOMST`, `POOLESCRITORIO PWW`, `DHCP SUPORTE PWW` — todos em
  `192.168.122.x`, faixa que **não tem nenhum `/ip address` neste equipamento**. O DHCP dos
  escritórios é servido em outro lugar hoje; estes são resíduo.
- `dhcp_pool5` (`192.168.25.2-6`) — `192.168.25.0/29` aparece na address-list `NAT`, mas sem
  interface aqui. Resíduo.
- `dhcp_pool6`, `dhcp_pool7`, `dhcp_pool9` — **três pools idênticos** (`192.168.66.2-14`), dos quais
  só o `dhcp_pool9` é referenciado (pelo servidor quebrado).
- `ovpn-pool` — ver acima.

## Pendências para fechar este levantamento

- ~~Identificar os serviços por trás dos IPs "accept sem nome"~~ ✅ **maioria resolvida pelo
  cruzamento com o Dude** ([11](11-cruzamento-dude-devices.md)) — restam só `.26`, `.57`,
  `.105.221` sem identificação em nenhuma fonte.
- Confirmar se `182.168.83.0/24` / `182.168.84.0/24` são erro de digitação.
- Decidir o que fazer com `1.1.1.0/24` usado como numeração interna.
- Cruzar esta lista com o Passo 1 do [05-limpeza-politicas.md](05-limpeza-politicas.md) (quais
  sistemas ainda estão vivos) para saber quais desses IPs realmente precisam de NAT no NE8000.
