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
> CCR1036** através do link privado com o NE8000 — mecanismo exato ainda **a definir** (ver seção
> abaixo).

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

```
                         NE8000
                           │ 1GE — VLANs privadas de gerência
                           │ 🆕 + rota do IP público de NAT (a definir)
                           │
                        CCR1036 ── 🆕 NAT (SRC-NAT geral, DST-NAT Dude/TS SIX)
         ┌────────┬───────┼───────┬────────┬─────────┬─────────┐
      ether2  ether3  ether4  ether5    ether6     ether7?   ether8?
         │       │       │       │         │          │         │
      TS SIX  Proxmox  DNS    Zabbix/   OLT CPV   Proxmox    Proxmox
              Docker   rec.   Callcenter          HubSoft⚠️   DNS⚠️
              CDNTV          (mgmt nova)          (novo)      (novo)
                                 │
                    segunda NIC → VLAN 16 / 177.72.104.5 (tráfego público direto, sem NAT)
```

## Alocação de portas e IPs (reais)

| Porta CCR | Dispositivo (Dude) | IP / rede hoje | VLAN no alvo | Gateway no alvo | Observação |
|---|---|---|---|---|---|
| `ether1` | — (uplink NE8000) | — | `vlan2000` (p2p) + `vlan10` + `vlan66` + `vlan109` + `vlan116` + `vlan999` + *novas abaixo* | — | Apenas tráfego privado |
| `ether2` | **TS SIX** | `192.168.66.14/28` | `vlan66` untagged | NE8000 `192.168.66.1/28` | DST-NAT `:15389` continua apontando para cá |
| `ether3` | **Proxmox Docker - CDNTV** | `192.168.116.122/30` | `vlan116` untagged | NE8000 `192.168.116.121/30` | Gerência privada; tráfego público dos serviços CDNTV vai por segunda NIC |
| `ether4` | **DNS recursivo** | `10.200.255.254/30` | `vlan10` untagged | NE8000 `10.200.255.253/30` | Nome não consta no Dude; IP vem do `/ip address` do RB3011 |
| `ether5` | **Proxmox Zabbix** (hoje) / **Callcenter** (a implantar) | mgmt privada nova | `vlan999` untagged | NE8000 `192.168.254.1/24` | O IP público `177.72.104.5/6` vai para a **segunda NIC** (VLAN16) |
| `ether6` | **OLT CPV** | `192.168.115.42/30` | `vlan109` untagged | NE8000 `192.168.115.41/30` | Gerência da OLT |
| 🆕 `ether7` (a criar) | **Proxmox HubSoft** | `192.168.115.210/30` | VLAN a definir | NE8000, endereço a definir | Faltava no plano — achado ao cruzar clusters Proxmox no Dude |
| 🆕 `ether8` (a criar) | **Proxmox DNS** | `192.168.115.138/30` | VLAN a definir | NE8000, endereço a definir | Faltava no plano — idem |

> Com a variante recomendada (**12G-4S**, ver discussão de hardware), sobram portas RJ45 de sobra
> pra isso sem trocar de modelo: 6 em uso + 2 novas = 8, ainda restam 4 RJ45 + 4 SFP.

> ✅ **Esclarecido (usuário, 2026-07-23):** "Callcenter" não aparece no Dude porque **ainda não
> existe** — é um sistema novo a ser implantado, não um serviço a migrar. `ether5`/`vlan999` fica
> reservada também para ele quando entrar em produção; hoje a porta é só do Proxmox Zabbix.

> ⚠️ **Pendência nova:** confirmar se `192.168.115.210` (HubSoft) e `192.168.115.138` (DNS) são
> IPs de gerência do próprio hypervisor Proxmox (mesmo padrão do Docker, `.116.122`) ou de outra
> VM dentro do cluster — e se o cluster **Zabbix** realmente não tem gerência de hypervisor
> separada hoje (nesse caso, `ether5` cobre isso ao criar a "mgmt privada nova").

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
   **não está entre as portas da CCR1036** listadas abaixo (`ether2`–`ether6`). Precisa confirmar
   como a CCR1036 alcança `192.168.116.30/24`: nova VLAN de gerência dedicada, ou rota via NE8000
   até essa sub-rede (que hoje é servida pela `Bridge IP Publico` do RB3011 — ver
   [08-vlans-e-portas.md](08-vlans-e-portas.md)).

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

```rsc
# Portas renomeadas
/interface ethernet set [ find default-name=ether1 ] name=ether1-uplink-ne8000
/interface ethernet set [ find default-name=ether2 ] name=ether2-ts-six
/interface ethernet set [ find default-name=ether3 ] name=ether3-proxmox-docker
/interface ethernet set [ find default-name=ether4 ] name=ether4-dns-recursivo
/interface ethernet set [ find default-name=ether5 ] name=ether5-zabbix-callcenter
/interface ethernet set [ find default-name=ether6 ] name=ether6-gerencia-olt-cpv

# VLANs no uplink (TODAS privadas)
/interface vlan add name=vlan10-dns-recursivo vlan-id=10 interface=ether1-uplink-ne8000
/interface vlan add name=vlan66-ts-six vlan-id=66 interface=ether1-uplink-ne8000
/interface vlan add name=vlan109-gerencia-olt vlan-id=109 interface=ether1-uplink-ne8000
/interface vlan add name=vlan116-proxmox-docker vlan-id=116 interface=ether1-uplink-ne8000
/interface vlan add name=vlan999-mgmt-local vlan-id=999 interface=ether1-uplink-ne8000
/interface vlan add name=vlan2000-p2p-ne8000 vlan-id=2000 interface=ether1-uplink-ne8000

# Bridge dos servidores locais (L2 puro)
/interface bridge add name=bridge-servidores
/interface bridge port add bridge=bridge-servidores interface=ether2-ts-six pvid=66
/interface bridge port add bridge=bridge-servidores interface=ether3-proxmox-docker pvid=116
/interface bridge port add bridge=bridge-servidores interface=ether4-dns-recursivo pvid=10
/interface bridge port add bridge=bridge-servidores interface=ether5-zabbix-callcenter pvid=999
/interface bridge port add bridge=bridge-servidores interface=ether6-gerencia-olt pvid=109

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
