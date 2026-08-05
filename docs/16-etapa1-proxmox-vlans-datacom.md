# Etapa 1 — 2 VLANs nos servidores (privada + pública), depois Datacom/CCR

> ✅ **Modelo (usuário, 2026-07-27):** uma VLAN **privada** (RFC1918/gerência) + uma VLAN
> **pública** (`177.72.104.x`). Migrar L2/tags **ainda nos Mikrotiks**; depois Datacom/CCR;
> por último só virar GW/IPs. POP/OLT/QinQ fora desta etapa.
>
> **IDs fechados (2026-07-27):**
> - **VLAN 100** — privada / gerência — livre no RB3011, NE8000 (dot1q/QinQ), **SW_JDF**
>   (`display vlan 100` → não existe)
> - **VLAN 16** — pública — já no SW_JDF como `IP_PUBLICO` (TG/UT em XGE0/0/11,15,24)
>
> PPPoE_NETPAL / BGP_NETPAL: sem VLAN L2 100/16 (normal). Zero mudança aplicada além de
> renomes ether6–10 no RB3011 e portas do RB750 (`RB750-WIREGUARD`, 2026-07-27).
>
> ⚠️ **Virada Etapa 1:** scripts/runbook prontos — **não aplicar agora** (usuário 2026-07-27).
> ✅ **Não mexer no bridge do RB750** (usuário 2026-07-27). HubSoft + Zabbix **fora** desta
> etapa no MK — ficam flat no 750 até CCR/Datacom. Etapa 1 no Mikrotik = **Docker + DNS** só.

## Mapa

| VLAN | Nome | Uso |
|------|------|-----|
| **100** | GERENCIA_SERVIDORES | **só** hypervisors Proxmox + VMs privadas |
| **16** | IP_PUBLICO | VMs/containers `177.72.104.x` + CCR `.4` depois — **nunca** o IP do Proxmox |

Cabo servidor → MK (e depois Datacom): trunk · native/untagged **100** · tagged **16**.

### Regra — IPs dos Proxmox ✅ fechada (2026-07-27)

> **Todo hypervisor Proxmox fica só com IP privado na VLAN 100.** Nenhum Proxmox mantém
> (nem ganha) IP no `/27` `177.72.104.0/27`. IP público/fixo fica **só nas VMs** (`tag=16`).

✅ **Subnet VLAN 100 fechada (usuário, 2026-07-27): `192.168.254.0/24` unificado.**
✅ **Bloco livre** — checagem ao vivo **NE8000** + **RB3011** (2026-07-27): sem address,
sem rota IP, sem OSPF, sem BGP. Evidências:
`config/ne8000/check-192.168.254-2026-07-27.txt` ·
`config/rb3011/check-192.168.254-2026-07-27.txt`.

| IP | Função |
|----|--------|
| `192.168.254.1/24` | GW (SVI no RB3011 `bridge-servidores`; depois NE8000) |
| `192.168.254.10` | Proxmox Zabbix (sai de `177.72.104.5`) |
| `192.168.254.11` | Proxmox Docker (sai de `192.168.116.122/30`) |
| `192.168.254.12` | Proxmox DNS (sai de `192.168.115.138/30`) |
| `192.168.254.13` | Proxmox HubSoft (sai de `192.168.115.210/30`) |

Os `/30` atuais de gerência **deixam de existir** após cada host migrar. Dude / allowlists /
bookmarks `8006` do `.5` atualizam para `.10`.

L2: `bridge-servidores` no RB3011 com **ether7 (Docker) + ether8 (DNS)**.
`ether10` / RB750 **não entra** nesta etapa (bridge do 750 intocado).

## Ordem

```
M1  Trunks 100+16 no RB3011 (ether7 + ether8 only)
M2  Proxmox Docker + DNS: gerência 192.168.254.x · VMs 177 na tag 16
M3  Validar
…   HubSoft + Zabbix: na troca pra CCR/Datacom (sem mexer no RB750 agora)
```

**Regra:** não aplicar `tag=16` no Proxmox **antes** do trunk no MK (HubSoft caiu assim).

## Sequência (quando for virar)

✅ **Usuário (2026-07-27):** não mexer no bridge do RB750 · HubSoft/Zabbix depois (CCR).

