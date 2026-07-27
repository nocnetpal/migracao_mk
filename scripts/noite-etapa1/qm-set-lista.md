# Lista qm set — Etapa 1 (tag 16 nas VMs públicas)

Fonte: `config/proxmox-*/live-network-2026-07-27.txt`  
**Só na madrugada**, depois do M1 no Mikrotik.

Gerência hypervisors (VLAN 100): `.10` Zabbix · `.11` Docker · `.12` DNS · `.13` HubSoft · GW `.1`

## HubSoft (`px-hubsoft`) — vmbr0 → `192.168.254.13`

```bash
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,macaddr=72:56:05:A7:29:E9
# RADIUS .214 → VLAN 100 native — SEM tag 16
```

## DNS (`proxmox-dns`) — vmbr0 → `192.168.254.12`

```bash
qm set 101 -net0 e1000e,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:89:AD:23
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:50:14:F9
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:BF:0B:B5
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=BC:24:11:E7:B0:75
```

## Zabbix (`proxmox3`) — vmbr0 → `192.168.254.10` (sai do `.5`)

```bash
qm set 110 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=4E:01:6C:C9:F0:78
qm set 103 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=B2:63:2D:95:56:FD
qm set 107 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=56:EC:57:EB:68:14
qm set 105 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=8A:26:35:E8:3A:BF
qm set 104 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=EE:2A:8A:5A:EE:E0
qm set 106 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=1A:97:C3:E0:DC:D3
qm set 108 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=16:8C:EF:D4:03:FD
qm set 102 -net0 virtio,bridge=vmbr0,tag=16,firewall=1,macaddr=F2:19:E1:4A:8C:8A
# 100/101/109 — sem tag 16
```

## Docker (`proxmoxDockerCDNTV`) — vmbr1 → `192.168.254.11`

```bash
qm set 103 -net0 e1000,bridge=vmbr1,tag=16,firewall=1,macaddr=F6:C7:5C:8A:4A:A3
qm set 104 -net0 virtio,bridge=vmbr1,tag=16,firewall=0,macaddr=6E:26:1A:C9:19:CE
qm set 105 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=62:B2:A1:0A:B1:AE
qm set 106 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=0E:C8:34:76:59:4E
qm set 107 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,macaddr=36:DC:89:9D:DA:5A
qm set 101 -net0 virtio,bridge=vmbr1,tag=16,firewall=1,queues=8,macaddr=2A:B7:2D:D8:6E:A2
# Docker-Netpal macvlan → parent tag 16; net5/net6 18/38 NÃO mexer
```
