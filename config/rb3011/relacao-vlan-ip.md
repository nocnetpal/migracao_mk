# Relação VLAN ↔ IP — RB3011 "GW Servidores"

> Cruzamento de `gw-servidores-vlans-portas-ppp-ovpn-ospf.txt` (60 interfaces VLAN) com
> `gw-servidores-ip-address-pool-dhcp-l2tp.txt` (`/ip address print`, ~100 endereços).
> Fonte primária — não editar à mão sem reconferir nos dumps.

## 1. Infra / uplink / loopback

| Interface | IP | Descrição |
|---|---|---|
| loopback | `172.16.200.5/32` | LOOPBACK (router-id OSPF) |
| sfp1 (uplink SW topo rack) | `192.168.116.34/30` | GERENCIA LOCAL (adjacência OSPF NE8000) |
| sfp1 (uplink SW topo rack) | `177.72.104.53/30` | GERENCIA HUAWEI (secundário, mesmo enlace) |
| Bridge IP Publico | `177.72.104.1/27` | IP PUBLICO — o bloco /27 inteiro |

## 2. Portas físicas (servidores locais em cobre)

> ⚠️ **Nomes corrigidos pela topologia física do usuário (2026-07-24)** — os comentários do MK
> estavam errados em vários pontos. Ver [`config/topologia-fisica-rack.md`](../topologia-fisica-rack.md).
> Os servidores passam por **2 bridges intermediárias** (RB2011 no `ether6`, RB750 no `ether10`),
> não plugam direto.

| Porta | IP | Nome no MK (comment) | Nome CERTO (usuário) |
|---|---|---|---|
| ether1 | `192.168.115.101/30` | REGUA VOLT | Régua Volt — ⚠️ marcada ESTRAGADA no MK |
| **ether6** | `192.168.66.1/28` | ~~"PC TS SIX"~~ | **RB BRIDGE SERVIDORES (RB2011)** — TS SIX/Dude/RRFlow/CGNAT-1 mgmt ficam atrás dele |
| ether7 | `192.168.123.13/30` | Proxmox DOCKER/CDNTV | PROXMOX DOCKER/CDNTV (DELL R420) ✅ |
| **ether8** | via VLAN10 | ~~"SERVIDOR DNS RECURSIVO"~~ | **PROXMOX DNS** (HP 360 G7) — o DNS recursivo é serviço nele |
| ether9 | `192.168.115.41/30` | ~~"GERENCIA OLT ZTE"~~ | GERENCIA OLT CPV MGNT |
| **ether10** | (bridge) | ~~"Callcenter"/"PROXMOX ZABBIX"~~ | **RB BRIDGE 750 (RB750)** — NE8000 mgmt + Zabbix + HubSoft ficam atrás dele |

## 3. Gerências de servidor local — na "Bridge IP Publico" (balde 3 / privado)

> Estes são os `/30` de gerência privada dos servidores locais que hoje convivem no mesmo domínio
> L2 da bridge pública. É a matéria-prima da VLAN privada nova (re-IP pra `/24` único).

| IP | Servidor |
|---|---|
| `192.168.116.29/30` | THE DUDE |
| `192.168.116.17/30` | LIBRENMS |
| `192.168.116.37/30` | WIKI 2 |
| `192.168.116.45/30` | WIKI |
| `192.168.116.21/30` | RB BRIDGE SERVIDORES (RB2011) |
| `192.168.116.5/30` | PROXMOX PNETLAB |
| `192.168.116.25/30` | ROTEADOR PRINCIPAL PNETLAB |
| `192.168.116.121/30` | PROXMOX DOCKER - CDNTV |
| `192.168.115.209/30` | PROXMOX HUB (HubSoft) |
| `192.168.115.213/30` | RADIUS HUBSOFT |
| `192.168.115.21/30` | PROXMOX VOIP |
| `192.168.115.137/30` | PROXMOX DNS |
| `192.168.115.61/30` | MONSTA |
| `192.168.115.97/30` | TS CALLCENTER |
| `192.168.123.21/30` | SERVIDOR VOIP BCP BACKUP |
| `192.168.123.1/30` | DNS BACKUP |
| `192.168.123.9/30` | SERVIDOR GRAYLOG |
| `192.168.17.37/30` | DUDE VLSUL |
| `192.168.17.41/30` | DUDE PMCPV |
| `192.168.17.45/30` | DUDE PMMST |
| `10.200.255.249/30` | DNS NOVO — ⚠️ **disabled (X)** no MK |

## 4. VLANs simples de serviço (tagged na sfp1 / ether8)

| VLAN | IP | Descrição |
|---|---|---|
| 10 (ether8) | `10.200.255.253/30` | SERVIDOR DNS RECURSIVO |
| 15 (NTP SERVER) | `192.168.116.9/30` | GERENCIA NTP SERVE |
| 16 (IP PUBLICO) | `177.72.104.1/27` (via bridge) | braço público |
| 18 (SERVERINO) | `192.168.15.73/30` | MONSTA |
| 1066 (GERADOR MST) | `192.168.90.1/24` | único DHCP vivo (`192.168.90.2-254`) |
| 11 (VLAN11_eoip) | `192.168.15.49/30` | GERENCIA SW DATACOM — ⚠️ EoIP morto |

