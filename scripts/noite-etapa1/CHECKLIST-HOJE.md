# Checklist de execução — Etapa 1 (Docker + DNS)

**Data:** 2026-08-04 · **Escopo:** somente Docker (ether7) + DNS (ether8) no RB3011
**Fonte:** `docs/17-runbook-etapa1-madrugada.md` + scripts desta pasta

> ⚠️ NÃO FAZER HOJE: HubSoft, Zabbix, RB750, ether10, Datacom, CCR1036, QinQ, virada do /27.

---

## FASE 0 — Pré-janela (fazer ANTES de começar)

- [x] **0.1** Confirmar autorização ✅ (2026-08-04)
- [x] **0.2** Export fresco do RB3011 ✅ → `config/rb3011/gw-servidores-pre-etapa1-2026-08-04.rsc`
- [ ] **0.3** Export fresco do RB750-WIREGUARD (precaução, não vamos mexer nele)
- [ ] **0.4** Acesso IPMI/iDRAC validado no Proxmox Docker (Dell) e iLO no Proxmox DNS (HP)
- [x] **0.5** Conferir nomes exatos no RB3011 ✅
  - [x] `ether7 - Proxmox Docker CDNTV`
  - [x] `ether8 - Proxmox DNS`
  - [x] `Bridge IP Publico`
- [x] **0.6** `192.168.254.0/24` livre ✅ — nada no RB3011
- [x] **0.7** Baseline de pings ✅ → `config/rb3011/baseline-pings-pre-etapa1-2026-08-04.txt`
  - [x] `ping 192.168.116.122` (Docker host) → 5/5 OK
  - [x] `ping 177.72.104.12` (OpenVPN2) → 3/3 OK
  - [x] `ping 177.72.104.2` `.3` `.8` `.10` `.11` `.21` `.107` → todos OK
- [x] **0.8** No host Docker: backup interfaces ✅ → `config/proxmox-docker/interfaces-pre-etapa1-2026-08-04.txt`
- [ ] **0.9** No host DNS: `cp /etc/network/interfaces /etc/network/interfaces.bak-pre-etapa1`
- [x] **0.10** `qm config` salvo das VMs Docker (101, 103–107) ✅ → `config/proxmox-docker/qm-configs-pre-etapa1-2026-08-04.txt`
- [ ] **0.11** Decisão tomada e comandos escritos para **Docker-Netpal (VMID 100) macvlan → VLAN 16** (ver FASE 1.5 abaixo)
- [ ] **0.12** Decisão sobre **CdnTV-Edge `.108`**: entra ou fica de fora (hoje só `.107` entra nos qm set)
- [ ] **0.13** Critério de abort definido: se gate de ping falhar ou bloco travar > 15 min → rollback do bloco e **parar**
- [ ] **0.14** Rollbacks abertos na tela: `docker-rollback.rsc`, `dns-rollback.rsc` + comandos de rollback Proxmox (item 1.7)

---

## FASE 1 — Docker (RB3011 ether7 → Proxmox Docker/CDNTV)

### 1A. Base no RB3011 (uma única vez)
- [ ] Colar `00-bridge-servidores-base.rsc`
- [ ] Verificar: `/ip address print where address~"192.168.254.1"` → deve existir em `vlan100-servidores`
- [ ] Verificar: `vlan16-servidores` virou porta da `Bridge IP Publico`

### 1B. Trunk ether7 no RB3011
- [x] **CONCLUÍDO** — 2026-08-05
- [x] Colar `docker-m1-rb3011.rsc`
- [x] **GATE:** `/ping 192.168.116.122 count=5` → 5/5 OK
- [x] **GATE:** `/ping 192.168.254.1 count=2` → 2/2 OK
- [x] VLAN 16 corrigida para tagged em `ether7`
  - [ ] ✅ OK → segue para 1C
  - [ ] ❌ Falhou → colar `docker-rollback.rsc` e **PARAR A NOITE**

### 1C. Proxmox Docker (executar seguido, sem pausa — VMs públicas caem aqui)
- [x] Ativar VLAN-aware: editar `/etc/network/interfaces` — `vmbr1`: `bridge-vlan-aware yes` + `bridge-vids 2-4094`
- [x] **Preservar** `10.250.104.1/24` e `10.250.102.1/24` no vmbr1 (conferir com o .bak)
- [x] `ifreload -a` → conferir `cat /sys/class/net/vmbr1/bridge/vlan_filtering` = `1` (esperar flap breve dos taps)
- [x] IP novo em paralelo: `ip addr add 192.168.254.11/24 dev vmbr1`
- [x] `ping -c3 192.168.254.1` → OK
- [x] GUI: `https://192.168.254.11:8006` abre
- [x] `qm set` tag=16 nas VMs (MACs do `qm-set-lista.md`): 101, 103, 104, 105, 106, 107
  - [x] **Não tocar** net5/net6 (tags 18/38 — SEVERINO e SpeedTest)
