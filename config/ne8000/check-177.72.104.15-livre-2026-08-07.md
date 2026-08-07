# Checagem 177.72.104.15 livre (2026-08-07) — CCR1036 novo IP (NAT)

> Motivo: LoopBack1 `177.72.104.4/32` no NE8000 (PPPOE_NETPAL, OSPF area1) conflita com o
> `177.72.104.4` que seria da CCR1036 (decisão #9). Candidato `.15` (único outro livre do
> `/27`). Checagem ao vivo antes de registrar (padrão da checagem 192.168.254).

## NE8000 (PPPOE_NETPAL, 2026-08-07)

```
display ip routing-table 177.72.104.15
   177.72.104.0/27  OSPF  10  12  D  10.200.255.1  Virtual-Ethernet0/3/31.1014
   (sem rota específica para .15)

ping -c 3 177.72.104.15
   3 packet(s) transmitted, 0 received, 100% loss
```

## RB3011 "GW Servidores" (2026-08-07)

```
ping 177.72.104.15
   sent=11 received=0 packet-loss=100%

/ip arp print where address=177.72.104.15
 #    ADDRESS         MAC-ADDRESS  INTERFACE
 0 D  177.72.104.15                Bridge IP Publico     ← dinâmica SEM MAC (não resolvida)
```

## Conclusão

✅ **177.72.104.15 está livre** — usar como novo IP da CCR1036 (SRC-NAT/DST-NAT) no lugar do
`177.72.104.4` (bloqueado pelo loopback `.4/32` do NE8000).
