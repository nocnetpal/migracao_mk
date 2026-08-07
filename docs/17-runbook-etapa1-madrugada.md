# Runbook Etapa 1 — comandos da madrugada

> Colar na ordem. Comentários explicam o que cada bloco faz.
> Se algo falhar no meio: use a seção **ROLLBACK** do bloco e **pare**.
> Scripts espelho: `scripts/noite-etapa1/`
>
> ⚠️ **Não aplicar agora (usuário, 2026-07-27):** só preparar.
>
> ✅ **Decisão (usuário, 2026-07-27):** **não mexer no bridge do RB750-WIREGUARD.**
> HubSoft + Zabbix ficam **fora** desta etapa no MK — ~~migram quando o 750 sair e for
> pra **CCR/Datacom**~~ → ✅ **concluído em 2026-08-05** via switch temporário/segundo cabo
> ([16](16-etapa1-proxmox-vlans-datacom.md)); o **RB750 permanece** (WireGuard `.19`) até a VPN
> migrar pós-corte (2026-08-06). Etapa 1 no Mikrotik = só **Docker (ether7)** + **DNS (ether8)**.

**IPs alvo nesta etapa:** `.1` GW · `.11` Docker · `.12` DNS  
**Depois (CCR):** `.10` Zabbix · `.13` HubSoft  
**VLANs:** 100 = gerência (native) · 16 = público (tagged)  
**Regra:** nunca `tag=16` no Proxmox antes do trunk no Mikrotik.

**Status em 2026-08-05:** ✅ Docker e DNS executados. Proxmox DNS concluído em
`192.168.254.12/24`, VMs 101/102/103/105 na tag 16 e Unbound `.28/.58/.59` respondendo
`NOERROR`. HubSoft/Zabbix continuam fora desta etapa. Captura no RB3011 comprovou que estender a
VLAN 100 pelo caminho flat do RB750 cria QinQ `16,100` ao cruzar o handoff VLAN 16 existente;
**não repetir os scripts antigos nem criar outro handoff entre as duas bridges**. Para o HubSoft,
há plano temporário ainda não executado: switch não gerenciável intercalado na `ether8`, DNS
validado primeiro e `eno2` do HubSoft como segundo cabo; `eno1` permanece na RB750 até concluir a
migração. O Zabbix pode usar o mesmo switch pela NIC 2 `enp3s0f1`, mantendo `enp3s0f0/.5` na
RB750; o IP órfão `10.1.1.2/24` já saiu do estado ao vivo, mas link, bridge e `.10/24` ainda
aguardam execução e validação.

---

# BLOCO 1 — Docker (começa aqui)

## 1A) RB3011 — cria bridge-servidores + GW 192.168.254.1

```rsc
# Cria a bridge VLAN-aware (ether7 Docker; depois ether8 DNS — SEM ether10/RB750)
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

# --- VLAN-aware no vmbr1 ---
# Editar /etc/network/interfaces — no bloco "iface vmbr1 inet static" acrescentar:
#   bridge-vlan-aware yes
#   bridge-vids 2-4094
nano /etc/network/interfaces
ifreload -a
cat /sys/class/net/vmbr1/bridge/vlan_filtering
# esperado: 1

# --- IP novo EM PARALELO (ao vivo; ainda nao remove o .122) ---
ip addr add 192.168.254.11/24 dev vmbr1
ip addr show dev vmbr1
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

# --- Se tudo OK: virar default + gravar permanente + tirar .122 ---
ip route replace default via 192.168.254.1
# No /etc/network/interfaces do vmbr1 trocar address/gateway para:
#   address 192.168.254.11/24
#   gateway 192.168.254.1
# (remover as linhas do 192.168.116.122/30 e gateway .121)
nano /etc/network/interfaces
ifreload -a
ip addr del 192.168.116.122/30 dev vmbr1 2>/dev/null || true
ip addr show dev vmbr1
ping -c 3 192.168.254.1
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

# BLOCO 2 — HubSoft + Zabbix — NÃO FAZER AGORA

```
# Usuario 2026-07-27: nao mexer no bridge do RB750.
# HubSoft/Zabbix continuam no path flat do 750 ate a troca pra CCR/Datacom.
# Scripts guardados (nao usar nesta etapa):
#   scripts/noite-etapa1/hubsoft-zabbix-m1-rb750-rb3011.rsc
#   hubsoft-m2-proxmox.sh · zabbix-m2-proxmox.sh · hubsoft-zabbix-rollback.rsc
# Motivo: sem vlan-filtering no 750, nao da pra separar VLAN 100/.19 no mesmo
# uplink sem quebrar o WireGuard .19 (ou sem tag=16 cedo demais).
```

---

# BLOCO 3 — DNS

## 3A) RB3011 — ether8 DNS no trunk

```rsc
/interface bridge port remove [find interface="ether8 - Proxmox DNS"]

