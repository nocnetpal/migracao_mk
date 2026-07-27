# Scripts noite — Etapa 1 (VLAN 100 + 16) — NÃO APLICAR agora

> Zero parada em horário comercial. Colar no equipamento **só na madrugada**, host a host.
> Modelo: native/untagged **100** · tagged **16**.
> Hypervisors: **`192.168.254.0/24`** (`.1` GW · `.10` Zabbix · `.11` Docker · `.12` DNS · `.13` HubSoft).
> VMs `177.x` = `tag=16`.

## Pré-noite

- [x] Export `RB750-WIREGUARD` pre-noite 2026-07-27
- [x] Nome `ether10` RB3011 = `ether10 - RB750 Bridge` (2026-07-27)
- [x] SW_JDF: anotar portas (opcional) — N/A p/ Proxmox (MACs no MK)
- [x] Subnet `192.168.254.0/24` fechada
- [x] Aviso equipe — pulado (não teremos)
- [~] Dude `.5` → `.10` — **na virada**, não hoje

## Janela única — 4 servidores (usuário, 2026-07-27)

| # | Bloco | Ordem dos arquivos |
|---|--------|-------------------|
| 1 | Base + **Docker** | `00-bridge-servidores-base.rsc` → `docker-m1-rb3011.rsc` → `docker-m2-proxmox.sh` |
| 2 | **HubSoft + Zabbix** | `hubsoft-zabbix-m1-rb750-rb3011.rsc` → `hubsoft-m2` → `zabbix-m2` (+ Dude `.5`→`.10`) |
| 3 | **DNS** | `dns-m1-rb3011.rsc` → `dns-m2-proxmox.sh` |

Por bloco: M1 → ping → M2 (IP paralelo + tags) → validar → remover IP velho → senão rollback **daquele** bloco.

## Arquivos

| Host | M1 | M2 | Rollback |
|------|----|----|----------|
| (base) | `00-bridge-servidores-base.rsc` | — | — |
| Docker | `docker-m1-rb3011.rsc` | `docker-m2-proxmox.sh` | `docker-rollback.rsc` |
| HubSoft+Zabbix | `hubsoft-zabbix-m1-rb750-rb3011.rsc` | `hubsoft-m2-proxmox.sh` + `zabbix-m2-proxmox.sh` | `hubsoft-zabbix-rollback.rsc` |
| DNS | `dns-m1-rb3011.rsc` | `dns-m2-proxmox.sh` | `dns-rollback.rsc` |

Lista VMs: `qm-set-lista.md`  
Docs: `docs/16-etapa1-proxmox-vlans-datacom.md` · **runbook:** `docs/17-runbook-etapa1-madrugada.md`

## Placeholders antigos

`hubsoft-m1-rb750-rb3011.rsc` e `zabbix-m1-rb750-rb3011.rsc` → substituídos pelo M1 combinado.
