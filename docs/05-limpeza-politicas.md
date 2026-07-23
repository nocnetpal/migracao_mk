# Limpeza e redesenho das políticas (firewall/NAT)

## Princípio

O objetivo **não é portar 1:1** o conjunto de regras do Mikrotik "GW Servidores" para o
NE8000/Datacom. O ruleset atual cresceu de forma orgânica ao longo dos anos (regra por regra, por
sistema, por IP) e virou difícil de auditar. A migração é a oportunidade de redesenhar do zero,
com 4 diretrizes definidas pelo usuário:

1. **Remover regras de sistemas que não existem mais** — descartar tudo que for legado.
2. **Descartar a geo-allowlist `BRASIL`** — não recriar essa lista enorme de faixas de IP no novo desenho.
3. **Padronizar acesso de gerência** (SSH/Winbox/API/FTP) — um único padrão em vez de porta
   não-padrão + allowlist diferente por serviço.
4. **Trocar regra por IP individual por zonas/VLANs** — agrupar por função em vez de uma regra
   por servidor.

## Passo 1: confirmar o que ainda está vivo

O export do "GW Servidores" tem regras nomeadas para os seguintes sistemas/parceiros. Preciso de
confirmação de quais ainda estão em uso hoje (o resto vira regra removida, não migrada).

🆕 **Cruzado com o Dude** ([11-cruzamento-dude-devices.md](11-cruzamento-dude-devices.md)) — coluna
"Nome no Dude hoje" é monitoramento ativo, mais confiável que o comentário do firewall (que pode ser
antigo). Onde os nomes **não batem**, o nome do Dude é o forte candidato a estar certo:

| Sistema/regra no MK antigo | IP(s) | Nome no Dude hoje | Ainda ativo? |
|---|---|---|---|
| Hubsoft (billing/ERP) | `177.72.104.8` | ⚠️ **não aparece no Dude** | Provável **morto** — ver `.16` abaixo |
| Hubsoft (billing/ERP) | `177.72.104.5` | Proxmox Zabbix | ? — mesmo IP também é "CallSys" |
| Fusion Netpal (clientes elaborados) | `177.72.104.14` | Fusion - VoIP - PM CPV | provável ativo |
| Fusion Netpal (clientes simples) | `177.72.104.25` | Fusion - VoIP - Painéis Simples | provável ativo |
| Fusion Netpal (geral) | `177.72.104.18` | Fusion - VoIP - 0800 NETPAL | provável ativo |
| Servidor Fusion Voip | `177.72.104.7` | ⚠️ **DOCS Cloud** (nome não bate) | confirmar — pode ter mudado de função |
| Servidor Fusion Voip Multistore | `177.72.104.9` | ⚠️ **Servidor VPN** (nome não bate) | confirmar — pode ter mudado de função |
| SBC VOIP | `177.72.104.20` | ⚠️ **SFTP - Netpal - OPA** (nome não bate) | confirmar — pode ter mudado de função |
| TIP VOIP | `177.72.104.13` | Zeus - TIP - VoIP | ativo (bate) |
| MADE4IT | `177.72.104.17` | ⚠️ **Fusion - VoIP - PM MST** (nome não bate) | confirmar — pode ter mudado de função |
| OPA Suite (chat) | `177.72.104.30` | Opa ChatBot | ativo (bate) |
| CallSys | `177.72.104.5` | Proxmox Zabbix | ? — mesmo IP também é "Hubsoft" acima |
| Servidor sala | `177.72.104.16` | ⚠️ **HubSoft** (nome não bate) | **Hipótese: este é o Hubsoft real hoje**, não `.8` |
| The Dude (monitoramento) | `192.168.116.30` | RB DUDE | ✅ confirmado ativo (é a própria fonte do CSV) |
| TS SIX | `192.168.66.14` | TS SIX | ✅ confirmado ativo (bate) |
| DNS NetPal (x3, incl. loopbacks) | `177.72.104.28/58/59` | DNS MASTER (só `.58`) | `.28`/`.59` sem confirmação no Dude |
| Belluno (parceiro externo) | lista `BELLUNO` (5 IPs/redes) | — | ? |
| SixTelecom (parceiro externo) | lista `SIXTELECOM` (5 IPs/redes) | — | ? |
| CGNAT | `177.93.242.0/24` | — | ✅ consistente com CGNAT do NE8000 ([06](06-ne8000-bgp-core.md)) |
| Espectra | lista `ESPECTRA` (nunca populada — já morta?) | — | ? |
| SMTP_LIBERADO | lista nunca populada — bloqueio porta 25 sem exceção real | — | ? |
| 🆕 (sem nome no MK) Zabbix | `177.72.104.6` | Zabbix | novo — incluir no levantamento |
| 🆕 (sem nome no MK) | `177.72.104.22` | Fusion - VoIP - Elaborados - Full | novo — incluir |
| 🆕 (sem nome no MK) | `177.72.104.23` | Aplicações /etc/scripts | novo — incluir |
| 🆕 (sem nome no MK) | `177.72.104.24` | OLT CLOUD | novo — incluir |
| 🆕 (sem nome no MK) | `177.72.104.29` | AUTOMACOES | novo — pode ser o mesmo sistema da decisão #6 |
| 🆕 VPN à parte (não é do MK) | `177.72.104.12` | OpenVPN - 2 | fora do escopo do Passo 1 — ver decisão #5 no [03](03-decisoes-pendentes.md) |
| 🆕 VPN à parte (não é do MK) | `177.72.104.19` | VPN - WireGuard | fora do escopo do Passo 1 — ver decisão #5 no [03](03-decisoes-pendentes.md) |

