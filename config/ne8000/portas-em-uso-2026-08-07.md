# NE8000 — portas físicas em uso (levantamento 2026-08-07, VS BGP_NETPAL + chassi)

> Levantado no `display interface brief` de 2026-08-07 para escolher a porta do trunk com o
> DM4170. ⚠️ **GE0/1/2 e GE0/1/7 parecem livres mas NÃO estão** — têm subinterfaces ativas.

## VS BGP_NETPAL (portas atribuídas)

| Porta | Estado | Uso | Obs |
|---|---|---|---|
| 100GE0/3/0 | up | .2602/.2706 (enlaces) | produção |
| GE0/1/2 | up, OutUti 18% | **`TRUNK_BGP_LUCFIBRA`** — subinterface `.198` = `BGP_LUCFIBRA` `10.91.91.1/30` (peer BGP `10.91.91.2`, AS 269184) | ✅ identificada — ⚠️ produção (BGP de trânsito LUCFIBRA) |
| GE0/1/3 | down/down | 🆕 **trunk DM4170** (`.16` = .1/27) + gerência (`.48` = .49/30) — ambas shutdown | criada 2026-08-07 |
| GE0/1/7 | up, InUti 15% | **`BGP_RL_CDN_NETFLIX_GLOBO`** — subinterface `.4053` = `10.95.95.2/30`, UP/UP, netstream — **peer BGP de CDN (Netflix/Globo)** | ✅ identificado 2026-08-07 — ⚠️ produção, não mexer |
| GE0/1/8 | up | trunk POPs (dezenas de subinterfaces) | produção |
| Eth-Trunk1.400/2.400 | up | CGNAT-1/2 OUTSIDE | produção |

## Chassi (PPPOE_NETPAL)

| Porta | Estado | Uso |
|---|---|---|
| GE0/1/0, 0/1/1 | up | Eth-Trunk2 (CGNAT-2) |
| GE0/1/4, 0/1/5 | up | Eth-Trunk1 (CGNAT-1) |
| GE0/1/6 | up/down, 0.01% | "LIVRE_10G" mas PHY up — algo plugado, evitar |
| GE0/1/9 | down/down | LIVRE (reserva futura) |
| 100GE0/3/1 | up | PPPoE server (QinQ assinantes) |
| Ethernet0/0/0 | up | gerência local 192.168.15.2/30 |

## Pendência de identificação

- ~~**GE0/1/2.198** (tráfego real)~~ → ✅ **identificada (2026-08-07):** `TRUNK_BGP_LUCFIBRA`
  — peer BGP de trânsito (`10.91.91.2`, AS 269184), VLAN 198. **Não é** o Juca Ana (esse é a
  `GE0/1/8.198` = `177.72.104.61/30`, QinQ 46/198 — decisão #10).
- ~~**GE0/1/7.4053** (VLAN 4053, tráfego real): identificar o enlace — não consta nos docs do projeto.~~ → ✅ **identificada (2026-08-07):** `BGP_RL_CDN_NETFLIX_GLOBO` — peer BGP de CDN (Netflix/Globo), `10.95.95.2/30`, netstream habilitado. Produção, **não mexer** na migração.
