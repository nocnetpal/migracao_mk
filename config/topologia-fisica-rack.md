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

> ✅ **Portas RB2011 confirmadas ao vivo em 2026-08-05:** `ether1` uplink, `ether2` TS SIX,
> `ether3` MGNT CGNAT-1, `ether4` Régua Volt, `ether5` Dude e `ether6` RRFlow. `ether7`–`ether10`
> estão sem link e livres. A `ether4` está `running` e aprende MAC mesmo com a Régua registrada
> como estragada; link ativo não confirma que a função da Régua esteja operacional.

🆕 **TERCEIRO Mikrotik: RB BRIDGE 750 = identity `WIREGUARD` (RB750Gr3, sn CC210F9A08D3)** —
confirmado 2026-07-27 por MAC + `bridge host`. Duplo papel: bridge L2 (NE8000 mgmt + Zabbix +
HubSoft, uplink `ether10` do RB3011) **e** concentrador VPN (WireGuard/OpenVPN) no
`177.72.104.19`. Export em `config/rb750gr3-wireguard/`. **Corrige a decisão #2**.

| Porta ROS | Nome alvo (renomear) | Destino |
|---|---|---|
| ether1 | `ether1 - LIVRE` | p1 livre (INACTIVE) |
| ether2 | `ether2 - NE8000 Gerencia` | p2 NE8000 gerência |
| ether3 | `ether3 - Proxmox Zabbix` | p3 cluster Zabbix (MACs confirmados) |
| ether4 | `ether4 - Proxmox HubSoft` | p4 HubSoft + Radius |
| ether5 | `ether5 - Uplink GW Servidores` | p5 uplink RB3011 ether10 + `.19/27` |

Script: `config/rb750gr3-wireguard/renomear-portas.rsc` (identity → `RB750-WIREGUARD`).

⚠️ **Os servidores NÃO plugam direto no RB3011** — a maioria passa por 2 bridges intermediárias:
- **RB2011** (no `ether6`): TS SIX, CGNAT-1 mgmt, Régua Volt, Dude, RRFlow
- **RB750** (no `ether10`): NE8000 gerência, Zabbix/Zeus, HubSoft

Isso **explica** o achado da decisão #12 (MACs de HubSoft e Zabbix aprendidos no mesmo `ether10`):
os dois estão atrás do RB750, que sobe pelo `ether10`.

## Cabeamento (cor do cabo → destino)

| Servidor (modelo/U) | Porta | Cabo | Vai para |
|---|---|---|---|
| DELL R720 2U — Proxmox HubSoft | p1 | amarelo | RB BRIDGE 750 p4 |
| DELL R420 1U — Proxmox Docker/CDNTV | `eno1` / p1 | vermelho | RB GW SERVIDORES (RB3011) p7 — gerência VLAN 100 nativa + VLAN 16 tagged |
| DELL R420 1U — Proxmox Docker/CDNTV | `enp8s0f0` / p? | a identificar | ✅ SW_JDF `XGE0/0/14`, access/untagged VLAN 23 — rede CDN `177.72.104.104/29` |
| HP DL360 G7 1U — Proxmox Zeus/Zabbix | p1 | verde | RB BRIDGE 750 p3 |
| HP 360 G7 1U — Proxmox DNS | p1 | verde | RB GW SERVIDORES (RB3011) p8 |
| Servidor RRFLOW | p1 | azul | RB BRIDGE SERVIDORES (RB2011) p6 |
| Servidor DUDE 3U | p1 | amarelo | RB BRIDGE SERVIDORES (RB2011) p5 |
| Servidor TS SIX 3U | p1 | verde | RB BRIDGE SERVIDORES (RB2011) p2 |

> 🆕 **Correção 2026-08-05:** o Dell R420 possui pelo menos dois enlaces de produção. Não mover
> apenas o cabo vermelho e assumir que todo o CDNTV está nas VLANs 100/16. As VMs 101/102 e a
> interface `.109` da VM 100 usam o segundo enlace `enp8s0f0` pela `vmbr2`, sem tag no host. Antes
> de configurar o DM4170 ou recabear, **preservar o segundo cabo no SW_JDF `XGE0/0/14`**, que
> aprende os MACs `2A:B7:2D:D8:6E:A2`, `5E:68:F6:70:6E:0D` e `C6:8F:DA:94:E0:6D` na VLAN 23.
> O uplink ativo da VLAN 23 é `SW_JDF XGE0/0/1` tagged até o NE8000 `Gi0/1/8.23`.

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
