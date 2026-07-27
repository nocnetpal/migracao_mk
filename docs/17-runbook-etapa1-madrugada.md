# Runbook Etapa 1 — comandos da madrugada (4 Proxmox)

> Colar na ordem. Comentários explicam o que cada bloco faz.
> Se algo falhar no meio: use a seção **ROLLBACK** do bloco e **pare**.
> Scripts espelho: `scripts/noite-etapa1/`

**IPs alvo:** `.1` GW · `.10` Zabbix · `.11` Docker · `.12` DNS · `.13` HubSoft  
**VLANs:** 100 = gerência (native) · 16 = público (tagged)  
**Regra:** nunca `tag=16` no Proxmox antes do trunk no Mikrotik.

---

# BLOCO 1 — Docker (começa aqui)

## 1A) RB3011 — cria bridge-servidores + GW 192.168.254.1

```rsc
# Cria a bridge VLAN-aware que vai receber ether7/8/10
/interface bridge add name=bridge-servidores vlan-filtering=yes protocol-mode=none \
  comment="Etapa1 VLAN100 gerencia + VLAN16 publico"

# SVI privada (gerencia dos Proxmox)
/interface vlan add name=vlan100-servidores vlan-id=100 interface=bridge-servidores \
  comment="GERENCIA SERVIDORES 192.168.254.0/24"

# SVI publica tagged — joga no Bridge IP Publico (mesmo L2 do /27)
/interface vlan add name=vlan16-servidores vlan-id=16 interface=bridge-servidores \
  comment="IP PUBLICO tagged dos servidores"

/ip address add address=192.168.254.1/24 interface=vlan100-servidores \
  comment="GW VLAN100 hypervisors"

/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 tagged=bridge-servidores
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 tagged=bridge-servidores
/interface bridge port add bridge="Bridge IP Publico" interface=vlan16-servidores

# Conferir: tem que aparecer .1/24
/ip address print where address~"192.168.254.1"
/ping 192.168.254.1 count=2
```

## 1B) RB3011 — ether7 Docker entra no trunk 100+16

```rsc
# Tira ether7 da Bridge IP Publico (flat) e mete na bridge-servidores
/interface bridge port remove [find interface="ether7 - Proxmox Docker CDNTV"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether7 - Proxmox Docker CDNTV" pvid=100

# Native 100 + tagged 16 no cabo do Docker
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  untagged="ether7 - Proxmox Docker CDNTV"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether7 - Proxmox Docker CDNTV"

# Mantem GW /30 antigo na vlan100 ate o host migrar pro .11
:do {
  /ip address set [find address="192.168.116.121/30"] interface=vlan100-servidores
} on-error={}

# TEM que pingar o Docker antigo — se nao pingar, ROLLBACK Docker
/ping 192.168.116.122 count=5
/ping 192.168.254.1 count=2
```

## 1C) Proxmox Docker — IP .11 + tag 16 nas VMs

```bash
# No host proxmoxDockerCDNTV (gerencia hoje em vmbr1)

# --- VLAN-aware no vmbr1 (editar /etc/network/interfaces) ---
# No bloco iface vmbr1 inet static, acrescentar:
#   bridge-vlan-aware yes
#   bridge-vids 2-4094
# Depois:
ifreload -a
cat /sys/class/net/vmbr1/bridge/vlan_filtering
# esperado: 1

# --- IP novo EM PARALELO (manter 192.168.116.122 ate validar) ---
# Em /etc/network/interfaces no vmbr1 (ou secondary):
#   address 192.168.254.11/24
#   gateway 192.168.254.1
ifreload -a
ping -c 3 192.168.254.1
# Abrir GUI: https://192.168.254.11:8006

# --- Tag 16 nas VMs publicas (vmbr1) ---
qm set 103 -net0 e1000,bridge=vmbr1,tag=16,firewall=1,macaddr=F6:C7:5C:8A:4A:A3
qm set 104 -net0 virtio,bridge=vmbr1,tag=16,firewall=0,macaddr=6E:26:1A:C9:19:CE
qm set 105 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=62:B2:A1:0A:B1:AE
qm set 106 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=0E:C8:34:76:59:4E
qm set 107 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=36:DC:89:9D:DA:5A
qm set 101 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,queues=8,macaddr=2A:B7:2D:D8:6E:A2
# Docker-Netpal macvlan 177: parent com tag 16 (ajustar na VM)
# NAO mexer net5/net6 (tags 18/38)

ping -c 3 177.72.104.12

# Se tudo OK: remover 192.168.116.122 do vmbr1 e deixar so .11
# ifreload -a
```

