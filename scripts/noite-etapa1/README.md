# Scripts noite — Etapa 1 (VLAN 100 + 16) — NÃO APLICAR agora

> Zero parada em horário comercial.
> Modelo: native/untagged **100** · tagged **16**.
>
> ✅ **Não mexer no bridge do RB750** (usuário 2026-07-27).
> Escopo MK agora: **Docker + DNS** só. HubSoft/Zabbix → CCR/Datacom depois.

## Pré-noite

- [x] Export `RB750-WIREGUARD` pre-noite 2026-07-27
- [x] Nome `ether10` RB3011 = `ether10 - RB750 Bridge` (2026-07-27)
- [x] SW_JDF: anotar portas (opcional) — N/A p/ Proxmox (MACs no MK)
- [x] Subnet `192.168.254.0/24` fechada
- [x] Aviso equipe — pulado (não teremos)
- [x] Não mexer bridge RB750 — HubSoft/Zabbix adiados
- [~] Dude `.5` → `.10` — na virada do Zabbix (CCR), não nesta etapa

## Quando virar (Docker + DNS)

| # | Bloco | Ordem dos arquivos |
|---|--------|-------------------|
| 1 | Base + **Docker** | `00-bridge-servidores-base.rsc` → `docker-m1-rb3011.rsc` → `docker-m2-proxmox.sh` |
| 2 | **DNS** | `dns-m1-rb3011.rsc` → `dns-m2-proxmox.sh` |
| — | ~~HubSoft+Zabbix~~ | **não usar** — guardado em `hubsoft-zabbix-*` |

Por bloco: M1 → ping → M2 (IP paralelo + tags) → validar → remover IP velho → senão rollback **daquele** bloco.

## Arquivos

| Host | M1 | M2 | Rollback |
|------|----|----|----------|
| (base) | `00-bridge-servidores-base.rsc` | — | — |
| Docker | `docker-m1-rb3011.rsc` | `docker-m2-proxmox.sh` | `docker-rollback.rsc` |
| DNS | `dns-m1-rb3011.rsc` | `dns-m2-proxmox.sh` | `dns-rollback.rsc` |
| HubSoft+Zabbix | `hubsoft-zabbix-*` | **ADIADO** (CCR) | — |

Lista VMs: `qm-set-lista.md`  
Docs: `docs/16-etapa1-proxmox-vlans-datacom.md` · **runbook:** `docs/17-runbook-etapa1-madrugada.md`