> Assim que confirmar, atualizo esta tabela e a lista final de "quem precisa de regra no novo
> equipamento" fica só com os sistemas ativos. Os itens com nome divergente (⚠️) são a prioridade —
> pode ser um servidor que trocou de função sem que o firewall tenha sido atualizado.

## Passo 2: geo-allowlist BRASIL — decisão tomada

**Descartar.** A lista `BRASIL` (centenas de faixas de IP nacionais) não será recriada no novo
desenho. Se algum sistema (ex.: Hubsoft) realmente precisar de um controle "só Brasil", isso deve
ser resolvido de outra forma no momento em que a necessidade aparecer de novo — não replicando a
lista estática antiga.

## Passo 3: padronização do acesso de gerência

Hoje cada serviço de gerência tem uma combinação diferente:

| Serviço | Porta hoje | Allowlist hoje |
|---|---|---|
| SSH | 15320 | `177.93.240.0/21, 177.72.104.0/21, 1.1.1.0/24` (+ variações por equipamento) |
| Winbox | padrão (8291) | `177.72.104.0/21, 177.93.240.0/21, 10.7.0.0/24, 192.168.116.28/30` |
| API | padrão | `177.72.104.0/21, 1.1.1.0/24` |
| FTP | 2122 (varia) | `177.93.240.0/21, 177.72.104.0/21, 1.1.1.0/24` |
| WWW | 8858 (desabilitado) | `177.72.104.0/27` |

**A definir:** um padrão único — por exemplo, uma única faixa/VLAN de gerência (ex.: uma "VLAN de
management") liberada para todos os serviços de gerência do NE8000/Datacom, com portas padrão (sem
ofuscação por porta não-padrão) e controle de acesso feito por ACL de zona, não por lista de IP
recriada em cada regra.

> **O NE8000 já tem um modelo bom pra copiar**: uma ACL nomeada única (`IPV4_NOC_NETPAL`,
> descrição "REDE_GERENCIA_NETPAL Control") usada no SSH. Em vez de inventar um esquema novo,
> a proposta é estender essa mesma ACL (ou uma equivalente) para todos os serviços de gerência
> do Datacom também — ver [06-ne8000-bgp-core.md](06-ne8000-bgp-core.md).

**Pergunta em aberto:** existe hoje uma rede/VLAN só para a equipe de gerência (NOC), ou o acesso
de administração vem de várias redes diferentes (escritório, VPN, parceiros)? Isso define se dá
pra consolidar em uma única fonte permitida ou se precisam ser mantidas 2-3 origens.

## Passo 4: modelo de zonas/VLANs (substituindo regra por IP)

Ideia geral (a refinar): em vez de uma regra `accept` por servidor, definir zonas — por exemplo:

- **Zona Gerência/NOC** — acesso administrativo a tudo.
- **Zona Servidores internos** — Hubsoft, Fusion Netpal, DNS, Dude, etc. (os que ficarem confirmados como ativos no Passo 1).
- **Zona VOIP** — SBC, TIP, Fusion Voip.
- **Zona Parceiros externos** — o que sobrar de Belluno/SixTelecom, se ainda ativo, com regra de zona em vez de lista de IP solta.

Cada zona = uma regra de entrada/saída por serviço, não uma regra por host. Isso também facilita
auditoria e ajuste futuro (adicionar um servidor na zona não exige nova regra de firewall).

**Status geral deste documento:** rascunho inicial — falta confirmar Passo 1 (quem está vivo) e
Passo 3 (origem de gerência) para fechar o desenho de zonas do Passo 4.