1. **Docker** — `00-bridge-servidores-base` → `docker-m1` → `docker-m2` (`.11`)
2. **DNS** — `dns-m1` → `dns-m2` (`.12`)
3. ~~HubSoft + Zabbix~~ — **adiado** até CCR/Datacom (scripts guardados, não usar)

## Preparação sem parada (já feito / falta)

- [x] Scripts em `scripts/noite-etapa1/`
- [x] Lista `qm-set-lista.md`
- [x] Subnet VLAN 100 = `192.168.254.0/24` (.1 GW · .10–.13 hosts)
- [x] Hypervisors **não** ficam com IP no `/27` (só VMs tag 16)
- [x] Export RB750 = `RB750-WIREGUARD` + RB2011
- [x] Mapa + renomes WIREGUARD
- [x] Conferir nome `ether10` RB3011 = `ether10 - RB750 Bridge` (2026-07-27)
- [x] Export RB3011 pre-noite colado/confirmado (14:54) — arrastar `.rsc` → `config/rb3011/` (META em `.META.md`)
- [x] Export `RB750-WIREGUARD` pre-noite (15:02) → `config/rb750gr3-wireguard/rb750-wireguard-pre-noite-2026-07-27.rsc`
- [x] SW_JDF: MACs Proxmox **não** aparecem (esperado — hosts no MK, não no SW) — `config/sw-jdf/mac-proxmox-check-2026-07-27.txt`
- [~] Dude `.5` → `.10` — **na virada** (noite HubSoft+Zabbix), não hoje
- [x] Aviso equipe — **pulado** (usuário, 2026-07-27): não teremos

## Progresso — 2026-08-05

**Fase 1A (base RB3011):** ✅ concluída — `bridge-servidores` + `vlan100-servidores` + `vlan16-servidores` criadas, `192.168.254.1/24` up.

**Fase 1B (trunk ether7):** ✅ concluída — `ether7` na `bridge-servidores`, PVID 100, VLAN 16 tagged. GATE `.122` + `.254.1` OK.

**Fase 1C (Proxmox Docker):** ✅ concluída — VLAN-aware ativo e `.11/24`; tag 16 nas VMs
`103`-`107` e na NIC pública `/27` da VM 100; rede macvlan recriada com parent `ens2`
(`net7/tag16`). Containers ativos pingando (`.2` `.3` `.8` `.10` `.11`). ~~`.21`~~ foi removido
intencionalmente pelo usuário e não migra (confirmação 2026-08-05).

**Correção CDN TV (2026-08-05 05:25):** ~~VM 101 com `tag=16` na `vmbr1`~~ → ✅ corrigida.
`CdnTV-Origin` (`.107`, VM 101) e `CdnTV-Edge` (`.108`, VM 102) ficam ambas na **`vmbr2` sem
tag**, pela NIC dedicada `enp8s0f0`. Elas pertencem à rede `177.72.104.104/29`, gateway
`177.72.104.105` no NE8000 `Gi0/1/8.23` (VLAN 23), e não à VLAN 16. VMs 101/102 estão `running`,
MACs aprendidos nos taps corretos e `.105`/`.107`/`.108` responderam 5/5. Coleta:
`config/proxmox-docker/cdntv-vm101-vm102-pos-alteracao-2026-08-05.txt`.

**NE8000/L2 (2026-08-05 05:30):** `display vlan 23` no `BGP_NETPAL` retornou "VLAN does not
exist" e a tabela MAC ficou vazia — ✅ comportamento esperado, pois a tag 23 termina numa
**subinterface L3 dot1q** (`Gi0/1/8.23`), não numa VLAN/bridge L2 local do NE8000. A porta física
do segundo cabo deve ser localizada no switch L2 a montante, não no NE8000. Evidência:
`config/ne8000/check-vlan23-cdntv-2026-08-05.txt`.

