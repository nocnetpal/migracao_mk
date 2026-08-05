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
> renomes ether6–10 no RB3011 e portas do RB750 (`RB750-WIREGUARD`, 2026-07-27).
>
> ⚠️ **Virada Etapa 1:** scripts/runbook prontos — **não aplicar agora** (usuário 2026-07-27).
> ✅ **Não mexer no bridge do RB750** (usuário 2026-07-27). HubSoft + Zabbix **fora** desta
> etapa no MK — ficam flat no 750 até CCR/Datacom. Etapa 1 no Mikrotik = **Docker + DNS** só.

## Mapa

| VLAN | Nome | Uso |
|------|------|-----|
| **100** | GERENCIA_SERVIDORES | **só** hypervisors Proxmox + VMs privadas |
| **16** | IP_PUBLICO | VMs/containers `177.72.104.x` + CCR `.4` depois — **nunca** o IP do Proxmox |

Cabo servidor → MK (e depois Datacom): trunk · native/untagged **100** · tagged **16**.

### Regra — IPs dos Proxmox ✅ fechada (2026-07-27)

> **Todo hypervisor Proxmox fica só com IP privado na VLAN 100.** Nenhum Proxmox mantém
> (nem ganha) IP no `/27` `177.72.104.0/27`. IP público/fixo fica **só nas VMs** (`tag=16`).

✅ **Subnet VLAN 100 fechada (usuário, 2026-07-27): `192.168.254.0/24` unificado.**
✅ **Bloco livre** — checagem ao vivo **NE8000** + **RB3011** (2026-07-27): sem address,
sem rota IP, sem OSPF, sem BGP. Evidências:
`config/ne8000/check-192.168.254-2026-07-27.txt` ·
`config/rb3011/check-192.168.254-2026-07-27.txt`.

| IP | Função |
|----|--------|
| `192.168.254.1/24` | GW (SVI no RB3011 `bridge-servidores`; depois NE8000) |
| `192.168.254.10` | Proxmox Zabbix (sai de `177.72.104.5`) |
| `192.168.254.11` | Proxmox Docker (sai de `192.168.116.122/30`) |
| `192.168.254.12` | Proxmox DNS (sai de `192.168.115.138/30`) |
| `192.168.254.13` | Proxmox HubSoft (sai de `192.168.115.210/30`) |

Os `/30` atuais de gerência **deixam de existir** após cada host migrar. Dude / allowlists /
bookmarks `8006` do `.5` atualizam para `.10`.

L2: `bridge-servidores` no RB3011 com **ether7 (Docker) + ether8 (DNS)**.
`ether10` / RB750 **não entra** nesta etapa (bridge do 750 intocado).

## Ordem

```
M1  Trunks 100+16 no RB3011 (ether7 + ether8 only)
M2  Proxmox Docker + DNS: gerência 192.168.254.x · VMs 177 na tag 16
M3  Validar
…   HubSoft + Zabbix: na troca pra CCR/Datacom (sem mexer no RB750 agora)
```

**Regra:** não aplicar `tag=16` no Proxmox **antes** do trunk no MK (HubSoft caiu assim).

## Sequência (quando for virar)

✅ **Usuário (2026-07-27):** não mexer no bridge do RB750 · HubSoft/Zabbix depois (CCR).

1. **Docker** — `00-bridge-servidores-base` → `docker-m1` → `docker-m2` (`.11`)
2. **DNS** — `dns-m1` → `dns-m2` (`.12`)
3. ~~HubSoft + Zabbix~~ — **adiado** até CCR/Datacom (scripts guardados, não usar)

## Preparação sem parada (já feito / falta)

- [x] Scripts em `scripts/noite-etapa1/`
- [x] Lista `qm-set-lista.md`
- [x] Subnet VLAN 100 = `192.168.254.0/24` (.1 GW · .10–.13 hosts)
- [x] Hypervisors **não** ficam com IP no `/27` (só VMs tag 16)
- [x] Export RB750 = `RB750-WIREGUARD` + RB2011
- [x] Mapa + renomes WIREGUARD
- [x] Conferir nome `ether10` RB3011 = `ether10 - RB750 Bridge` (2026-07-27)
- [x] Export RB3011 pre-noite colado/confirmado (14:54) — arrastar `.rsc` → `config/rb3011/` (META em `.META.md`)
- [x] Export `RB750-WIREGUARD` pre-noite (15:02) → `config/rb750gr3-wireguard/rb750-wireguard-pre-noite-2026-07-27.rsc`
- [x] SW_JDF: MACs Proxmox **não** aparecem (esperado — hosts no MK, não no SW) — `config/sw-jdf/mac-proxmox-check-2026-07-27.txt`
- [~] Dude `.5` → `.10` — **na virada** (noite HubSoft+Zabbix), não hoje
- [x] Aviso equipe — **pulado** (usuário, 2026-07-27): não teremos

## Progresso — 2026-08-05

**Fase 1A (base RB3011):** ✅ concluída — `bridge-servidores` + `vlan100-servidores` + `vlan16-servidores` criadas, `192.168.254.1/24` up.

**Fase 1B (trunk ether7):** ✅ concluída — `ether7` na `bridge-servidores`, PVID 100, VLAN 16 tagged. GATE `.122` + `.254.1` OK.

**Fase 1C (Proxmox Docker):** ✅ concluída — VLAN-aware ativo, `.11/24` em paralelo, tag 16 nas VMs 101/103-107, rede macvlan da VM 100 recriada com parent `ens2` (net7/tag16). Todos os containers 177 pingando (`.2` `.3` `.8` `.10` `.11` `.21`).

**Fase 1C-final:** ✅ concluída — default route virada para `.1`, IP velho `.122/30` removido, NAT VLAN 100 adicionado no RB3011 (`192.168.254.0/24` na address-list `NAT`). Internet OK (`ping 8.8.8.8`).

**NE8000:** ✅ validado — configuração atual salva em `config/ne8000/bgp_netpal-2026-08-05.txt`.

**Fase 2 (DNS):** ⏳ pendente.

Dumps: `config/rb3011/fase1b-*-2026-08-05.txt` · `config/proxmox-docker/fase1c-*-2026-08-05.txt` · `config/ne8000/bgp_netpal-2026-08-05.txt`

## Fora / later

- VMs órfãs detalhe fino (cabem na 100 se RFC1918)
- `10.1.1.2` Zabbix `enp3s0f1`
- QinQ / POP / OLT

## Fontes

- Live Proxmox: `config/proxmox-*/live-network-2026-07-27.txt`
- Scripts: `scripts/noite-etapa1/`
- **Runbook madrugada (passo a passo):** [17-runbook-etapa1-madrugada.md](17-runbook-etapa1-madrugada.md)
- SW_JDF: `display vlan 100/16` (2026-07-27)
- [15](15-plano-migracao-servidores-177.md) · topologia rack
