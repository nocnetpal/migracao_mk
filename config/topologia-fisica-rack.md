# Topologia física do rack — GW Servidores (fonte autoritativa do usuário, 2026-07-24)

> Lista de portas e cabeamento fornecida pelo usuário. **Substitui os nomes dos comentários do
> RB3011** (que estavam errados/desatualizados em vários pontos). Fonte primária de topologia física.

## Cadeia de bridges (quem conecta em quem)

```
RB GW SERVIDORES (RB3011)
├── ether6  → RB BRIDGE SERVIDORES (RB2011)   ⚠️ comment do MK dizia "PC TS SIX" (errado)
│              ├── p1 ETHER6 GW SERVIDORES (uplink de volta pro RB3011 ether6)
│              ├── p2 TS SIX
│              ├── p3 MGNT CGNAT-1
│              ├── p4 REGUA VOLTA 110/220V
│              ├── p5 SERVIDOR DUDE
│              └── p6 SERVIDOR RRFLOW
├── ether7  → PROXMOX DOCKER/CDNTV  (DELL R420 1U, cabo vermelho)   ✅ batia
├── ether8  → PROXMOX DNS  (HP 360 G7 1U, cabo verde)   ⚠️ comment dizia "SERVIDOR DNS RECURSIVO"
├── ether9  → GERENCIA OLT CPV MGNT   ⚠️ comment dizia "GERENCIA OLT ZTE"
└── ether10 → RB BRIDGE 750 (RB750)   ⚠️ comment dizia "Callcenter"/"PROXMOX ZABBIX" (errado)
               ├── p1 LIVRE
               ├── p2 ROTEADOR HUAWEI NE8000 - GERENCIA
               ├── p3 PROXMOX ZABBIX/ZEUS  (HP DL360 G7 1U, cabo verde)
               ├── p4 PROXMOX HUBSOFT  (DELL R720 2U, cabo amarelo)
               └── p5 GW SERVIDORES PORTA 10 (uplink de volta pro RB3011 ether10)
```

🆕 **TERCEIRO Mikrotik descoberto: RB BRIDGE 750 (RB750)** — não estava inventariado. Bridge L2 que
agrega gerência do NE8000 + Proxmox Zabbix + Proxmox HubSoft, com uplink no `ether10` do RB3011.
**Corrige a decisão #2** (que dava só RB3011 + RB2011 como os MKs do trecho).

⚠️ **Os servidores NÃO plugam direto no RB3011** — a maioria passa por 2 bridges intermediárias:
- **RB2011** (no `ether6`): TS SIX, CGNAT-1 mgmt, Régua Volt, Dude, RRFlow
- **RB750** (no `ether10`): NE8000 gerência, Zabbix/Zeus, HubSoft

Isso **explica** o achado da decisão #12 (MACs de HubSoft e Zabbix aprendidos no mesmo `ether10`):
os dois estão atrás do RB750, que sobe pelo `ether10`.

## Cabeamento (cor do cabo → destino)

| Servidor (modelo/U) | Porta | Cabo | Vai para |
|---|---|---|---|
| DELL R720 2U — Proxmox HubSoft | p1 | amarelo | RB BRIDGE 750 p4 |
| DELL R420 1U — Proxmox Docker/CDNTV | p1 | vermelho | RB GW SERVIDORES (RB3011) p7 |
| HP DL360 G7 1U — Proxmox Zeus/Zabbix | p1 | verde | RB BRIDGE 750 p3 |
| HP 360 G7 1U — Proxmox DNS | p1 | verde | RB GW SERVIDORES (RB3011) p8 |
| Servidor RRFLOW | p1 | azul | RB BRIDGE SERVIDORES (RB2011) p6 |
| Servidor DUDE 3U | p1 | amarelo | RB BRIDGE SERVIDORES (RB2011) p5 |
| Servidor TS SIX 3U | p1 | verde | RB BRIDGE SERVIDORES (RB2011) p2 |

## Layout do rack (44U)

| U | Equipamento |
|---|---|
| 43U | **RB GW SERVIDORES - 3011** |
| 41U | **RB BRIDGE SERVIDORES - 2011** |
| 40U | **RB BRIDGE 750** |
| 38–37U | DELL R720 — Proxmox HubSoft |
| 35U | DELL R420 — Proxmox Docker/CDNTV |
| 33U | HP DL360 G7 — Proxmox Zabbix/Zeus |
| 31–30U | DELL R240 EMC — GGC1 / GGC2 (Google Global Cache) |
| 28–27U | HILLSTONE SG600 / S5760P — **CGNAT-1** |
| 25–23U | Servidor DUDE |
| 21–19U | Servidor TS SIX |
| 17U | HP 360 G7 — Proxmox DNS |
| 15–14U | Servidor RRFLOW |
| 12–11U | HILLSTONE SG600 / S5760P — **CGNAT-2** |
| demais | LIVRE |

🆕 **Equipamentos novos identificados no rack** (não estavam nos docs):
- **CGNAT = Hillstone SG600 / S5760P** (2 unidades CGNAT-1 + 2 unidades CGNAT-2)
- **GGC1/GGC2 = Dell R240 EMC** (Google Global Cache)
- Modelos exatos dos hosts Proxmox (R720 HubSoft, R420 Docker, DL360 G7 Zabbix, 360 G7 DNS)
