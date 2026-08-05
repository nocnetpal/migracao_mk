# Lista consolidada de IPs — virada dos servidores

> Referência rápida para a janela de corte: servidores físicos a replugar no DM4170 + mapa
> completo do `177.72.104.0/27` e demais `177.72` relevantes ao rack.
>
> Fontes: [`config/topologia-fisica-rack.md`](../config/topologia-fisica-rack.md),
> [12-mapeamento-proxmox.md](12-mapeamento-proxmox.md),
> [07-enderecamento-ip.md](07-enderecamento-ip.md), decisão #2 em
> [03-decisoes-pendentes.md](03-decisoes-pendentes.md).
>
> Não inventa IP — o que não está confirmado fica marcado como **a confirmar**.

---

## 1. Servidores físicos a replugar no DM4170

Régua Volt (RB2011 p4) — **estragada, não migra**.

| # | Equipamento | IP(s) | Hoje pendura em | Notas |
|---|---|---|---|---|
| 1 | Proxmox Docker/CDNTV (Dell R420) | ✅ `192.168.254.11/24`, **VLAN 100** | RB3011 ether7 | Concluído 2026-08-05; VMs/containers na §1.1 |
| 2 | Proxmox DNS (HP 360 G7) | ✅ `192.168.254.12/24`, **VLAN 100** | RB3011 ether8 | Concluído 2026-08-05; VMs na §1.2 |
| 3 | Proxmox Zabbix/Zeus (HP DL360 G7) | **`177.72.104.5` → sai do `/27`** → VLAN 100 privado | RB750 p3 | Sem gerência privada hoje; VMs na §1.3 |
| 4 | Proxmox HubSoft (Dell R720) | `192.168.115.210/30` → alvo **VLAN 100** privado | RB750 p4 | VMs na §1.4 |

> ✅ **2026-07-27:** nenhum hypervisor fica com IP no `/27`. Subnet VLAN 100 fechada:
> **`192.168.254.0/24`** (`.1` GW · `.10` Zabbix · `.11` Docker · `.12` DNS · `.13` HubSoft) —
> [16](16-etapa1-proxmox-vlans-datacom.md).
| 5 | TS SIX | `192.168.66.14` | RB2011 p2 | Alvo DST-NAT `.1:15389` |
| 6 | Servidor Dude | `192.168.116.30` | RB2011 p5 | Alvo DST-NAT `.1:18291` |
| 7 | Servidor RRFlow | `177.72.104.27` | RB2011 p6 | RR FlowSpec + NetStream `:3055` |
| 8 | MGNT CGNAT-1 (Hillstone) | `177.72.104.66` (Dude) | RB2011 p3 | IP público CGNAT no NE8000; meio cobre/fibra **a confirmar** |
| 9 | Gerência NE8000 | **a confirmar** (porta de mgmt via RB750) | RB750 p2 | Lado OSPF do enlace: `192.168.116.33` + `177.72.104.54` em `Gi0/1/8.28` — não é necessariamente o IP da porta de gerência no RB750 |
| 10 | Gerência OLT CPV | `192.168.115.42/30` (plano CCR) | RB3011 ether9 | Gateway alvo NE8000 `192.168.115.41/30` |

### 1.1 Proxmox Docker/CDNTV — VMs e containers com IP

| Host/VM/container | IP | Tipo |
|---|---|---|
| **hypervisor** | ~~`192.168.116.122/30`~~ → ✅ `192.168.254.11/24` | gerência privada, VLAN 100 |
| OpenVPN2 | `177.72.104.12` (+ `10.254.0.30`) | VM pública |
| Fusion-Painel-Elaborados | `177.72.104.22` | VM pública |
| APP-ETC-SCRIPTS | `177.72.104.23` | VM pública |
| Fusion-Painel-Simples | `177.72.104.25` | VM pública |
| OPA.SUIT | `177.72.104.30` | VM pública |
| CdnTV-Origin | `177.72.104.107` | VM pública — **fora do `/27`** |
| CdnTV-Edge | `177.72.104.108` | VM pública — **fora do `/27`** |
| Docker-Netpal (interface) | `177.72.104.109` | VM — **fora do `/27`** |
| unifi-controller | `177.72.104.2` | container |
| Wiki | `177.72.104.3` | container |
| smokeping | `177.72.104.8` | container |
| pdns-master1 | `177.72.104.10` | container |
| pdns-slave | `177.72.104.11` | container |
| ~~DNS2-Recursivo-104.21~~ | `177.72.104.21` | ✅ removido intencionalmente em 2026-08-05; não migra |
| NTP_SERVER | `192.168.116.10` | container (origem NTP da rede) |
| SEVERINO | `192.168.15.74` | container (VLAN 18) |
| SpeedTest | `177.93.247.138` | container — bloco `177.93`, não `177.72` |

