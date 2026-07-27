# Export RB3011 pre-noite — 2026-07-27 14:54:54

- RouterOS 6.49 · model RB3011UiAS · sn B88D0B6BA720 · identity GW Servidores
- Arquivo no equipamento: `gw-servidores-pre-noite-2026-07-27.rsc` (81.3KiB)
- Conteúdo colado no chat 2026-07-27 — **arrastar o .rsc do Desktop para esta pasta** para arquivo completo (lista BRASIL é grande).
- Credenciais no export (backup_ftp / dude API) — não copiar para docs.

## Conferência Etapa 1 (do paste)

| Item | Status |
|------|--------|
| `ether7 - Proxmox Docker CDNTV` | ok |
| `ether8 - Proxmox DNS` | ok |
| `ether10 - RB750 Bridge` | ok |
| ether7/8/10 em Bridge IP Publico | ok |
| GW Docker `192.168.116.121/30` | ok |
| GW DNS `192.168.115.137/30` | ok |
| GW HubSoft `192.168.115.209/30` | ok |
| `192.168.254.0/24` | ausente (livre) |
| VLAN 100 / bridge-servidores | ainda não existe |

Scripts M1 batem com estes nomes.
