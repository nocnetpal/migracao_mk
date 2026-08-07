# NE8000 — LoopBacks de gerência permanentes (2026-08-07)

> Criadas para garantir acesso ao NE8000 em qualquer fase da migração (o `.54`/VLAN 28 morre
> na janela QinQ; o `.240` é do PPPOE e permanece). Registro da criação em 2026-08-07.

## ✅ Validação de fora (2026-08-07, PC de operação)

```
ping 10.200.255.241 → 4/4 (TTL 252)
ping 10.200.255.242 → 4/4 (TTL 253)
```

Ambos respondendo de fora do NE8000 — **acesso de gerência garantido** em qualquer fase.

## PPPOE_NETPAL (chassi)

```
interface LoopBack2
 ip address 10.200.255.241 255.255.255.255
ospf 1
 area 0.0.0.1
  network 10.200.255.241 0.0.0.0
```

- Validado: `display ospf routing` → `10.200.255.241/32 Direct 10.200.255.241 10.200.255.2 0.0.0.1`
- OSPF: process 1, router-id `10.200.255.2`, área 0.0.0.1

## BGP_NETPAL (virtual-system)

```
interface LoopBack2
 ip address 10.200.255.242 255.255.255.255
ospf 1
 area 0.0.0.1
  network 10.200.255.242 0.0.0.0
```

- Validado: `display ospf routing` → `10.200.255.242/32 Direct 10.200.255.242 172.16.200.1 0.0.0.1`
- OSPF: process 1, router-id `172.16.200.1`, área 0.0.0.1
- Commitado na VS (`commit`)

## Mapa de acesso ao NE8000 (pós-criação)

| Acesso | IP | VS | Sobrevive à janela QinQ? |
|---|---|---|---|
| LoopBack0 | `10.200.255.240` | PPPOE | ✅ permanece |
| **LoopBack2 (nova)** | **`10.200.255.241`** | PPPOE | ✅ permanece |
| **LoopBack2 (nova)** | **`10.200.255.242`** | BGP_NETPAL | ✅ permanece |
| Gerência local | `192.168.15.2/30` | chassi | ✅ permanece |
| VLAN 28 / `.54` | `177.72.104.54` | BGP_NETPAL | ❌ morre (janela) — substituído pelas LoopBacks |
| LoopBack1 | `177.72.104.4/32` | PPPOE | ✅ permanece (⚠️ bloqueia CCR `.4`) |
| Console | — | — | ✅ sempre (rack) |

## Achado de segurança (fase 4)

- OSPF da VS **BGP_NETPAL**: área `0.0.0.1` com **`Authtype: None`** (sem MD5) — o doc 11
  (estratégia `ntprb1030`) deve considerar rotacionar/ativar autenticação na área da VS.
- OSPF do **PPPOE_NETPAL**: tem `ospf authentication-mode md5 1 plain ntprb1030` (na VE .1014).