### ROLLBACK Docker (RB3011) — se 1B/1C der ruim

```rsc
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 untagged~"ether7"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether7"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether7"]
:do {
  /ip address set [find address="192.168.116.121/30"] interface="Bridge IP Publico"
} on-error={}
/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether7 - Proxmox Docker CDNTV" hw=yes
/ping 192.168.116.122 count=5
```

---

# BLOCO 2 — HubSoft + Zabbix (juntos)

## 2A) RB750-WIREGUARD — trunk 100+16 + move .19 para vlan16

```rsc
# Impacto: HubSoft + Zabbix + NE8000 mgmt + VPN .19 no mesmo bridge

# VLAN 16 para o IP publico .19 (antes de filtrar)
/interface vlan add name=vlan16-wg vlan-id=16 interface="bridge1 - Servidores" \
  comment="IP PUBLICO .19 WireGuard"
/interface vlan add name=vlan100-wg vlan-id=100 interface="bridge1 - Servidores" \
  comment="GERENCIA (L2 only; GW fica no RB3011 .1)"

# Move .19 do ether5 para a vlan16
/ip address set [find address="177.72.104.19/27"] interface=vlan16-wg

/interface bridge set [find name="bridge1 - Servidores"] vlan-filtering=yes

/interface bridge port
set [find interface="ether1 - LIVRE"] pvid=100
set [find interface="ether2 - NE8000 Gerencia"] pvid=100
set [find interface="ether3 - Proxmox Zabbix"] pvid=100
set [find interface="ether4 - Proxmox HubSoft"] pvid=100
set [find interface="ether5 - Uplink GW Servidores"] pvid=100

# ether3/4: native 100 + tagged 16 | ether5: tagged 100+16 (uplink)
/interface bridge vlan
add bridge="bridge1 - Servidores" vlan-ids=100 \
  untagged="ether1 - LIVRE","ether2 - NE8000 Gerencia","ether3 - Proxmox Zabbix","ether4 - Proxmox HubSoft" \
  tagged="ether5 - Uplink GW Servidores","bridge1 - Servidores"
add bridge="bridge1 - Servidores" vlan-ids=16 \
  tagged="ether3 - Proxmox Zabbix","ether4 - Proxmox HubSoft","ether5 - Uplink GW Servidores","bridge1 - Servidores"

# Conferir VPN / default
/ip address print where address~"177.72.104.19"
/ping 177.72.104.1 count=5
```

## 2B) RB3011 — ether10 (RB750) entra no trunk

```rsc
/interface bridge port remove [find interface~"ether10"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether10 - RB750 Bridge" pvid=1

# Uplink so tagged (sem untagged util)
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  tagged="ether10 - RB750 Bridge"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether10 - RB750 Bridge"

# /30 HubSoft antigo, se existir, vai pra vlan100
:do {
  /ip address set [find address="192.168.115.209/30"] interface=vlan100-servidores
} on-error={}

# Tem que continuar pingando HubSoft e Zabbix antigos
/ping 192.168.254.1 count=2
/ping 177.72.104.19 count=5
/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
```

## 2C) Proxmox HubSoft — IP .13 + tag 16

```bash
# Host px-hubsoft — vlan-aware no vmbr0 ja deve ser 1
cat /sys/class/net/vmbr0/bridge/vlan_filtering

# IP paralelo 192.168.254.13/24 GW .1 (manter .210 ate validar)
# Editar /etc/network/interfaces + ifreload -a
ping -c 3 192.168.254.1
# GUI: https://192.168.254.13:8006

# HubSoft publico
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,macaddr=72:56:05:A7:29:E9
# Radius 101: SEM tag 16 (fica native VLAN 100)

ping -c 3 177.72.104.16
# OK -> remover 192.168.115.210
```

## 2D) Proxmox Zabbix — IP .10 + tag 16 + tira .5