### 1.2 Proxmox DNS — VMs

| Host/VM | IP | Tipo |
|---|---|---|
| **hypervisor** | ~~`192.168.115.138/30`~~ → ✅ `192.168.254.12/24` | gerência privada, VLAN 100 |
| OLT-CLOUD | `177.72.104.24` | VM pública |
| API-ZAP | `177.72.104.26` | VM pública |
| NS-UNBOUND | `177.72.104.28/27` + `.58/32` + `.59/32` | VM pública (três IPs, um host; `.58`/`.59` secundários) |
| AUTOMACOES | `177.72.104.29` | VM pública |

### 1.3 Proxmox Zabbix — hypervisor + VMs

| Host/VM | IP | Tipo |
|---|---|---|
| **hypervisor** | `177.72.104.5` | público (sem gerência privada) |
| Zabbix | `177.72.104.6` | VM pública |
| Docs | `177.72.104.7` | VM pública |
| OVPN | `177.72.104.9` | VM pública |
| TIP-VOIP | `177.72.104.13` | VM pública |
| Fusionpbx-PM-CPV | `177.72.104.14` | VM pública |
| Fusionpbx-PM-MST | `177.72.104.17` | VM pública |
| Fusion-0800-Netpal | `177.72.104.18` | VM pública |
| SFTP-OPA-CHAT | `177.72.104.20` | VM pública |
| Dude-VLSul | `192.168.17.38` (+ `100.6.6.4`) | VM privada |
| Dude-PM-CPV | `192.168.17.42` | VM privada |
| Monsta | `192.168.115.62` | VM privada |

### 1.4 Proxmox HubSoft — VMs

| Host/VM | IP | Tipo |
|---|---|---|
| **hypervisor** | `192.168.115.210/30` | gerência privada |
| HUBSOFT | `177.72.104.16` | VM pública |
| HUBSOFT-RADIUS | `192.168.115.214` | VM privada |

### 1.5 Outros hosts `177.72` no escopo do rack (não Proxmox acima)