## 5. VLANs de acesso (QinQ) — VLAN → sub-redes de gerência/enlace

| VLAN | Nome | IP(s) |
|---|---|---|
| 21 | OLT ZTE GGV | `192.168.115.125/30` |
| 22 | PWW | `192.168.115.9/30` |
| 27 | SW FO Shopping | `192.168.115.241/30` |
| 30 | Gerencia Radios CPV | `192.168.15.93/30` · `192.168.6.1/24` |
| 35 | FSB | `192.168.23.89/29` |
| 35 (ger. OLT FSB) | GERENCIA OLT FSB | `192.168.115.53/30` |
| 37 | OLT BCP | `192.168.115.225/30` |
| 39 | LBCP | `192.168.15.61/30` · `192.168.115.229/30` · `192.168.22.49/28` |
| 40 | PSLD | `192.168.15.29/30` · `192.168.115.233/30` · `192.168.115.245/30` |
| 41 | CCB | `192.168.115.237/30` |
| 42 | CASCA | `192.168.115.17/30` |
| 43 | MST | `192.168.115.169/30` |
| 44 | SLD | `192.168.15.81/30` · `192.168.115.105/30` |
| 46 | TVR | `192.168.116.197/30` |
| 47 | PRAIA MST | `192.168.15.45/30` · `192.168.115.173/30` · `172.31.254.29/30` |
| 48 | PRAIA SAO SIMAO | `192.168.15.53/30` · `192.168.115.181/30` |
| 49 | Clientes IP Publico MST | `192.168.115.81/30` |
| 50 | GERENCIA TVR | `192.168.15.253/30` |
| 52 | Clientes IP Publico PWW | `192.168.15.85/30` · `192.168.15.89/30` · `192.168.115.65/30` · `192.168.115.141/30` · `192.168.116.209/28` |
| 54 | Marcos Solon | `192.168.116.149/30` · `192.168.116.153/30` |
| 90 | RB Bridge Consepro PWW | `192.168.115.205/30` |
| 93 | GERENCIA POP JDF / Enlace Rancho Velho | `192.168.31.49/29` · `192.168.22.1/27` · `192.168.30.25/29` · `192.168.116.177/29` |
| 196 | RB Banco do Brasil CPV | `192.168.115.85/30` |
| ~~198~~ | ~~Pantano => Juca Ana~~ | ✅ **REMOVIDA do RB (2026-07-24)** — interface VLAN + OSPF network/interface já apagados; migrou pro NE8000 (`Gi0/1/8.198`). ⚠️ Resta remover o `/ip address 177.72.104.61/30 disabled=yes` órfão |
| 200 | RB Bridge Predio Maicon | `192.168.116.113/29` · `192.168.115.5/30` |
| 539 | GERENCIA OLT LBCP | `192.168.115.177/30` |
| 600 | AP Centro TVR Rei dos Pampas | `192.168.16.1/27` |
| 708 | MK POP Serraria | `192.168.17.17/30` |
| 712 | MK POP Casca | `192.168.30.201/29` |
| 713 | GW SOLIDAO | `172.31.254.33/30` |
| 718 | MK POP Valim | `192.168.30.73/29` |
| 719 | MK POP Pantano | `192.168.17.9/30` |
| 720 | MK POP Povos | `192.168.17.5/30` |
| 721 | MK POP Faz. Cardoso | `192.168.30.81/29` |
| 731 | MK POP Cavalhada | `192.168.30.113/29` |
| 738 | MK POP Solidao 101 | `192.168.30.193/29` · `192.168.30.49/29` |
| 753 | MK POP Bacupari | `192.168.31.41/29` · `192.168.31.17/29` · `192.168.31.9/29` · `192.168.17.21/30` · `192.168.17.25/30` · `192.168.30.145/29` · `192.168.31.33/29` |
| 765 | Serraria => BCP | `192.168.30.161/29` |
| 775 | MK POP Aguape | `192.168.30.177/29` · `192.168.30.153/29` · `192.168.17.1/30` |
| 2020 | Gerencia EDD MST (TIM) | `192.168.116.157/30` |

## Notas

- **VLANs sem IP** (só transporte ou mortas): 13, 17, 25, 26, 31, 33, 51, 53, 92, 250, 742, 770,
  772 e as outer de site — ver classificação em [09](../../docs/09-l2-mapeamento-vlans.md).
- **`177.72.104.61/30` na VLAN198** é o único IP **público** fora da VLAN 16/bridge — 🆕
  **decidido (2026-07-24): remover do RB3011 e passar pro NE8000** (que já tinha `FTP client-source
  -a .61`, agora consistente). Decisão #10.
- Pools DHCP e L2TP no fim do arquivo-fonte (`...-ip-address-pool-dhcp-l2tp.txt`).