```bash
# Host proxmox3 — hoje 177.72.104.5/27 no vmbr0

# VLAN-aware vmbr0 (editar interfaces):
#   bridge-vlan-aware yes
#   bridge-vids 2-4094
ifreload -a

# IP paralelo 192.168.254.10/24 GW .1 — MANTER .5 ate validar
ping -c 3 192.168.254.1
# GUI: https://192.168.254.10:8006

# Dude: trocar device 177.72.104.5 -> 192.168.254.10

# VMs publicas tag 16
qm set 110 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=4E:01:6C:C9:F0:78
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=B2:63:2D:95:56:FD
qm set 107 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=56:EC:57:EB:68:14
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=8A:26:35:E8:3A:BF
qm set 104 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=EE:2A:8A:5A:EE:E0
qm set 106 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=1A:97:C3:E0:DC:D3
qm set 108 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=16:8C:EF:D4:03:FD
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=F2:19:E1:4A:8C:8A
# 100/101/109: sem tag 16 (privadas / later)

ping -c 3 177.72.104.6

# OK -> REMOVER 177.72.104.5 do vmbr0 (hypervisor sai do /27)
```

### ROLLBACK HubSoft+Zabbix — RB750 depois RB3011

```rsc
# --- No RB750-WIREGUARD ---
/interface bridge set [find name="bridge1 - Servidores"] vlan-filtering=no
/interface bridge vlan remove [find bridge="bridge1 - Servidores"]
/ip address set [find address="177.72.104.19/27"] interface="ether5 - Uplink GW Servidores"
/interface vlan remove [find name=vlan16-wg]
/interface vlan remove [find name=vlan100-wg]
/ping 177.72.104.1 count=5

# --- No RB3011 ---
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 tagged~"ether10"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether10"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether10"]
:do {
  /ip address set [find address="192.168.115.209/30"] interface="Bridge IP Publico"
} on-error={}
/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether10 - RB750 Bridge" hw=yes
/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
/ping 177.72.104.19 count=3
```

---

# BLOCO 3 — DNS

## 3A) RB3011 — ether8 DNS no trunk

```rsc
/interface bridge port remove [find interface="ether8 - Proxmox DNS"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether8 - Proxmox DNS" pvid=100
/interface bridge vlan add bridge=bridge-servidores vlan-ids=100 \
  untagged="ether8 - Proxmox DNS"
/interface bridge vlan add bridge=bridge-servidores vlan-ids=16 \
  tagged="ether8 - Proxmox DNS"

:do {
  /ip address set [find address="192.168.115.137/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.115.138 count=5
/ping 192.168.254.1 count=2
```

## 3B) Proxmox DNS — IP .12 + tag 16

```bash
# Host proxmox-dns

# VLAN-aware vmbr0 + ifreload -a
# IP paralelo 192.168.254.12/24 GW .1 (manter .138 ate validar)
ping -c 3 192.168.254.1
# GUI: https://192.168.254.12:8006

qm set 101 -net0 e1000e,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:89:AD:23
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:50:14:F9
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:BF:0B:B5
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:E7:B0:75

ping -c 3 177.72.104.28
# OK -> remover 192.168.115.138
```

### ROLLBACK DNS (RB3011)

```rsc
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=100 untagged~"ether8"]
/interface bridge vlan remove [find bridge=bridge-servidores vlan-ids=16 tagged~"ether8"]
/interface bridge port remove [find bridge=bridge-servidores interface~"ether8"]
:do {
  /ip address set [find address="192.168.115.137/30"] interface="Bridge IP Publico"
} on-error={}
/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether8 - Proxmox DNS" hw=yes
/ping 192.168.115.138 count=5
```

---

# Depois dos 4

```rsc
# No RB3011 — conferência final
/ping 192.168.254.1 count=2
/ping 192.168.254.10 count=3
/ping 192.168.254.11 count=3
/ping 192.168.254.12 count=3
/ping 192.168.254.13 count=3
/ping 177.72.104.16 count=2
/ping 177.72.104.28 count=2
/ping 177.72.104.6 count=2
/ping 177.72.104.19 count=2

/export file=gw-servidores-pos-etapa1
```

```rsc
# No RB750-WIREGUARD
/export file=rb750-pos-etapa1
```

---

# Fora desta etapa (não fazer agora)

```
# Datacom / CCR / troca de cabo / QinQ / POP / OLT / virada L3 do /27
```