- [x] Reboot/re-plug das VMs se a tag não hot-aplicar (validar com ping em cada)
- [x] **1C-macvlan (CRÍTICO):** VLAN 16 chegando ao parent macvlan da Docker-Netpal (VMID 100)
  - [x] Executar procedimento: `net7` adicionado, rede macvlan recriada com parent `ens2`
  - [x] Validar: `ping 177.72.104.2` `.3` `.8` `.10` `.11` `.21` — todos OK
- [x] Validar: `ping -c3 177.72.104.12` (OpenVPN2) → OK
- [x] Validar: `ping -c3 177.72.104.107` (CdnTV-Origin, VM 101) → OK
- [x] Só agora: `ip route replace default via 192.168.254.1` — OK
- [x] Gravar `.11/24` + `gateway 192.168.254.1` em `/etc/network/interfaces` → `ifreload -a` — OK
- [x] Remover IP velho: `ip addr del 192.168.116.122/30 dev vmbr1` — OK
- [x] Conferir `10.250.104.1` e `10.250.102.1` ainda presentes no vmbr1 — OK
- [x] **NAT VLAN 100:** adicionado `192.168.254.0/24` na address-list `NAT` do RB3011 — OK (`ping 8.8.8.8` OK)

### 1D. Rollback lado Proxmox (ter pronto ANTES — usar só se necessário)
```
# Reverter tags: qm set <vmid> -net0 <modelo>=<MAC>,bridge=vmbr1   (sem tag=16)
# ip addr del 192.168.254.11/24 dev vmbr1
# ip addr add 192.168.116.122/30 dev vmbr1
# ip route replace default via 192.168.116.121
# Restaurar /etc/network/interfaces.bak-pre-etapa1 → ifreload -a
```

---

## FASE 2 — DNS (RB3011 ether8 → Proxmox DNS)

### 2A. Trunk ether8 no RB3011
- [ ] Colar `dns-m1-rb3011.rsc`
- [ ] **GATE:** `/ping 192.168.115.138 count=5` → **deve responder**
  - [ ] ✅ OK → segue para 2B
  - [ ] ❌ Falhou → colar `dns-rollback.rsc` e **PARAR** (Docker já migrado fica como está)

### 2B. Proxmox DNS
- [ ] `vmbr0`: `bridge-vlan-aware yes` + `bridge-vids 2-4094` → `ifreload -a` → `vlan_filtering=1`
- [ ] `ip addr add 192.168.254.12/24 dev vmbr0`
- [ ] `ping -c3 192.168.254.1` → OK
- [ ] GUI: `https://192.168.254.12:8006` abre
- [ ] `qm set` tag=16 nas VMs: 101, 102, 103, 105
- [ ] Reboot/re-plug das VMs se necessário
- [ ] Validar: `ping -c3 177.72.104.28` (NS-UNBOUND — **recursivo da rede, prioridade máxima**)
- [ ] Validar: `ping -c3 177.72.104.58` (mesmo host, segundo IP)
- [ ] Validar: `ping -c3 177.72.104.24` `.26` `.29` (OLT-CLOUD, API-ZAP, AUTOMACOES)
- [ ] `ip route replace default via 192.168.254.1`
- [ ] Gravar em `/etc/network/interfaces` → `ifreload -a`
- [ ] Remover IP velho: `ip addr del 192.168.115.138/30 dev vmbr0`

---

## FASE 3 — Validação final e fechamento

- [x] Do RB3011: ping `192.168.254.1` `.11` `177.72.104.12` `177.72.104.2` `.3` `.8` `.10` `.11` `.21` — OK
- [x] NE8000 validado: configuração atual salva em `config/ne8000/bgp_netpal-2026-08-05.txt`
- [ ] Serviços públicos um a um: OpenVPN2 `.12` · Fusion `.22`/`.25` · APP `.23` · OPA `.30` · NS-UNBOUND `.28`/`.58` · OLT-CLOUD `.24` · API-ZAP `.26` · AUTOMACOES `.29` · containers `.2`/`.3`/`.8`/`.10`/`.11`/`.21` · CdnTV `.107` — pendente
- [ ] NTP da rede: `ping 192.168.116.10` + equipamentos sincronizando — pendente
- [ ] DNS recursivo resolvendo (testar de um cliente/rede de acesso) — pendente
- [ ] GUIs Proxmox: `https://192.168.254.11:8006` — OK · `https://192.168.254.12:8006` — pendente (Fase 2)
- [ ] Export final: `/export file=gw-servidores-pos-etapa1-docker-dns` — pendente

## FASE 4 — Pós (pode ser amanhã, mas registrar)

- [ ] Remover `/30` muletas de `vlan100-servidores`: `192.168.116.121/30` e `192.168.115.137/30`
- [ ] Atualizar Dude, bookmarks e allowlists: `.122`→`.11`, `.138`→`.12`
- [ ] Anotar pendências para a fase CCR/Datacom (HubSoft/Zabbix, DST-NAT `.1` vs `.4`, etc.)