**Caminho L2 confirmado (2026-08-05 05:31):** ✅ `enp8s0f0` → SW_JDF `XGE0/0/14` **untagged
VLAN 23** → SW_JDF `XGE0/0/1` **tagged** → NE8000 `Gi0/1/8.23`. ARP no NE8000 e tabela MAC no
SW_JDF bateram exatamente para `.107`, `.108` e `.109`. O membro tagged `XGE0/0/11` está DOWN e
não faz parte do caminho ativo. Como a rede de acesso está fora do corte, `XGE0/0/14` fica
intocada; só o cabo `eno1`/RB3011 ether7 migra depois ao DM4170. Evidência:
`config/sw-jdf/vlan23-cdntv-porta-2026-08-05.txt`.

**Fase 1C-final:** ✅ concluída — default route virada para `.1`, IP velho `.122/30` removido, NAT VLAN 100 adicionado no RB3011 (`192.168.254.0/24` na address-list `NAT`). Internet OK (`ping 8.8.8.8`).

**NE8000:** ✅ validado — configuração atual salva em `config/ne8000/bgp_netpal-2026-08-05.txt`.

**Fase 2 (DNS):** ✅ concluída em 2026-08-05; detalhes abaixo.

**Fase 2/M1 RB3011 (2026-08-05):** ✅ ether8 movida para `bridge-servidores`, PVID 100; VLAN 100
untagged e VLAN 16 tagged; gateway antigo `.137/30` temporariamente em `vlan100-servidores`.
Proxmox DNS `.138` respondeu 5/5 e alcançou `.254.1` 3/3. Safe Mode validado/confirmado. Evidência:
`config/rb3011/fase2-dns-m1-2026-08-05.txt`.

**Fase 2/M2 parcial (2026-08-05):** ✅ `vmbr0` VLAN-aware, `.12/24` ativo em paralelo e VMs
101/102/103/105 com tag 16; todos os IPs `.24`, `.26`, `.29`, `.28`, `.58` e `.59` respondem.
~~🚨 **Gate funcional:** DNS UDP/53 é alcançável nos três IPs da VM 105, mas retorna `SERVFAIL`
imediato para `google.com`; manter `.138/.137` e não concluir.~~ → ✅ **resolvido
operacionalmente:** como o host não tem rota IPv6, foi aplicado `do-ip6: no` e o Unbound foi
reiniciado. `.28`, `.58` e `.59` passaram a responder `NOERROR`. A hipótese intermediária de
falha no trust anchor/DNSSEC não foi confirmada; também não foi isolado se o fator decisivo foi a
remoção das tentativas IPv6, a limpeza de estado/cache pelo reinício ou ambos.

**Fase 2/M2 final (2026-08-05 06:33):** ✅ `/etc/network/interfaces` persistido com somente
`192.168.254.12/24`, gateway `192.168.254.1`, `vmbr0` VLAN-aware e porta `enp3s0f0`; o IP antigo
`.138/30` e gateway `.137` foram removidos. Gateway local 3/3, internet 3/3 e DNS recursivo
`NOERROR`. As quatro VMs seguem `running`, em `tag=16`, e todos os seis IPs responderam sem perda.
Evidências: `config/proxmox-dns/fase2-vms-tag16-validacao-2026-08-05.txt` e
`config/proxmox-dns/fase2-concluida-2026-08-05.txt`.

**Validação final Docker/CDNTV (2026-08-05):** host `.11`, gateway/NAT, VMs 100–107, VLAN 16,
CDN `.105`/`.107`/`.108`/`.109`, NTP `192.168.116.10` e internet estão ✅ OK. ~~A falha de `.21`
foi tratada inicialmente como bloqueio~~ → ✅ **reclassificada:** usuário confirmou que removeu
intencionalmente o `DNS2-Recursivo-104.21` e não o usa mais; não recriar/não migrar. Os cinco
containers ativos da mesma macvlan responderam. Baseline DNS (`.138`, `.24`, `.26`, `.28`, `.58`,
`.29`) também respondeu sem perda. **Fase 2 liberada.** Evidências:
`config/proxmox-docker/validacao-pos-cdntv-2026-08-05.txt` e
`config/rb3011/validacao-docker-cdntv-e-baseline-dns-2026-08-05.txt`.

Dumps: `config/rb3011/fase1b-*-2026-08-05.txt` · `config/proxmox-docker/fase1c-*-2026-08-05.txt` · `config/ne8000/bgp_netpal-2026-08-05.txt`

## Fora / later

