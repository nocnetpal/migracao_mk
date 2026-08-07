# CCR1036 — troca .4 → .15 aplicada (2026-08-07)

> Aplicado em bancada em 2026-08-07 (equipamento ligado, SFP do trunk desconectado).
> Motivo: `177.72.104.4` é o LoopBack1 .4/32 do NE8000/PPPOE_NETPAL (conflito de IP e de
> router-id OSPF). `.15` confirmado livre (ping/ARP em NE8000 e RB3011).

## Aplicado

| Item | Antes | Depois |
|---|---|---|
| IP VLAN 16 | 177.72.104.4/27 | **177.72.104.15/27** |
| SRC-NAT (to-addresses) | .4 | **.15** |
| DST-NAT Dude (`dst-address`) | (sem — casava por porta) | **177.72.104.15** |
| DST-NAT TS SIX (`dst-address`) | (sem — casava por porta) | **177.72.104.15** |
| router-id OSPF (`ospf1`) | .4 | **177.72.104.15** |

## Comandos aplicados

```
/ip address set [find where address="177.72.104.4/27"] address=177.72.104.15/27
/ip firewall nat set [find where to-addresses="177.72.104.4"] to-addresses=177.72.104.15
/ip firewall nat set [find where comment~"DUDE"] dst-address=177.72.104.15
/ip firewall nat set [find where comment~"TS SIX"] dst-address=177.72.104.15
/routing ospf instance set [find name="ospf1"] router-id=177.72.104.15
```

## Validação (2026-08-07)

```
/routing ospf instance print → ospf1 router-id=177.72.104.15 ✅
/ip address print → vlan16-PUBLICA 177.72.104.15/27 ✅
/ip firewall nat print → SRC-NAT to .15; DST-NAT com dst-address .15 ✅
```

## ⚠️ Atenção

- Os scripts `config/ccr1036/*.rsc` e o backup `ccr1036-pre-corte-2026-08-06.rsc` ainda têm
  o `.4` — **não re-executar** (documentado no runbook). Gerar export novo no fim da noite:
  `/export file=ccr1036-pre-corte-v2`.
