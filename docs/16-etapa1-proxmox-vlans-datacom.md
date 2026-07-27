# Etapa 1 — 2 VLANs nos servidores (privada + pública), depois Datacom/CCR

> ✅ **Modelo (usuário, 2026-07-27):** uma VLAN **privada** (RFC1918/gerência) + uma VLAN
> **pública** (`177.72.104.x`). Migrar L2/tags **ainda nos Mikrotiks**; depois Datacom/CCR;
> por último só virar GW/IPs. POP/OLT/QinQ fora desta etapa.
>
> **IDs fechados (2026-07-27):**
> - **VLAN 100** — privada / gerência — livre no RB3011, NE8000 (dot1q/QinQ), **SW_JDF**
>   (`display vlan 100` → não existe)
> - **VLAN 16** — pública — já no SW_JDF como `IP_PUBLICO` (TG/UT em XGE0/0/11,15,24)
>
> PPPoE_NETPAL / BGP_NETPAL: sem VLAN L2 100/16 (normal). Zero mudança aplicada além de
> renomes ether6–10 no RB3011.

## Mapa

| VLAN | Nome | Uso |
|------|------|-----|
| **100** | GERENCIA_SERVIDORES | hypervisors, VMs privadas, NTP interno, Radius, etc. |
| **16** | IP_PUBLICO | VMs/containers `177.72.104.x` + CCR `.4` depois |

Cabo servidor → MK (e depois Datacom): trunk · native/untagged **100** · tagged **16**  
(ou ambos tagged — a definir na config; default = native 100 + tag 16).

## Ordem

```
M1  Trunks 100+16 nos Mikrotiks (RB3011 / RB750 / RB2011 se precisar)
M2  Proxmox: gerência na 100 · VMs 177 na tag 16
M3  Validar ainda no MK
D   Datacom + CCR (mesmas 2 VLANs)
E   Trocar cabos
F   POP / OLT / QinQ / virada L3 — depois
```

**Regra:** não aplicar `tag=16` no Proxmox **antes** do trunk no MK (HubSoft caiu assim).

## Sequência de hosts

1. Docker (`ether7`)  
2. HubSoft (RB750 p4)  
3. DNS (`ether8`)  
4. Zabbix (RB750 p3) — gerência sai do `.5` → IP privado na VLAN 100  

## Fora / later

- VMs órfãs detalhe fino (cabem na 100 se RFC1918)  
- `10.1.1.2` Zabbix `enp3s0f1`  
- QinQ / POP / OLT  

## Fontes

- Live Proxmox: `config/proxmox-*/live-network-2026-07-27.txt`
- SW_JDF: `display vlan 100/16` (2026-07-27)
- [15](15-plano-migracao-servidores-177.md) · topologia rack
