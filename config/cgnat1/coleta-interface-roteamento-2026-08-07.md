# CGNAT-1 (Hillstone "CGNAT-NETPAL") — coleta 2026-08-07

> Coletado via CLI no próprio equipamento (177.72.104.66). Usado para decidir a porta GE
> 1/1/9 do DM4170 (mapa A.6 do doc 15 chamava de "CGNAT-1 mgmt .66").

## show interface (resumo)

| Interface | IPv4 | Zona | Estado | MAC |
|---|---|---|---|---|
| aggregate1 | 0.0.0.0/0 | NULL | U U U D | 3029.52e8.2694 |
| aggregate1.40 | 0.0.0.0/0 | NULL | U U U D | 3029.52e8.2694 |
| **aggregate1.400** | **177.72.104.66/30** | untrust | U U U U | 3029.52e8.2694 | OUTSIDE |
| **aggregate1.401** | **177.72.104.70/30** | trust | U U U U | 3029.52e8.2694 | INSIDE |
| vswitchif1 | 0.0.0.0/0 | NULL | D U D D | — |
| **ethernet0/0** | **192.168.1.1/24** | mgt | U U U U | 3029.52e8.266a | (gerência dedicada) |
| ethernet0/1..0/9 | 0.0.0.0/0 | NULL | D U D D | — | (down) |
| xethernet4/0, 4/1 | 0.0.0.0/0 | NULL | U U U D | — | (up, sem protocolo) |

## show ip route (trust-vr)

```
S>* 0.0.0.0/0 via 177.72.104.65, aggregate1.400      (default OUTSIDE)
S>* 100.64.0.0/19 via 177.72.104.69, aggregate1.401  (CGNAT assinantes)
S>* 100.127.0.0/20 via 177.72.104.69, aggregate1.401 (CGNAT assinantes)
C>* 177.72.104.64/30 connected, aggregate1.400       (.66/30, gw .65)
C>* 177.72.104.68/30 connected, aggregate1.401       (.70/30, gw .69)
S>* 177.93.242.0/24 null0
```

mgt-vr: `192.168.1.0/24` connected em ethernet0/0 (192.168.1.1).

## show arp

```
177.72.104.65  f4b7.8d04.5bac  aggregate1.400
177.72.104.69  f4b7.8d04.5bac  aggregate1.401
```

> ⚠️ `.65` e `.69` (gateways dos /30) resolvem num **mesmo MAC** (f4b7.8d04.5bac) — provável
> RB2011/RB3011 na bridge — conferir identidade na etapa B.

## Conclusão para o DM4170 (GE 1/1/9)

- O "mgmt .66" do Dude é na verdade a **subinterface de dados OUTSIDE** do firewall
  (`177.72.104.66/30`, gateway `.65`) — não é host do `/27` direto.
- O CGNAT-1 tem **link de dados agregado (LAG)** com subinterfaces VLAN **400** (OUTSIDE) e
  **401** (INSIDE), ambos /30, e **porta de gerência dedicada** ethernet0/0 (`192.168.1.1/24`).
- A GE 1/1/9 do DM4170 **não é "VLAN 16 native" simples** — depende do que hoje entra na p3
  do RB2011 (link de dados agregado ou porta de gerência). **Decisão pendente** antes de
  configurar a porta.