- ⚠️ HubSoft não pode ser migrado isoladamente pelo RB750: ativar VLAN filtering afeta também
  Zabbix, WireGuard e gerência NE8000. A VM `HUBSOFT-RADIUS` `.214` usa gateway `.213/30`, que o
  script antigo não transportava. **Nesta rodada, por decisão do usuário (2026-08-05), somente
  organizar os IPs:** sem DM4170, CCR, recabeamento, tags ou mudança no RB750. Pré-check:
  `config/proxmox-hubsoft/precheck-migracao-vlan100-2026-08-05.txt`.
- ❌ Tentativa de transportar VLAN 100 tagged por RB3011 `Bridge IP Publico` → RB750 flat →
  HubSoft não alcançou `.1`; rollback completo e serviços antigos 3/3 OK. Evidência inicial:
  `config/proxmox-hubsoft/tentativa-vlan100-rollback-2026-08-05.txt`.
  Diagnóstico posterior corrigiu a emissão local (`vmbr0 self` precisava permitir VLAN 100) e
  comprovou o percurso até `vlan100-rb750-test` no RB3011. Captura conclusiva mostrou cada ARP
  entrando sem tag (56 bytes), mas saindo na `bridge-servidores` como **QinQ `16,100`** (64 bytes),
  sem chegar à SVI. O handoff VLAN 100 reverso interage com `vlan16-servidores`, já ligando as
  mesmas bridges. ~~Faltava testar hw-offload/RB750.~~ ✅ **Causa isolada: segundo handoff entre as
  bridges empilha tags. Não repetir.** Zabbix segue somente no novo L2 DM4170; HubSoft pode usar o
  caminho temporário físico pela `ether8`, descrito abaixo.
  Rollback final confirmou zero mudança persistente. Evidência completa:
  `config/proxmox-hubsoft/diagnostico-vlan100-preparacao-2026-08-05.txt`.
- 🟡 **Plano temporário aprovado, não executado:** intercalar switch gigabit não gerenciável na
  `ether8`, mantendo o DNS e adicionando a `eno2` livre do HubSoft. A `ether8` já fornece VLAN 100
  native + VLAN 16 tagged; não exige mudança na RB3011 nem no DNS. Primeiro validar o DNS sozinho
  atrás do switch; somente depois conectar `eno2`. A `eno1` fica na RB750 e mantém `.210`, RADIUS
  `.214` e HubSoft `.16` durante o teste paralelo de `.13/24` numa bridge nova. Para concluir com
  um cabo, ainda será necessário passar a VM `.16` pela tag 16 e transportar o gateway RADIUS
  `.213/30`; só então remover `.210` e `eno1`. Plano completo e rollback:
  `config/proxmox-hubsoft/plano-switch-temporario-2026-08-05.md`.
- VMs privadas: decidir se mantêm as sub-redes atuais como secundárias na VLAN 100 ou se serão
  renumeradas; para o RADIUS, renumerar exige revisar clientes e secrets antes.
- ~~`10.1.1.2` Zabbix `enp3s0f1` com função pendente~~ → ✅ usuário confirmou que não usa; config
  órfã, limpar depois em etapa controlada.
- 🆕 Zabbix tem `enp4s0f0` e `enp4s0f1` livres; `enp4s0f0` pode receber um segundo cabo para
  testar `.10/24` em paralelo pelo switch temporário, mantendo `enp3s0f0/.5` na RB750. Ainda não
  mover VMs: `vmbr0` não é VLAN-aware e as redes privadas precisam ser tratadas separadamente.
- ✅ Usuário escolheu reutilizar `enp3s0f1` (NIC 2) no segundo cabo; `10.1.1.2/24` já foi removido
  ao vivo e `enp4s0f0/enp4s0f1` ficam como reserva. Bridge persistente aguarda link físico.
- QinQ / POP / OLT

## Fontes

- Live Proxmox: `config/proxmox-*/live-network-2026-07-27.txt`
- Scripts: `scripts/noite-etapa1/`
- **Runbook madrugada (passo a passo):** [17-runbook-etapa1-madrugada.md](17-runbook-etapa1-madrugada.md)
- SW_JDF: `display vlan 100/16` (2026-07-27)
- [15](15-plano-migracao-servidores-177.md) · topologia rack
