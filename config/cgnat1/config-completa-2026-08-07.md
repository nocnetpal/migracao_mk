# CGNAT-1 (Hillstone "CGNAT-NETPAL") — config completa (dump bruto 2026-08-07)

> Fonte primária: `show configuration` no próprio equipamento. Conteúdo sensível
> (hashes de senhas, communities SNMP) — tratar como credencial; **não copiar valores para
> os docs** (regra do `docs/01`). Rotacionar na fase 4.

## Topologia de interfaces (relevante)

- `ethernet0/0` — **gerência dedicada**: `192.168.1.1/24` (zone mgt) — ssh/ping/snmp/https
- `xethernet4/0` + `xethernet4/1` — **membros do LAG** `aggregate1` (lacp enable)
- `aggregate1.400` — **OUTSIDE**: `177.72.104.66/30` (untrust) — ssh/https/ping/snmp habilitados
  (é o IP que o Dude mostra como "CGNAT 1 - Jardim Formoso 177.72.104.66")
- `aggregate1.401` — **INSIDE**: `177.72.104.70/30` (trust)
- `aggregate1.40` — sem IP (interface base dot1q do agregado)

## Rotas (trust-vr)

- `0.0.0.0/0 via 177.72.104.65` (aggregate1.400 — default OUTSIDE)
- `100.64.0.0/19` e `100.127.0.0/20 via 177.72.104.69` (aggregate1.401 — CGNAT assinantes)
- `177.93.242.0/24 null0`

## SNAT

- POOL-PRIVATE-01 (`100.64.0.0/19`) → POOL-PUBLIC-01 (`177.93.242.0/24`)
- POOL-PRIVATE-02-RADIO (`100.127.0.0/20`) → POOL-PUBLIC-02-RADIOS (`177.72.107.0/24`)

## Gerência/SNMP

- SNMP hosts: `177.72.104.0/27`, `177.72.104.1`, `192.168.15.0/24`, `192.168.115.0/24`
- arp-mib-query: `177.72.104.6` (Zabbix) via aggregate1.400
- admin hosts: `192.168.1.0/24`, `177.72.104.0/27`, `177.93.244.165`, `170.82.198.218`,
  `167.250.29.190`, `186.219.133.117`

## Conclusões para o DM4170 (porta GE 1/1/9) — 2026-08-07

1. O CGNAT-1 usa **LAG de 2 portas** (`xethernet4/0` + `xethernet4/1`) com **subinterfaces
   dot1q VLAN 400 (OUTSIDE) e 401 (INSIDE)** — **não é host da VLAN 16** e não usa QinQ.
2. As tags 400/401 precisam ser **transportadas pelo DM4170** até quem terminar os `/30`
   `.64/30` (gw `.65`) e `.68/30` (gw `.69`) — hoje o RB3011; no alvo, o **NE8000**
   (sub-redes dentro do `/27`, decisão #9/#13).
3. **Achado novo:** VLANs **400 e 401 não constam no mapeamento do doc 09** (que lista 27 QinQ
   + 2 simples + 16) — precisam ser adicionadas ao plano L2 do DM4170/NE8000.
4. A GE 1/1/9 do DM4170 deve ser **trunk com as VLANs 400 e 401 tagged** (não access 16).
   Se mantiver o LAG: **2 portas GE** (GE 1/1/9 + GE 1/1/10 ou vizinhas). Meio físico das
   xethernet: a confirmar (SFP óptico ou SFP-RJ45).
5. A gerência "pura" do equipamento é a `ethernet0/0` (`192.168.1.1/24`) — rede local de
   gerência, provavelmente sem relação com o DM4170 (confirmar o que está plugado nela).
