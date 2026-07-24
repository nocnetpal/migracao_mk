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
> ✅ **IP definido (usuário, 2026-07-24): `177.72.104.4`.** Cruzando a tabela completa de
> [07-enderecamento-ip.md](07-enderecamento-ip.md) (firewall filter, Dude, consulta direta aos 4
> clusters Proxmox, ARP do RB3011) contra o export bruto do RB3011/NE8000, `.4` e `.15` eram os
> únicos dois endereços do `/27` sem nenhuma referência em qualquer fonte — `.4` foi o escolhido.
> Falta só desenhar o mecanismo de roteamento exato (rota estática no NE8000 pro link com a
> CCR1036, ou subinterface dedicada) — não é mais "qual IP", é "como rotear".
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
| Proxmox Docker | `192.168.116.122/30` ✅ no plano (`ether3`) | OpenVPN-2 `177.72.104.12`, Fusion Elaborados `.22`, Fusion Painéis Simples `.25`, Aplicações `.23`, Opa ChatBot `.30` | — |
| **Proxmox HubSoft** | `192.168.115.210/30` ⚠️ **fora do plano** | HubSoft `177.72.104.16` | **Radius HubSoft `192.168.115.214`** ⚠️ |
| **Proxmox DNS** | `192.168.115.138/30` ⚠️ **fora do plano** | OLT Cloud `177.72.104.24`, DNS Master `.58`, Automações `.29` | — |
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
                         NE8000
                           │ 10GE — 🆕 só pra CCR1036 ganhar IP público (NAT usa `177.72.104.4`,
                           │ rota até lá ainda a definir)
                           │
                        CCR1036 ── 🆕 NAT (SRC-NAT geral, DST-NAT Dude/TS SIX)
                           │
                           │ 🆕 trunk 802.1q novo (era porta-a-porta antes de 2026-07-24)
                           │
                        DM4170 ── switching (só L2, decisão #13)
         ┌────────┬───────┼───────┬────────┬─────────┬─────────┐
      vlan66   vlan116  vlan10  vlan999   vlan109    vlan?      vlan?
         │       │       │       │         │          │         │
      TS SIX  Proxmox  DNS    Zabbix/   OLT CPV   Proxmox    Proxmox
              Docker   rec.   Callcenter          HubSoft⚠️   DNS⚠️
              CDNTV          (mgmt nova)          (novo)      (novo)
                                 │
                    segunda NIC → VLAN 16 / 177.72.104.5 (tráfego público direto, sem NAT,
                                  direto na rede de acesso — não passa pelo DM4170/CCR1036)
```

## Alocação de portas e VLANs (reais)

> 🆕 A CCR1036 agora usa só **2 portas físicas**: uma pro trunk com o DM4170 (carrega todas as
> VLANs de gerência abaixo) e uma pro NE8000 (só IP público do NAT, sem VLAN de servidor). As
> VLANs continuam as mesmas de antes — só o meio físico até cada servidor mudou (era porta
> dedicada na CCR1036, agora é porta dedicada no **DM4170**, tagged até a CCR1036).

| VLAN (no trunk DM4170↔CCR1036) | Dispositivo (Dude) | IP / rede hoje | Porta no DM4170 | Gateway no alvo | Observação |
|---|---|---|---|---|---|
| `vlan66` | **TS SIX** | `192.168.66.14/28` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.66.1/28` | DST-NAT `:15389` continua apontando pra cá |
| `vlan116` | **Proxmox Docker - CDNTV** | `192.168.116.122/30` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.116.121/30` | Gerência privada; tráfego público dos serviços CDNTV vai por segunda NIC |
| `vlan10` | **DNS recursivo** | `10.200.255.254/30` | porta GE dedicada (SFP-RJ45) | NE8000 `10.200.255.253/30` | Nome não consta no Dude; IP vem do `/ip address` do RB3011 |
| `vlan999` | **Proxmox Zabbix** (hoje) / **Callcenter** (a implantar) | mgmt privada nova | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.254.1/24` | O IP público `177.72.104.5/6` vai para a **segunda NIC** (VLAN16) |
| `vlan109` | **OLT CPV** | `192.168.115.42/30` | porta GE dedicada (SFP-RJ45) | NE8000 `192.168.115.41/30` | Gerência da OLT |
| 🆕 VLAN a criar | **Proxmox HubSoft** | `192.168.115.210/30` | porta GE dedicada (SFP-RJ45) | NE8000, endereço a definir | Faltava no plano — achado ao cruzar clusters Proxmox no Dude |
| 🆕 VLAN a criar | **Proxmox DNS** | `192.168.115.138/30` | porta GE dedicada (SFP-RJ45) | NE8000, endereço a definir | Faltava no plano — idem |

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

⚠️ **Pendência de desenho, não só de config:**

1. **Qual IP público usar.** Manter `.1` mantém os port-forwards sem precisar avisar ninguém que
   acessa de fora; usar outro IP do `/27` é mais simples de rotear mas exige atualizar quem
   depende do `.1` hoje.
2. **Como esse IP chega até a CCR1036.** O NE8000 é quem termina o `/27` (decisão #9). O padrão
   mais consistente com o que a própria rede já faz hoje (ver decisão #8: `.9`/`.12`/`.19`
   roteados para hosts específicos dentro do `/27`) é uma **rota estática no NE8000** apontando o
   IP de NAT para o link privado NE8000↔CCR1036 (`10.254.254.254`, ver abaixo).
3. **Alcance do DST-NAT do Dude.** O alvo do port-forward é `192.168.116.30` (RB DUDE) — esse host
   **não está entre as VLANs da CCR1036** listadas acima. Precisa confirmar como a CCR1036 alcança
   `192.168.116.30/24`: nova VLAN de gerência dedicada (chegando pelo trunk do DM4170, como as
   demais), ou rota via NE8000 até essa sub-rede (que hoje é servida pela `Bridge IP Publico` do
   RB3011 — ver [08-vlans-e-portas.md](08-vlans-e-portas.md)).

**Status:** correção de arquitetura registrada; mecanismo exato ainda em aberto — ver decisão #9
em [03-decisoes-pendentes.md](03-decisoes-pendentes.md).

## Endereços da própria CCR1036

| Uso | Endereço |
|---|---|
| Link ponto a ponto NE8000 ↔ CCR1036 (`vlan2000`) | `10.254.254.254/30` — NE8000 = `.253` |
| Gateway default | `10.254.254.253` |
| Gerência da CCR1036 | `10.254.254.254` (acesso restrito à origem do NOC) |
| Pool VPN (OpenVPN) | `10.7.0.0/24` (mesma faixa usada hoje) |

## Config RouterOS de exemplo (com IPs reais)

> 🆕 **Atualizado (2026-07-24):** não há mais porta física dedicada por servidor na CCR1036. As
> VLANs de gerência chegam **já tagged**, num trunk único vindo do DM4170.

```rsc
# Portas renomeadas — só 2 em uso agora
/interface ethernet set [ find default-name=ether1 ] name=ether1-uplink-ne8000
/interface ethernet set [ find default-name=ether2 ] name=ether2-trunk-dm4170

# VLAN p2p com o NE8000 — única finalidade: dar à CCR1036 um IP público pro NAT
/interface vlan add name=vlan2000-p2p-ne8000 vlan-id=2000 interface=ether1-uplink-ne8000

# 🆕 VLANs de gerência dos servidores, recebidas tagged no trunk do DM4170
# (antes eram portas físicas dedicadas ether2–ether6; os servidores agora plugam no DM4170)
/interface vlan add name=vlan10-dns-recursivo   vlan-id=10  interface=ether2-trunk-dm4170
/interface vlan add name=vlan66-ts-six          vlan-id=66  interface=ether2-trunk-dm4170
/interface vlan add name=vlan109-gerencia-olt   vlan-id=109 interface=ether2-trunk-dm4170
/interface vlan add name=vlan116-proxmox-docker vlan-id=116 interface=ether2-trunk-dm4170
/interface vlan add name=vlan999-mgmt-local     vlan-id=999 interface=ether2-trunk-dm4170

# A CCR1036 não roteia essas VLANs de gerência (o gateway real é o NE8000, ver tabela acima) —
# ela só precisa entregá-las ao uplink; exemplo simplificado, detalhar o bridging exato na config real

# IP da CCR1036 (somente p2p privado)
/ip address add address=10.254.254.254/30 interface=vlan2000-p2p-ne8000 comment="P2P NE8000"

# Rota default
/ip route add dst-address=0.0.0.0/0 gateway=10.254.254.253

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
add chain=input action=accept in-interface=vlan2000-p2p-ne8000 src-address=177.93.244.165 comment="GERENCIA NOC"
add chain=input action=accept protocol=tcp dst-port=1194 comment="OpenVPN"
add chain=input action=accept protocol=udp dst-port=1194 comment="OpenVPN"
add chain=input action=drop comment="DROP ALL"

# 🆕 NAT (esqueleto — IP público e VLAN ainda a definir, ver seção acima)
# /interface vlan add name=vlanXXX-nat-publico vlan-id=XXX interface=ether1-uplink-ne8000
# /ip address add address=177.72.104.1/32 interface=vlanXXX-nat-publico comment="a confirmar"
/ip firewall nat
add chain=srcnat action=src-nat to-addresses=177.72.104.1 comment="NAT GERAL — endereço a confirmar" src-address-list=NAT
add chain=dstnat action=dst-nat to-addresses=192.168.66.14 to-ports=15389 dst-port=15389 protocol=tcp comment="TS SIX"
add chain=dstnat action=dst-nat to-addresses=192.168.116.30 to-ports=8291 dst-port=18291 protocol=tcp comment="DUDE — alcance de 192.168.116.30 a confirmar"
```

## O que não muda nos servidores (gerência)

- **TS SIX** continua `192.168.66.14/28` — só o gateway passa de `192.168.66.1` (MK) para o NE8000.
- **Proxmox Docker/CDNTV** continua `192.168.116.122/30` — gateway passa para o NE8000.
- **DNS recursivo** continua `10.200.255.254/30` — gateway passa para o NE8000.
- **OLT CPV** continua `192.168.115.42/30` — gateway passa para o NE8000.
- **Proxmox Zabbix/Callcenter** ganha uma IP privado novo em `vlan999` para gerência; o IP
  público `177.72.104.5/6` migra para a **segunda NIC** (VLAN16 / rede de acesso).
- 🆕 **Proxmox HubSoft** continua `192.168.115.210/30` — gateway passa para o NE8000. VM HubSoft
  pública `177.72.104.16` segue por segunda NIC (VLAN16), sem passar pela CCR1036.
- 🆕 **Proxmox DNS** continua `192.168.115.138/30` — gateway passa para o NE8000. VMs públicas
  (OLT Cloud `.24`, DNS Master `.58`, Automações `.29`) seguem por segunda NIC (VLAN16).

## Subinterfaces que o NE8000 precisa criar (no link com a CCR1036)

```text
interface GigabitEthernet0/1/X.10   -> 10.200.255.253/30   (DNS recursivo)
interface GigabitEthernet0/1/X.66   -> 192.168.66.1/28      (TS SIX)
interface GigabitEthernet0/1/X.109  -> 192.168.115.41/30    (OLT CPV)
interface GigabitEthernet0/1/X.116  -> 192.168.116.121/30   (Proxmox Docker/CDNTV)
interface GigabitEthernet0/1/X.999  -> 192.168.254.1/24     (gerência Zabbix/Callcenter)
interface GigabitEthernet0/1/X.2000 -> 10.254.254.253/30    (p2p CCR1036)
interface GigabitEthernet0/1/X.???  -> a definir            (🆕 gerência Proxmox HubSoft, 192.168.115.210/30)
interface GigabitEthernet0/1/X.???  -> a definir            (🆕 gerência Proxmox DNS, 192.168.115.138/30)
```

A VLAN 16 (pública) **não** aparece no link CCR1036↔NE8000 — ela chega ao NE8000 pelo DM4170
(vinda da rede de acesso) e os servidores que precisarem a acessam por uma segunda NIC fora da
CCR1036.
