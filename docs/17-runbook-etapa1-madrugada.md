# Runbook — Etapa 1 (madrugada dos 4 Proxmox)

> **Objetivo:** colocar VLAN **100** (gerência `192.168.254.0/24`) + VLAN **16** (pública `177.x`)
> no path dos 4 hypervisors **ainda nos Mikrotiks**. Datacom/CCR/QinQ = depois.
>
> **Janela:** uma madrugada · **4 servidores** · ordem abaixo.
> **Scripts:** [`scripts/noite-etapa1/`](../scripts/noite-etapa1/)  
> **Contexto:** [16-etapa1-proxmox-vlans-datacom.md](16-etapa1-proxmox-vlans-datacom.md)

---

## Mapa rápido

| VLAN | Uso | No fio |
|------|-----|--------|
| **100** | gerência Proxmox + VMs privadas | native / untagged |
| **16** | VMs `177.72.104.x` | tagged |

| IP | Quem | Sai de |
|----|------|--------|
| `192.168.254.1` | GW (RB3011 `vlan100-servidores`) | — |
| `.10` | Proxmox Zabbix | `177.72.104.5` |
| `.11` | Proxmox Docker | `192.168.116.122/30` |
| `.12` | Proxmox DNS | `192.168.115.138/30` |
| `.13` | Proxmox HubSoft | `192.168.115.210/30` |

**Regra de ouro:** nunca `tag=16` no Proxmox **antes** do trunk no Mikrotik.

**Se um bloco falhar:** rollback **só daquele** bloco · não avance.

---

## Antes de começar (checklist)

- [ ] SSH/Winbox: **RB3011** (`GW Servidores`)
- [ ] SSH/Winbox: **RB750-WIREGUARD**
- [ ] SSH root: Proxmox **Docker**, **HubSoft**, **Zabbix**, **DNS**
- [ ] Pasta `scripts/noite-etapa1/` aberta (ou impressa)
- [ ] Rollback de cada bloco à mão (arquivos `*-rollback.rsc`)
- [ ] Confirmar nomes:
  - RB3011: `ether7 - Proxmox Docker CDNTV` · `ether8 - Proxmox DNS` · `ether10 - RB750 Bridge`
  - RB750: `ether3 - Proxmox Zabbix` · `ether4 - Proxmox HubSoft` · `ether5 - Uplink GW Servidores` · `bridge1 - Servidores`

---

## Bloco 1 — Base + Docker

### 1.1 RB3011 — criar `bridge-servidores` + GW `.1`

Arquivo: `00-bridge-servidores-base.rsc`

- [ ] Colar no RB3011
- [ ] Validar:

```rsc
/ip address print where address~"192.168.254.1"
/ping 192.168.254.1 count=2
/interface bridge print where name=bridge-servidores
```

- [ ] Vê `192.168.254.1/24` em `vlan100-servidores` → segue  
- [ ] Senão → **para** (não continue)

### 1.2 RB3011 — M1 Docker (`ether7`)

Arquivo: `docker-m1-rb3011.rsc`

- [ ] Colar no RB3011
- [ ] Validar:

```rsc
/ping 192.168.116.122 count=5
/ping 192.168.254.1 count=2
```

- [ ] Ping `.122` OK → Proxmox  
- [ ] Ping falhou → `docker-rollback.rsc` · **para**

### 1.3 Proxmox Docker — M2

Host: `proxmoxDockerCDNTV` · gerência hoje em **vmbr1** · alvo **`.11`**

Arquivo: `docker-m2-proxmox.sh` + edição manual de `/etc/network/interfaces`

- [ ] `bridge-vlan-aware yes` no `vmbr1` + `bridge-vids 2-4094`
- [ ] `ifreload -a` · conferir: `cat /sys/class/net/vmbr1/bridge/vlan_filtering` → `1`
- [ ] IP **paralelo** `192.168.254.11/24` GW `192.168.254.1` (**manter** `.122` por enquanto)
- [ ] `ping 192.168.254.1` · GUI `https://192.168.254.11:8006`
- [ ] Rodar `qm set … tag=16` do script (VMs 101, 103–107)
- [ ] `ping 177.72.104.12` (ou outra VM 177 do cluster)
- [ ] Docker-Netpal macvlan 177: parent com tag 16 (ajustar na VM) · **não** mexer net5/net6 (18/38)
- [ ] OK → remover `.122` · deixar só `.11`
- [ ] Falhou → reverter tags/IP no Proxmox · se preciso `docker-rollback.rsc` no MK

**Bloco 1 concluído quando:** gerência Docker = `.11` · VMs 177 respondem com tag 16.

---

## Bloco 2 — HubSoft + Zabbix (juntos)

> Mesmo path RB750 + `ether10`. Fazer os dois neste bloco.

### 2.1 RB750-WIREGUARD — parte (A)

Arquivo: `hubsoft-zabbix-m1-rb750-rb3011.rsc` · **só a seção (A)**

- [ ] Criar `vlan16-wg` / `vlan100-wg`
- [ ] Mover `177.72.104.19/27` de ether5 → `vlan16-wg`
- [ ] `vlan-filtering=yes` na `bridge1 - Servidores`
- [ ] PVID 100 nas portas · VLAN 100/16 conforme script
- [ ] Validar:

```rsc
/ip address print where address~"177.72.104.19"
/ping 177.72.104.1 count=5
```

- [ ] VPN/WG ok (peers vivos)  
- [ ] `.19` ou default falhou → `hubsoft-zabbix-rollback.rsc` (RB750) · **para**

### 2.2 RB3011 — parte (B) `ether10`