| Host | IP | Onde |
|---|---|---|
| VPN WireGuard | `177.72.104.19` | fora dos 4 clusters Proxmox mapeados — Dude; **a confirmar** física |
| RRFlow | `177.72.104.27` | servidor físico (§1 #7) |
| Storage BCP | `177.72.104.131` | backup FTP (RB3011 + NE8000) — **fora do `/27`** |
| CGNAT-1 Jardim Formoso | `177.72.104.66` | Dude / rotas NE8000 |
| CGNAT-2 Jardim Formoso | `177.72.104.102` | Dude / rotas NE8000 |

---

## 2. Mapa `177.72.104.0/27` (`.0`–`.31`)

Bloco dos servidores/serviços com IP público dedicado. Gateway L3 hoje: RB3011 `177.72.104.1`.
Pós-corte: dono do `/27` = **NE8000**; NAT SRC = **CCR1036** em `177.72.104.4`.

| IP | Status | Uso |
|---|---|---|
| `.0` | rede | prefixo `/27` |
| `.1` | gateway / NAT hoje | GW Servidores (SRC-NAT + DST-NAT Dude/TS SIX) → NE8000 assume o bloco |
| `.2` | ocupado | UniFi Controller (`docker-netpal`) |
| `.3` | ocupado | Wiki (`docker-netpal`) |
| `.4` | **livre → reservado** | NAT da CCR1036 (definido 2026-07-24) |
| `.5` | ocupado | hypervisor Proxmox Zabbix (+ regras Hubsoft legadas no firewall) |
| `.6` | ocupado | Zabbix |
| `.7` | ocupado | Docs / DOCS Cloud |
| `.8` | ocupado | Smokeping (`docker-netpal`) |
| `.9` | ocupado | OVPN / Servidor VPN (também next-hop `10.8.0.0/21`) |
| `.10` | ocupado | PowerDNS master (`docker-netpal`) |
| `.11` | ocupado | PowerDNS slave (`docker-netpal`) |
| `.12` | ocupado | OpenVPN-2 (também next-hop `10.254.0.0/22`) |
| `.13` | ocupado | TIP-VOIP |
| `.14` | ocupado | Fusionpbx-PM-CPV |
| `.15` | **livre** | único IP livre restante no `/27` (além do `.4` já reservado) |
| `.16` | ocupado | HubSoft |
| `.17` | ocupado | Fusionpbx-PM-MST |
| `.18` | ocupado | Fusion-0800-Netpal |
| `.19` | ocupado | VPN WireGuard (next-hop `10.30.0.0/30`, `10.150.150.0/24`) |
| `.20` | ocupado | SFTP-OPA-CHAT |
| `.21` | **desocupado** | ~~DNS2 Recursivo~~ removido intencionalmente em 2026-08-05; não recriar na migração |
| `.22` | ocupado | Fusion-Painel-Elaborados |
| `.23` | ocupado | APP-ETC-SCRIPTS |
| `.24` | ocupado | OLT-CLOUD |
| `.25` | ocupado | Fusion-Painel-Simples |
| `.26` | ocupado | API-ZAP |
| `.27` | ocupado | RRFlow (RR FlowSpec AS 52828 + NetStream `:3055`) |
| `.28` | ocupado | NS-UNBOUND (mesmo host que os loopbacks `.58` e `.59`) |
| `.29` | ocupado | AUTOMACOES |
| `.30` | ocupado | OPA.SUIT / Opa ChatBot |
| `.31` | broadcast | prefixo `/27` |

**Resumo `/27`:** 2 livres utilizáveis (`.4` reservado NAT, `.15` livre); o restante ocupado ou rede/broadcast.

---

## 3. Outros `177.72` relevantes (fora do `/27`, mas no corte)

Não é o `/21` BGP inteiro do NE8000 — só o que toca servidores/enlaces do trecho.

| IP / prefixo | Uso |
|---|---|
| `177.72.104.52/30` | Enlace P2P GW↔NE8000 (lado MK `.53`, lado NE `.54`) |
| `177.72.104.53` | Secundário no `sfp1` do RB3011 |
| `177.72.104.54` | NE8000 (`Gi0/1/8.28` sub + router-id / NetStream source) |
| `177.72.104.56/30` | Prefixo DNS (rota desabilitada no MK); filtro OSPF |
| `177.72.104.57` | Firewall accept — **sem ARP (2026-07-24), provável residual** |
| `177.72.104.58` | DNS loopback — mesmo host NS-UNBOUND que `.28` |
| `177.72.104.59` | ✅ DNS loopback `/32` — mesmo host NS-UNBOUND que `.28`/`.58`; confirmado em 2026-08-05 |
| `177.72.104.60/30` | Pantano⇒Juca Ana — migrou pro NE8000 (`.61`); órfão disabled no MK a limpar |
| `177.72.104.66` | CGNAT-1 Jardim Formoso |
| `177.72.104.102` | CGNAT-2 Jardim Formoso |
| `177.72.104.107` | CdnTV-Origin |
| `177.72.104.108` | CdnTV-Edge |
| `177.72.104.109` | Docker-Netpal (interface) |
| `177.72.104.131` | Storage BCP (backup FTP) |
| `177.72.105.217` | GW CC BCP / Escritório BCP (firewall) |
| `177.72.105.221` | Firewall accept — **sem ARP, provável residual** |

---

## Ver também

- [07-enderecamento-ip.md](07-enderecamento-ip.md) — detalhe e fontes de cada IP
- [12-mapeamento-proxmox.md](12-mapeamento-proxmox.md) — clusters Proxmox completos
- [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md) — plano de portas/VLANs da CCR1036
- [13-rotina-corte.md](13-rotina-corte.md) — runbook da janela
