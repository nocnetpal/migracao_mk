# NE8000 "BGP_NETPAL" — o que ele realmente é

## Achado principal

O NE8000 **não é um equipamento novo entrando só para assumir firewall/NAT/VPN da GW Servidores**.
Ele é o **core BGP + OSPF de toda a rede da NetPal**, já em produção, com:

- **BGP AS 52828**, peering com:
  - `LUCFIBRA` (AS 269184) — trânsito
  - `RL` / CDN Netflix-Globo (AS 268671)
  - `ADYLNET` (AS 28283) — dois pontos (POA e TDAI, ambos 100GE), incluindo um peer específico
    de **blackhole/DDoS scrubbing** (`ADYLNET_DDOS`, ebgp-max-hop 255)
  - Route-reflector interno (`177.72.104.27`, AS 52828, também usado para FlowSpec)
  - Google GGC (cache CDN, AS 11344)
- **OSPF area 0.0.0.1 (= "area1")** — a mesma area1 vista no export do Mikrotik "GW Servidores",
  com a **mesma chave MD5** da area1 (valor: ver exports em `config/ne8000/`). Confirma que MK e
  NE8000 já são vizinhos OSPF hoje.
- **Dezenas de subinterfaces QinQ**, cada uma sendo um link ponto a ponto para um POP, torre,
  rádio ou cliente com IP público dedicado (nomenclatura `MK_POP_*`, `RB_*`, `GERENCIA_SW_*`, etc.)
  — isso é a distribuição inteira da rede da NetPal convergindo neste equipamento.
- **CGNAT** (duas instâncias: `CGNAT-NETPAL` e `CGNAT-NETPAL2-OUTSIDE`).
- NetStream/IPFIX (equivalente a NetFlow) exportando para `177.72.104.27:3055`.

## O link direto com a GW Servidores — confirmado

Subinterface `GigabitEthernet0/1/8.28`:
```
description GERENCIA_GW_SERVIDORES_HUAWEI_NE8000
ip address 192.168.116.33 255.255.255.252
ospf authentication-mode md5 1 plain <chave-area1>
ospf network-type p2p
ospf enable 1 area 0.0.0.1
```
`192.168.116.33` é exatamente o gateway que a GW Servidores usa hoje como rota padrão
(`add comment=NETPAL distance=1 gateway=192.168.116.33`, ver
[`01-inventario-atual.md`](01-inventario-atual.md)). **Isso resolve a decisão #4** em
[03-decisoes-pendentes.md](03-decisoes-pendentes.md): o NE8000 já é vizinho OSPF da GW Servidores
hoje, por essa subinterface. Quando a GW Servidores sair e o Datacom entrar no lugar, a adjacência
OSPF dessa ponta simplesmente precisa ser recriada no Datacom, apontando pro mesmo lado do NE8000
(mesma VLAN 28, mesma sub-rede `192.168.116.32/30`, mesma area 1, mesma chave MD5 — ou uma nova,
já que vamos rotacionar).

## Modelo de gerência já existente (aproveitar para o Passo 3 da limpeza)

O NE8000 já usa uma ACL nomeada única para controlar quem acessa a gerência:

```
acl name IPV4_NOC_NETPAL basic
 description REDE_GERENCIA_NETPAL Control
 rule 10 permit source 177.93.244.165 0
 rule 11 permit source 177.72.104.19 0
 ...
 rule 100 permit source 177.72.104.52 0.0.0.3
 rule 666 deny
#
ssh server acl IPV4_NOC_NETPAL
```

Isso é exatamente o padrão que faltava no Mikrotik (que tinha uma allowlist diferente por
serviço). **Proposta:** usar esse mesmo modelo — uma única ACL de gerência nomeada — como padrão
para SSH/API/Winbox/gerência do Datacom também, em vez de inventar um esquema novo. Ver
[05-limpeza-políticas.md, Passo 3](05-limpeza-politicas.md).

## Legado / cruft encontrado (candidatos a limpeza, mesmo espírito do Passo 1)

- `acl ip-pool CLIENTE_PORTAS_LIBERADA` — pool vazio, provavelmente erro de digitação duplicando
  `CLIENTE_PORTAS_LIBERADAS` (que tem conteúdo). Candidato a remoção.
- A política `DROPFORWARD` (que replica a mesma lógica de "portas bloqueadas para fora" do
  Mikrotik) só está **aplicada nas duas interfaces 100GE da ADYLNET** — não é global. Vale
  confirmar se isso é intencional (proteção só no trânsito internet) ou lacuna.
- `route-policy MADE4FLOW-IN` existe mas não está associada a nenhum peer BGP no trecho visto —
  possível resíduo de configuração antiga.

## ⚠️ Segurança — achados neste export

1. **Senha de sessão BGP em texto claro**: `peer 177.72.104.126 password simple j6vpa0q0`
   (peer com o Google GGC, AS 11344). Deveria usar `password cipher` (criptografado) em vez de
   `simple`. Recomendo trocar essa senha e usar o modo cifrado.
2. Backup de configuração via FTP para `177.72.104.131` com credencial em "reversible cipher" do
   Huawei (`hwbkp` / senha ofuscada, mas reversível por quem tem acesso ao equipamento) — mesmo
   servidor de backup usado pelos Mikrotiks. Tratar como sensível, mesma recomendação de rotação.
3. SNMP community está em `cipher` (criptografado) — **ponto positivo**, ao contrário do Mikrotik
   "RB Bridge Servidores" que tinha community em texto claro com write-access liberado pra
   internet inteira.
4. Chave OSPF MD5 da area1 é a **mesma em toda a rede** (dezenas de interfaces). Não é uma
   vulnerabilidade grave em si (é assim que OSPF costuma ser operado numa rede única), mas se for
   trocada em algum ponto por causa da migração, precisa trocar em todos os vizinhos ao mesmo
   tempo (ou usar rollover de key-id).

## O que isso muda no desenho da migração

- O NE8000 **já está pronto e em produção** para o papel de "roteador acima do Datacom" — não é
  preciso configurá-lo do zero, só adicionar/ajustar a ponta que hoje fala com a GW Servidores.
- O Datacom entra numa rede muito maior do que o desenho inicial sugeria: ele não é só "o substituto
  local", ele passa a ser mais um vizinho OSPF nessa area1 gigante, ao lado de dezenas de outros
  Mikrotiks de POP.
- Nenhuma indicação, até agora, de que o NE8000 faça NAT de usuário/PPPoE ou VPN L2TP/IPSec de
  equipe — essas funções continuam sem um lugar definido (ver decisões #1 e #5 em
  [03-decisoes-pendentes.md](03-decisoes-pendentes.md)). O CGNAT visto aqui é CGNAT de assinantes
  (100.64.0.0/10, carrier-grade NAT), não o NAT de servidores internos que a GW Servidores fazia.