Mesmo arquivo · **seção (B)**

- [ ] Tirar `ether10 - RB750 Bridge` da Bridge IP Publico · meter em `bridge-servidores` (tagged 100+16)
- [ ] Validar:

```rsc
/ping 192.168.254.1 count=2
/ping 177.72.104.19 count=5
/ping 192.168.115.210 count=3
/ping 177.72.104.5 count=3
```

- [ ] HubSoft/Zabbix antigos ainda pingam → M2  
- [ ] Falhou → rollback HubSoft+Zabbix · **para**

### 2.3 Proxmox HubSoft — M2

Host: `px-hubsoft` · vmbr0 · alvo **`.13`** · vlan-aware já deve estar `1`

Arquivo: `hubsoft-m2-proxmox.sh`

- [ ] IP paralelo `192.168.254.13/24` GW `.1` (manter `.210`)
- [ ] `ping 192.168.254.1` · GUI `:8006` no `.13`
- [ ] `qm set 102 … tag=16` (HubSoft `.16`)
- [ ] Radius (101): **sem** tag 16 (fica native 100)
- [ ] `ping 177.72.104.16`
- [ ] OK → remover `.210`

### 2.4 Proxmox Zabbix — M2

Host: `proxmox3` · vmbr0 · hoje **`.5/27`** · alvo **`.10`**

Arquivo: `zabbix-m2-proxmox.sh`

- [ ] `bridge-vlan-aware` no vmbr0 + `ifreload -a`
- [ ] IP paralelo `192.168.254.10/24` GW `.1` (**manter `.5` até validar**)
- [ ] `ping 192.168.254.1` · GUI `https://192.168.254.10:8006`
- [ ] **Dude:** device `177.72.104.5` → `192.168.254.10`
- [ ] `qm set … tag=16` nas VMs públicas (lista no script / `qm-set-lista.md`)
- [ ] `ping 177.72.104.6` (Zabbix VM)
- [ ] OK → **remover `177.72.104.5`** do vmbr0
- [ ] VMs órfãs 100/101/109: sem tag 16 (later / VLAN 100)

**Bloco 2 concluído quando:** HubSoft `.13` · Zabbix `.10` · Dude no `.10` · `.5` fora · VMs 177 ok.

---

## Bloco 3 — DNS

### 3.1 RB3011 — M1 DNS (`ether8`)

Arquivo: `dns-m1-rb3011.rsc`

- [ ] Colar no RB3011
- [ ] Validar:

```rsc
/ping 192.168.115.138 count=5
/ping 192.168.254.1 count=2
```

- [ ] Falhou → `dns-rollback.rsc` · **para**

### 3.2 Proxmox DNS — M2

Host: `proxmox-dns` · vmbr0 · alvo **`.12`**

Arquivo: `dns-m2-proxmox.sh`

- [ ] `bridge-vlan-aware` no vmbr0 + `ifreload -a`
- [ ] IP paralelo `192.168.254.12/24` GW `.1` (manter `.138`)
- [ ] Ping `.1` · GUI `:8006` no `.12`
- [ ] `qm set` tag 16 nas VMs 101, 102, 103, 105
- [ ] `ping 177.72.104.28` (NS-UNBOUND)
- [ ] OK → remover `.138`

**Bloco 3 concluído quando:** DNS `.12` · VMs 177 ok.

---

## Encerramento da Etapa 1

- [ ] Ping dos 4: `.10` `.11` `.12` `.13` + GW `.1`
- [ ] Spot-check `177.72.104.x` (HubSoft, DNS, Zabbix, Docker)
- [ ] WireGuard `.19` ok
- [ ] Export pós-noite RB3011 + RB750 → salvar em `config/`
- [ ] Atualizar bookmarks locais dos 4 Proxmox

### Estado esperado

```
RB3011 bridge-servidores: ether7 + ether8 + ether10 (100+16)
RB750: vlan-filtering · ether3/4 access 100+tag16 · ether5 trunk · .19 em vlan16
Hypervisors: só 192.168.254.x · nenhum no /27
VMs públicas: tag=16
```

---

## Rollbacks (referência rápida)

| Bloco | Arquivo |
|-------|---------|
| Docker | `docker-rollback.rsc` (+ reverter Proxmox) |
| HubSoft+Zabbix | `hubsoft-zabbix-rollback.rsc` (RB750 depois RB3011) |
| DNS | `dns-rollback.rsc` |

---

## Fora desta etapa (não fazer agora)

- Datacom DM4170 / CCR1036 / troca de cabos
- POP / OLT / QinQ / virada L3 do `/27`
- VMs órfãs finas · `10.1.1.2` no Zabbix

---

## Índice de arquivos

| Passo | Arquivo |
|-------|---------|
| Base | `scripts/noite-etapa1/00-bridge-servidores-base.rsc` |
| Docker M1/M2/RB | `docker-m1-rb3011.rsc` · `docker-m2-proxmox.sh` · `docker-rollback.rsc` |
| HubSoft+Zabbix M1/M2/RB | `hubsoft-zabbix-m1-rb750-rb3011.rsc` · `hubsoft-m2-proxmox.sh` · `zabbix-m2-proxmox.sh` · `hubsoft-zabbix-rollback.rsc` |
| DNS M1/M2/RB | `dns-m1-rb3011.rsc` · `dns-m2-proxmox.sh` · `dns-rollback.rsc` |
| Lista qm | `qm-set-lista.md` |
| Visão | [16](16-etapa1-proxmox-vlans-datacom.md) · [14](14-ips-servidores-e-17772.md) · topologia rack |
