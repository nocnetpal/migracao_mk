# BGP_NETPAL (VS do NE8000) — config completa (dump bruto 2026-08-07)

> Fonte primária: `display current-configuration` na virtual-system BGP_NETPAL (2026-08-07,
> atualizada às 16:37 por Jdf1010, salva 16:38). Conteúdo sensível (senhas/communities em
> cipher) — **não copiar valores para os docs**; rotacionar na fase 4.
>
> Resumo executivo e achados em `resumo-bgp_netpal-2026-08-07.md` (mesma pasta).

## Identificação

- sysname: BGP_NETPAL · slot 10 (pvmb, VS do NE8000 físico)
- OSPF: process 1, router-id `172.16.200.1`, area 0.0.0.1, silent-interface all + exceções
  (todas as GE0/1/8.xxx de POP com `ospf authentication-mode md5 1 plain ntprb1030`)
- BGP: AS 52828, router-id `177.72.104.54`

## Interfaces relevantes (resumo)

- GE0/1/2 = `TRUNK_BGP_LUCFIBRA` · GE0/1/2.198 = `BGP_LUCFIBRA` `10.91.91.1/30` (peer 10.91.91.2 AS 269184)
- GE0/1/3 = `MGMT-DM4170-SW_SERVIDORES` (nossa, sem IP na física) · `.16` = 177.72.104.1/27 shutdown · `.48` = 192.168.15.49/30 shutdown
- GE0/1/7 = `BGP_RL_CDN_NETFLIX_GLOBO` · `.4053` = `10.95.95.2/30` (peer 10.95.95.1 AS 268671, RL de CDN Netflix/Globo)
- GE0/1/8 = trunk POPs: dezenas de subinterfaces QinQ (pe-vid/ce-vid), todas com OSPF MD5 ntprb1030;
  `.10` = GERENCIA_SW6730_JDF_5720CDN (192.168.15.25/30 + sub .5); `.20` = SW_5720PWW;
  `.23` = SERVIDOR_CDN_TV (177.72.104.105/29); `.24` = VPN_JDF; `.28` = GERENCIA_GW_SERVIDORES
  (192.168.116.33 + 177.72.104.54 sub — a VLAN 28!); `.198` = JUCA_ANA_IP_PUBLICO (177.72.104.61/30);
  `.350` = DUDE_TESTE; `.706`-`.778` = MK_POP_*; `.5162` = Cooperativa Rizícola rota 2
- 100GE0/3/0: `.2602` = ADYLNET_POA_100GE (172.19.236.6/30) · `.2706` = ADYLNET_TDAI_100GE (172.19.246.22/30)
- LoopBack0 = `172.16.200.1/32` (router-id OSPF) · LoopBack2 = `10.200.255.242/32` (nossa, no OSPF)
- VE0/2/21.1014 = CGNAT-NETPAL `10.200.255.1/30` (OSPF MD5, p2p com o PPPOE)

## BGP (AS 52828, router-id 177.72.104.54)

| Peer | IP | AS | Descrição |
|---|---|---|---|
| LUCFIBRA | 10.91.91.2 (GE0/1/2.198) | 269184 | route-policy LUCFIBRA-IN/OUT |
| RL CDN | 10.95.95.1 (GE0/1/7.4053) | 268671 | Netflix/Globo — RL-IN/OUT, as-path RL-GLOBO `_28604_` |
| ADYLNET | 172.19.236.5 (100GE .2602) | 28283 | ADYLNET_POA |
| ADYLNET | 172.19.246.21 (100GE .2706) | 28283 | ADYLNET |
| ADYLNET blackhole | 189.14.239.255 | 28283 | ebgp-max-hop 255, community 28283:666 |
| **RR_FLOW_IPv4** | **177.72.104.27** | 52828 | **connect-interface 177.72.104.54** — FlowSpec + unicast (RR), add-path 8 |
| GGC_NETPAL | 177.72.104.126 | 11344 | senha simple configurada |

## NetStream

- `ip netstream export source 177.72.104.54` + host `177.72.104.27:3055` — **source = .54** (morre
  na janela QinQ; validar/trocar junto com o router-id BGP — checklist do doc 13)

## Rotas estáticas que dependem do RB3011 (decisão #8)

- `10.8.0.0/21 via 177.72.104.1` · `10.254.0.0/22 via 177.72.104.1` — **next-hop .1 = RB3011**;
  na Etapa B os next-hops (.9/.12) viram connected quando o /27 subir no NE8000 (doc 02)
- `177.72.107.0/24 via 177.72.104.66` e `177.93.242.0/24 via 177.72.104.66` → CGNAT-1 (Hillstone)
- `177.93.240.0/24 via 177.72.104.102` → CGNAT-2
- Blackholes: `177.72.104.0/22` NULL0, `177.72.104.0/24` NULL0, `177.72.105.0/24` NULL0,
  `177.72.106.0/24` NULL0, `177.93.240.0/21` NULL0 etc. (anti-spoof/anti-loop)

## ACLs / gerência

- `IPV4_NOC_NETPAL` (VS): regras 10–100 (NOC .165, .19, .104.0/27, 192.168.0.0/24, .52/30...) + deny 666
- `ssh server acl IPV4_NOC_NETPAL` · SNMP com `acl 2999` (leitura)
- SSH client peers: rsa `177.72.104.66` (CGNAT-1), ecc `192.168.15.35` e `192.168.233.2`
- FTP/sftp client-source `-a 177.72.104.61` (Juca Ana — consistente com a decisão #10)
