# DM4170 — inventário inicial (bancada)

> Coletado em 2026-08-07 via SSH na porta MGMT (estado pós-factory reset).
> Hostname atual: `DM4170` (default de fábrica).
> ⚠️ Atualizado para **DmOS 12.4.0-270** em 2026-08-07 — ver
> `atualizacao-firmware-12.4.0-2026-08-07.md`.

## show system (resumo)

- Clock: 2000-01-01 (sem NTP — relógio zerado, ainda não configurado)
- Uptime: ~24 min na coleta (último reboot: Power Failure)
- RAM: 1.91 GiB total, ~440 MiB usados

## show firmware

| Versão | Estado |
|---|---|
| ~~9.8.0-263-1-g759c968883~~ | ~~Active~~ → Inactive |
| **12.4.0-270-1-g57b3a30648** | **Active** (após update 2026-08-07) |

> ✅ Atualizado de 9.8.0 para **12.4.0** (portal Datacom, 2026-08-07). Hash conferido antes
> (md5 `b48fd9be...`, sha256 `879de6d2...`).

## show inventory (resumo)

- Chassis: 1 — Product model: DM4170
- Slot 1/1: **24GX+12XS** (Part 800.5186.51, serial **6502096**, rev 51, HW 0)
- Base MAC: 18:81:ed:1a:e8:ad
- Interfaces GE 1/1/1..1/1/24 (MACs ...ae..c5) e XE 1/1/1..1/1/12 (MACs ...c6..d1):
  todas `Transceiver — Presence: No` (nenhum SFP inserido em bancada)
- PSU 1/PSU1: PSU-125-DC (Part 800.5188.62, serial 6486287)

## Estado das portas

- Nenhum transceiver presente → todas as portas down em bancada (esperado)