/interface bridge port add bridge=bridge-servidores \
  interface="ether8 - Proxmox DNS" pvid=100
# VLANs ja existem por causa do Docker: acrescentar ether8 nas entradas atuais.
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=100] \
  tagged=bridge-servidores \
  untagged="ether7 - Proxmox Docker CDNTV,ether8 - Proxmox DNS"
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=16] \
  tagged="bridge-servidores,ether7 - Proxmox Docker CDNTV,ether8 - Proxmox DNS" \
  untagged=""

:do {
  /ip address set [find address="192.168.115.137/30"] interface=vlan100-servidores
} on-error={}

/ping 192.168.115.138 count=5
/ping 192.168.254.1 count=2
```

## 3B) Proxmox DNS — IP .12 + tag 16

```bash
# Host proxmox-dns

# --- VLAN-aware vmbr0 ---
# Em /etc/network/interfaces no bloco vmbr0:
#   bridge-vlan-aware yes
#   bridge-vids 2-4094
nano /etc/network/interfaces
ifreload -a
cat /sys/class/net/vmbr0/bridge/vlan_filtering

# --- IP novo EM PARALELO (manter .138) ---
ip addr add 192.168.254.12/24 dev vmbr0
ip addr show dev vmbr0
ping -c 3 192.168.254.1
# GUI: https://192.168.254.12:8006

qm set 101 -net0 e1000e,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:89:AD:23
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:50:14:F9
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:BF:0B:B5
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:E7:B0:75

ping -c 3 177.72.104.28
ping -c 3 177.72.104.58
ping -c 3 177.72.104.59

# --- Se OK: virar default + gravar + tirar .138 ---
ip route replace default via 192.168.254.1
# Em /etc/network/interfaces do vmbr0:
#   address 192.168.254.12/24
#   gateway 192.168.254.1
# (remover 192.168.115.138/30 e gateway .137)
nano /etc/network/interfaces
ifreload -a
ip addr del 192.168.115.138/30 dev vmbr0 2>/dev/null || true
ping -c 3 192.168.254.1
```

### ROLLBACK DNS (RB3011)

```rsc
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=100] \
  tagged=bridge-servidores untagged="ether7 - Proxmox Docker CDNTV"
/interface bridge vlan set [find bridge=bridge-servidores vlan-ids=16] \
  tagged="bridge-servidores,ether7 - Proxmox Docker CDNTV" untagged=""
/interface bridge port remove [find bridge=bridge-servidores interface~"ether8"]
:do {
  /ip address set [find address="192.168.115.137/30"] interface="Bridge IP Publico"
} on-error={}
/interface bridge port add bridge="Bridge IP Publico" \
  interface="ether8 - Proxmox DNS" hw=yes
/ping 192.168.115.138 count=5
```

---

# Depois dos 2 (Docker + DNS)

```rsc
# No RB3011 — conferencia final (HubSoft/Zabbix ainda no path antigo do RB750)
/ping 192.168.254.1 count=2
/ping 192.168.254.11 count=3
/ping 192.168.254.12 count=3
/ping 177.72.104.28 count=2
/ping 177.72.104.58 count=2
/ping 177.72.104.59 count=2
/ping 177.72.104.12 count=2

/export file=gw-servidores-pos-etapa1-docker-dns
```

---

# Fora desta etapa (não fazer agora)

```
# Datacom / CCR / troca de cabo / QinQ / POP / OLT / virada L3 do /27
```
