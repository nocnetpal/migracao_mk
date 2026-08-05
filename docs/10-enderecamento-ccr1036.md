# Endereçamento da CCR1036

> Fonte: `docs/Devices.csv` (export do The Dude). Escopo: VPN de equipe, automações, **gerência**
> dos servidores locais **e, 🆕 desde 2026-07-23, NAT** (SRC-NAT/DST-NAT — correção do usuário
> sobre a decisão #1/#9 em [03-decisoes-pendentes.md](03-decisoes-pendentes.md)).
>
> ⚠️ **A CCR1036 deixou de ser "100% privada".** A versão anterior deste documento descrevia a
> CCR1036 sem nenhum IP público, com o tráfego público dos servidores saindo por uma segunda NIC
> direto na VLAN 16 (rede de acesso) — **essa parte segue valendo para os servidores que já têm
> IP público próprio**. O que muda: a função de **tradução de endereço** (SRC-NAT/DST-NAT) agora
> roda aqui, o que exige que ao menos um IP público do `177.72.104.0/27` seja **roteado até a
> CCR1036** através do link privado com o NE8000.
>
> ✅ **IP definido (usuário, 2026-07-24): `177.72.104.4`.** ✅ **Modelo (2026-07-27): CCR
> dentro do `/27`** (VLAN 16), igual aos servidores — sem rota `/32` por P2P privado.
>
> 🆕 **Correção do usuário (2026-07-24): os servidores locais não plugam mais direto na CCR1036.**
> Toda a agregação física de servidores passa a ser no **DM4170** (que tem 24 portas GE ópticas
> de sobra e passa a ser o ponto físico único — POPs + servidores). O DM4170 entrega essas VLANs
> de gerência privada (`vlan10`, `vlan66`, `vlan109`, `vlan116`, `vlan999` etc.) pra CCR1036 num
> **trunk 802.1q novo** (não mais porta-a-porta). A CCR1036 passa a ter só **duas portas em uso**:
> o trunk pro DM4170 e o link pro NE8000 (esse último, exclusivamente pra ganhar IP público pro
> NAT). Isso **derruba a demanda por portas RJ45** que motivava a variante 12G-4S — ver nota na
> seção de portas abaixo. Todo o resto deste documento (endereçamento IP dos servidores, NAT,
> VPN) **continua igual**; só o **meio físico de acesso** aos servidores mudou.

## Princípio: gerência do hypervisor (privada) ≠ IP das VMs (podem ser públicos e fixos)

✅ **Confirmado (usuário, 2026-07-23).** Cada cluster Proxmox tem **um IP privado de gerência do
hypervisor** (é o que pendura na CCR1036) e, dentro dele, **várias VMs com IP próprio** — várias
delas públicas e fixas, do `177.72.104.0/27`. Essas VMs **não passam pela CCR1036**: seguem o
padrão já descrito para o CDNTV, saindo por uma NIC própria direto na VLAN 16 (rede de acesso).

Cruzando o Dude ([11](11-cruzamento-dude-devices.md)), existem **4 clusters Proxmox**, mas o plano
de portas só previa gerência para 1:

| Cluster | IP de gerência (hypervisor) | VMs — **públicas** | VMs — **privadas** |
|---|---|---|---|
| Proxmox Docker | ~~`192.168.116.122/30`~~ → ✅ `192.168.254.11/24` (VLAN 100) | OpenVPN-2 `177.72.104.12`, Fusion Elaborados `.22`, Fusion Painéis Simples `.25`, Aplicações `.23`, Opa ChatBot `.30` | — |
| **Proxmox HubSoft** | `192.168.115.210/30` ⚠️ **fora do plano** | HubSoft `177.72.104.16` | **Radius HubSoft `192.168.115.214`** ⚠️ |
| **Proxmox DNS** | ~~`192.168.115.138/30`~~ → ✅ `192.168.254.12/24` (VLAN 100) | OLT Cloud `177.72.104.24`, DNS Master `.28/.58/.59`, Automações `.29`, API-ZAP `.26` | — |
| Proxmox Zabbix | ⚠️ nenhum IP de gerência identificado no Dude (`ether5` já previa "mgmt privada nova", consistente) | Zabbix `.6`, Fusion PM CPV `.14`, Fusion 0800 `.18`, Zeus TIP `.13`, "Proxmox Zabbix" `.5`, DOCS Cloud `.7`, Servidor VPN `.9`, Fusion PM MST `.17`, SFTP OPA `.20` | Dude VLSUL `192.168.17.38` ⚠️, Dude PM CPV `192.168.17.42` ⚠️, Servidor Monsta `192.168.115.62` ⚠️ |

### ⚠️ VMs privadas não cabem no `/30` de gerência do hypervisor

`Radius HubSoft` (`192.168.115.214`), `Dude VLSUL` (`192.168.17.38`), `Dude PM CPV`
(`192.168.17.42`) e `Servidor Monsta` (`192.168.115.62`) são VMs **sem IP público**, cada uma em
sub-rede diferente da do hypervisor onde rodam. Um `/30` de gerência só tem 2 IPs úteis (já
ocupados pelo hypervisor e seu gateway) — essas VMs **não cabem nele**, precisam de VLAN/rota
própria. Ainda não está claro se elas saem pela mesma porta física do hypervisor (bridge
adicional dentro do Proxmox, tagged) ou por outro caminho. **Confirmar antes de fechar o
endereçamento da CCR1036/NE8000 para esses clusters.**

> Cruzamento útil: `192.168.115.214` (Radius HubSoft) já aparecia em
> [07-enderecamento-ip.md](07-enderecamento-ip.md) na lista `FORA_DO_NAT_RADIUS` do RB3011 — agora
> sabe-se de qual VM/cluster ela é.

## Topologia lógica da CCR1036

> 🆕 **Atualizado (2026-07-24):** os servidores não plugam mais porta-a-porta na CCR1036 — todos
> entram fisicamente no **DM4170**, que entrega as VLANs de gerência num trunk único.

```
                         NE8000 ── GW do /27 (.1) na VLAN 16
                           │
                        DM4170 ── L2 (VLAN 16 + VLANs de gerência)
                           │
              ┌────────────┼──────────────┐
              │            │              │
           CCR1036     servidores      trunk gerência
           (.4 NAT     (Proxmox etc.   (vlan66/116/…)
            na VLAN16)  na VLAN16)
```

> ✅ **2026-07-27:** CCR **dentro do `/27`** — `177.72.104.4` na VLAN 16 (mesmo broadcast dos
> servidores). Sem rota `/32` por P2P privado.

## Alocação de portas e VLANs (reais)

> 🆕 A CCR1036: trunk com o DM4170 (VLANs de gerência **+ VLAN 16** com `177.72.104.4`) e,
> opcionalmente, link direto com o NE8000 se ainda for útil pra VPN/outro — **não** é mais o
> caminho do IP de NAT (NAT está na VLAN 16). As VLANs de gerência seguem tagged no trunk.

| VLAN (no trunk DM4170↔CCR1036) | Dispositivo (Dude) | IP / rede hoje | Porta no DM4170 | Gateway no alvo | Observação |
|---|---|---|---|---|---|
| `vlan66` | **TS SIX** | `192.168.66.14/28` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.66.1/28` | DST-NAT `:15389` continua apontando pra cá |
| `vlan116` | **Proxmox Docker - CDNTV** | `192.168.116.122/30` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.116.121/30` | Gerência em **vmbr1**; tráfego público tag 16 (Etapa 1) |
| `vlan10` | **DNS recursivo** | `10.200.255.254/30` | porta GE dedicada (SFP-RJ45) | NE8000 `10.200.255.253/30` | Nome não consta no Dude; IP vem do `/ip address` do RB3011 |
| `vlan999` | **Proxmox Zabbix** / **Callcenter** | mgmt privada nova | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.254.1/24` | IP público `.5` sai da gerência; VMs 177 tag 16 |
| `vlan109` | **OLT CPV** | `192.168.115.42/30` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.115.41/30` | Gerência da OLT |
| ✅ `vlan210` | ~~Proxmox HubSoft~~ | — | — | — | ~~substituído~~ → modelo 2 VLANs: **100**+**16** ([16](16-etapa1-proxmox-vlans-datacom.md), 2026-07-27) |
| ✅ `vlan138` | ~~Proxmox DNS~~ | — | — | — | idem — gerência na **100**, público na **16** |

> ⚠️ **Assumindo transceiver SFP-RJ45 (1000BASE-T) nas portas ópticas do DM4170** pra receber os
> servidores em cobre — o DM4170 24GX+12XS é 100% óptico. Vale confirmar com o usuário antes de
> fechar a lista de material (ver [02-arquitetura-alvo.md](02-arquitetura-alvo.md), questão física
> nº2).
>
> ✅ **Variante decidida (usuário, 2026-07-24): 8G-2S+.** Com só 2 portas físicas em uso (trunk +
> NE8000), a demanda de RJ45 que justificava a 12G-4S caiu bastante — a 8G-2S+ (mais barata) cobre
> com folga.

> ✅ **Esclarecido (usuário, 2026-07-23):** "Callcenter" não aparece no Dude porque **ainda não
> existe** — é um sistema novo a ser implantado, não um serviço a migrar. `vlan999` fica reservada
> também para ele quando entrar em produção; hoje ela só carrega o Proxmox Zabbix.

> ✅ **Pendência resolvida (2026-07-24):** `192.168.115.210` (HubSoft) e `192.168.115.138` (DNS)
> confirmados por `ip -4 -o addr show` direto nos hosts físicos `px-hubsoft` e `proxmox-dns` —
> `vmbr0` com esses IPs em cada um, mesmo padrão do Docker (`.116.122`), é gerência do próprio
> hypervisor. Falta só reservar VLAN/subinterface no NE8000 pra cada um. Ainda em aberto: se o
> cluster **Zabbix** realmente não tem gerência de hypervisor separada hoje (nesse caso, `vlan999`
> cobre isso ao criar a "mgmt privada nova").
>
> ✅ **Resolvido pra HubSoft (2026-07-24):** `/interface bridge host print` no **RB3011** (o
> equipamento antigo) mostrou que os MACs das VMs do cluster HubSoft (`HUBSOFT`, `HUBSOFT-RADIUS`)
> aparecem aprendidos no **mesmo `ether10` do cluster Zabbix** — ou seja, HubSoft **nunca teve
> cabo dedicado** ao RB3011; ele compartilha o segmento físico do Zabbix (deve haver um switch
> pequeno entre o `ether10` e os dois hosts físicos). **Isso muda o plano de VLANs da CCR1036: não
> é preciso reservar uma VLAN dedicada pro HubSoft** — ele pode entrar na mesma VLAN que o Zabbix,
> desde que o DM4170 (ou o switch a montante) trunque as duas gerências separadas. Resta confirmar
> o mesmo para o cluster **DNS** (`ether8` no RB3011, mesmo padrão do Docker — sem indício de
> compartilhamento até agora).

## 🆕 NAT (SRC-NAT/DST-NAT) — correção 2026-07-23

O que precisa migrar do RB3011 para cá (ver [01-inventario-atual.md](01-inventario-atual.md) e
[07-enderecamento-ip.md](07-enderecamento-ip.md)):

- **SRC-NAT geral**: redes privadas que hoje saem mascaradas como `177.72.104.1` (address-list
  `NAT`/`NAT_RADIUS` do MK antigo).
- **DST-NAT** (port-forward): `.1:18291` → Dude (`192.168.116.30:8291`), `.1:15389` → TS SIX
  (`192.168.66.14:15389`).

✅ **Mecanismo fechado (usuário, 2026-07-27):** a CCR **fica dentro do `/27`** (VLAN 16),
igual aos servidores — IP `177.72.104.4`. ~~`/32` via P2P~~ e ~~`10.254.254.x`~~ descartados.

1. **IP de NAT:** `177.72.104.4` na VLAN 16.
2. **Como chega:** L2 no broadcast do `/27` (DM4170 entrega VLAN 16 à CCR; NE8000 é o GW `.1`).
   Sem rota host especial — ARP resolve `.4` como qualquer outro servidor do bloco.
3. **DST-NAT Dude/TS SIX:** ainda aberto — portas hoje no `.1`; migrar pra `.4`?
   Alcance até Dude/TS SIX via VLANs de gerência no trunk DM4170 — ver [08](08-vlans-e-portas.md).

```
Internet → NE8000 (GW .1 do 177.72.104.0/27, VLAN16)
              │
              └─ VLAN16 (L2 via DM4170) → servidores (.5 .12 .16 …) + CCR (.4 NAT)
```

**Status:** CCR no `/27` ✅; DST-NAT `.1` vs `.4` aberto — decisão #9 em
[03](03-decisoes-pendentes.md).

## Endereços da própria CCR1036

| Uso | Endereço |
|---|---|
| IP público / NAT | `177.72.104.4` na **VLAN 16** (dentro do `/27`) |
| Gateway | NE8000 `177.72.104.1` (dono do `/27`) |
| Link adicional NE8000↔CCR (se existir) | ⛔ só se precisar de algo além da VLAN 16 — **não** usar ~~`10.254.254.x`~~ |
| Pool VPN (OpenVPN) | `10.7.0.0/24` (mesma faixa usada hoje) |

## Config RouterOS de exemplo (com IPs reais)

> 🆕 **Atualizado (2026-07-24):** não há mais porta física dedicada por servidor na CCR1036. As
> VLANs de gerência chegam **já tagged**, num trunk único vindo do DM4170.

```rsc
# Trunk DM4170: gerência + VLAN 16 (CCR dentro do /27)
/interface ethernet set [ find default-name=ether1 ] name=ether1-trunk-dm4170

/interface vlan add name=vlan16-ip-publico      vlan-id=16  interface=ether1-trunk-dm4170
/interface vlan add name=vlan10-dns-recursivo   vlan-id=10  interface=ether1-trunk-dm4170
/interface vlan add name=vlan66-ts-six          vlan-id=66  interface=ether1-trunk-dm4170
/interface vlan add name=vlan109-gerencia-olt   vlan-id=109 interface=ether1-trunk-dm4170
/interface vlan add name=vlan116-proxmox-docker vlan-id=116 interface=ether1-trunk-dm4170
/interface vlan add name=vlan999-mgmt-local     vlan-id=999 interface=ether1-trunk-dm4170

# IP público NAT — dentro do /27 (VLAN 16), GW = NE8000 .1
/ip address add address=177.72.104.4/27 interface=vlan16-ip-publico comment="NAT CCR"
/ip route add dst-address=0.0.0.0/0 gateway=177.72.104.1

# OpenVPN (exemplo — certs precisam ser gerados/emitidos)
/interface ovpn-server server set enabled=yes port=1194 mode=ip require-client-certificate=yes cipher=aes256 auth=sha512
/ppp profile add name=profile-ovpn local-address=10.7.0.1 remote-address=pool-ovpn use-encryption=yes
/ip pool add name=pool-ovpn ranges=10.7.0.2-10.7.0.254
/ppp secret add name=bruno     profile=profile-ovpn password=***
/ppp secret add name=isaac    profile=profile-ovpn password=***
/ppp secret add name=leonardo profile=profile-ovpn password=***
/ppp secret add name=vpnbruno profile=profile-ovpn password=***

# Firewall mínimo
/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="ESTABLISHED"
add chain=input action=accept src-address=177.93.244.165 comment="GERENCIA NOC"
add chain=input action=accept protocol=tcp dst-port=1194 comment="OpenVPN"
add chain=input action=accept protocol=udp dst-port=1194 comment="OpenVPN"
add chain=input action=drop comment="DROP ALL"

/ip firewall nat
add chain=srcnat action=src-nat to-addresses=177.72.104.4 comment="NAT GERAL" src-address-list=NAT
add chain=dstnat action=dst-nat to-addresses=192.168.66.14 to-ports=15389 dst-port=15389 protocol=tcp comment="TS SIX"
add chain=dstnat action=dst-nat to-addresses=192.168.116.30 to-ports=8291 dst-port=18291 protocol=tcp comment="DUDE — alcance a confirmar"
```

## O que não muda nos servidores (gerência)

- **TS SIX** continua `192.168.66.14/28` — só o gateway passa de `192.168.66.1` (MK) para o NE8000.
- ~~**Proxmox Docker/CDNTV** continua `192.168.116.122/30`.~~ → ✅ migrou para
  `192.168.254.11/24` na VLAN 100 em 2026-08-05; gateway ainda no RB3011 e depois passa ao NE8000.
- **DNS recursivo** continua `10.200.255.254/30` — gateway passa para o NE8000.
- **OLT CPV** continua `192.168.115.42/30` — gateway passa para o NE8000.
- **Proxmox Zabbix/Callcenter** ganha um IP privado novo na VLAN 100 para gerência; o IP
  público `177.72.104.5/6` migra para a **segunda NIC** (VLAN16 / rede de acesso).
- 🆕 **Proxmox HubSoft** continua `192.168.115.210/30` — gateway passa para o NE8000. VM HubSoft
  pública `177.72.104.16` segue por segunda NIC (VLAN16), sem passar pela CCR1036.
- ~~🆕 **Proxmox DNS** continua `192.168.115.138/30`.~~ → ✅ migrou para
  `192.168.254.12/24` na VLAN 100 em 2026-08-05; gateway ainda no RB3011 e depois passa ao NE8000.
  VMs públicas (`.24`, `.26`, `.29`, `.28/.58/.59`) seguem na VLAN 16.

## Subinterfaces que o NE8000 precisa criar (no link com a CCR1036)

```text
interface GigabitEthernet0/1/X.10   -> 10.200.255.253/30   (DNS recursivo)
interface GigabitEthernet0/1/X.66   -> 192.168.66.1/28      (TS SIX)
interface GigabitEthernet0/1/X.109  -> 192.168.115.41/30    (OLT CPV)
interface GigabitEthernet0/1/X.100  -> 192.168.254.1/24     (gerência dos Proxmox)
interface GigabitEthernet0/1/X.2000 -> <NE8000-P2P>/<mask>  (p2p CCR1036 — IPs a definir)
interface GigabitEthernet0/1/X.???  -> a definir            (🆕 gerência Proxmox HubSoft, 192.168.115.210/30)
```

A VLAN 16 (pública) sobe pelo DM4170 até o NE8000 **e** até a CCR (`177.72.104.4` no mesmo
broadcast). Servidores com IP público próprio também usam VLAN 16; gerência privada segue nas
outras VLANs do trunk.
