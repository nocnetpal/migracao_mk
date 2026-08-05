# Mapeamento de IPs — clusters Proxmox

> Fonte: `docs/Devices.csv` (Dude), cruzado com [07-enderecamento-ip.md](07-enderecamento-ip.md)
> (regras do RB3011) e [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md) (plano de portas
> da CCR1036). Todos os IPs, sem omitir nenhum.
>
> 🆕 **Confirmação direta nos 4 clusters (2026-07-24):** rodado
> [`scripts/proxmox-mapear-vms.sh`](../scripts/proxmox-mapear-vms.sh) e
> [`scripts/docker-mapear-containers.sh`](../scripts/docker-mapear-containers.sh) em **todos os 4
> hosts** — consulta `qm config`/`qm guest agent`, com fallback de captura passiva no `tap` (MAC da
> própria VM) e, no cluster Docker, inspeção direta dos containers. Dados brutos em
> `config/proxmox-hubsoft/`, `config/proxmox-zabbix/`, `config/proxmox-docker/`,
> `config/proxmox-dns/`. **Nenhuma identidade errada em nenhum dos 4 clusters** — tudo que o Dude já
> apontava se confirmou, mais uma quantidade grande de sistemas novos (ver seções abaixo).
>
> ⚠️ **Correção da generalização anterior:** HubSoft e Zabbix realmente não têm VLAN tag nenhuma
> (público e privado no mesmo `vmbr0`) — mas o cluster **Docker/CDNTV usa VLAN tag** em parte das
> interfaces (macvlan com tag `18` e `38`). **Não é padrão único da casa** — cada cluster precisa
> ser avaliado individualmente antes de decidir o esquema de VLAN gerência privada/pública.

## Modelo

Cada cluster Proxmox = **1 host físico (hypervisor)** + **N VMs**, cada VM com IP próprio. O
hypervisor normalmente tem um IP de **gerência privada** — exceto o cluster Zabbix, que é um caso
à parte (ver abaixo). As VMs com IP público não passam pela CCR1036: saem por uma NIC/bridge
própria do host direto na VLAN 16 (rede de acesso). VMs com IP **privado** (fora do `/30` de
gerência) ainda têm o caminho de rede **não confirmado**.

## 1. Proxmox Docker (CDNTV)

> ✅ **Confirmado por consulta direta (2026-07-24)** — os 5 sistemas esperados bateram 100%, mais
> **2 VMs novas** (CdnTV-Origin, CdnTV-Edge) e uma quantidade grande de containers Docker rodando
> dentro da VM "Docker-Netpal", nunca documentados antes. Dados brutos em
> [`config/proxmox-docker/mapeamento-vms.csv`](../config/proxmox-docker/mapeamento-vms.csv) e
> [`docker-containers.csv`](../config/proxmox-docker/docker-containers.csv).

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox Docker - CDNTV** (hypervisor) | `192.168.116.122/30` | Dell Inc. | gerência privada — ✅ já no plano da CCR1036 (`ether3`) |
| OpenVPN - 2 (`OpenVPN2`) | `177.72.104.12` ✅ (+ `10.254.0.30` interno) | `62:B2:A1:0A:B1:AE` | VM pública |
| Fusion - VoIP - Painéis Simples (`Fusion-Painel-Simples`) | `177.72.104.25` ✅ | `0E:C8:34:76:59:4E` | VM pública |
| Fusion - VoIP - Elaborados - Full (`Fusion-Painel-Elaborados`) | `177.72.104.22` ✅ | `6E:26:1A:C9:19:CE` | VM pública |
| Aplicações /etc/scripts (`APP-ETC-SCRIPTS`) | `177.72.104.23` ✅ | `36:DC:89:9D:DA:5A` | VM pública |
| Opa ChatBot (`OPA.SUIT`) | `177.72.104.30` ✅ | `F6:C7:5C:8A:4A:A3` | VM pública |
| 🆕 CdnTV-Origin | `177.72.104.107` | `2A:B7:2D:D8:6E:A2` | VM pública — **fora do `/27`**; ✅ `vmbr2` sem tag, rede CDN/VLAN 23 |
| 🆕 CdnTV-Edge | `177.72.104.108` | `5E:68:F6:70:6E:0D` | VM pública — **fora do `/27`**; ✅ `vmbr2` sem tag, rede CDN/VLAN 23 |

MAC de fabricante **Dell** no hypervisor — consistente com ser hardware físico real, não uma VM.

**Importante:** o "OpenVPN - 2" `10.254.0.30` interno confirma por que o RB3011 tinha rota estática
`10.254.0.0/22` via `.12` — é o pool de clientes da própria VPN (decisão #8, [03](03-decisoes-pendentes.md)).

### 🆕 VM "Docker-Netpal" — o verdadeiro host Docker do cluster, 7 interfaces

Diferente das VMs acima (uma função cada), a VM `Docker-Netpal` (vmid 100) é quem roda o Docker de
verdade — 7 NICs em bridges/VLANs diferentes (`vmbr1`, `vmbr2` ✅ `.109`, `vmbr3` sem tag, `vmbr3`
tag `38`, `vmbr3` tag `18`, `vmbr15` ×2) — mapeamento completo das 7 fechado abaixo. Inspeção
direta dos containers (`docker-mapear-containers.sh`) revelou:

| Container | Rede | IP | Achado |
|---|---|---|---|
| `NTP_SERVER` | macvlan | `192.168.116.10` | 🆕 **É a origem do NTP de toda a rede** — o RB3011 aponta pra cá ([01](01-inventario-atual.md)) |
| `smokeping` | macvlan `IP-DNS-177.72.104.21` | `177.72.104.8` | 🆕 **Resolve o mistério do `.8`** — não é Hubsoft nem morto ([07](07-enderecamento-ip.md), [11](11-cruzamento-dude-devices.md)) |
| `unifi-controller` | macvlan | `177.72.104.2` | 🆕 novo, nunca catalogado |
| `Wiki` | macvlan | `177.72.104.3` | 🆕 novo — já citado genericamente na "escala real" do [07](07-enderecamento-ip.md) |
| `pdns-master1` | macvlan | `177.72.104.10` | 🆕 novo — stack PowerDNS separada da "DNS NetPal" |
| `pdns-slave` | macvlan | `177.72.104.11` | 🆕 novo |
| ~~`DNS2-Recursivo-104.21`~~ | macvlan | `177.72.104.21` | ✅ removido intencionalmente pelo usuário em 2026-08-05; não migra |
| `SEVERINO` | macvlan tag `18` | `192.168.15.74` | Resolve a interface `vmbr3` tag 18 da VM |
| `SpeedTest` | macvlan tag `38` | `177.93.247.138` | Resolve a interface `vmbr3` tag 38 — está no **segundo bloco público** (`177.93.240.0/21`) |
| `netbox-*` (4 containers), `phpipam-*` (3), `portainer`, `Nginx_Netpal`, `webserver` | redes Docker internas (172.x.x.x) | — | Ferramentas de gestão/infra (IPAM, proxy, dashboards) — não expõem IP público direto, sem impacto na migração do RB3011 |

✅ **Resolvido (2026-07-24)** — `ip -4 -o addr show` + `ip -o link show` dentro da `docker-netpal`
deram os MACs de cada interface física (`ensN`); cruzando com `docker network inspect --format
'{{.Options.parent}}'` das redes macvlan, o parent de cada uma bateu direto (sem precisar
adivinhar por MAC). Dump bruto em
[`config/proxmox-docker/docker-netpal-interfaces.txt`](../config/proxmox-docker/docker-netpal-interfaces.txt).

| Interface (VM) | MAC | Bridge (Proxmox) | Rede Docker (parent) |
|---|---|---|---|
| `ens18` | `F6:EF:DA:C8:5B:0B` | `vmbr1` | `IP-DNS-177.72.104.21` (nome histórico da macvlan) — 5 containers ativos: smokeping, pdns-master1, pdns-slave, unifi-controller e Wiki; DNS2 `.21` removido |
| `ens21` | `5A:D9:BF:85:6A:44` | `vmbr15` (1) | `MACVLAN` — rede do `NTP_SERVER` (`192.168.116.10`) |
| `ens1` | `C2:BB:BB:23:3A:B3` | `vmbr3` tag `18` | `MACVLAN-18-SEVERINO` — já confirmado antes |
| `ens23` | `36:56:3A:7B:40:A9` | `vmbr3` tag `38` | `MACVLAN-38-SPEED` — já confirmado antes |
| `ens20` | `1A:D7:AB:37:73:F6` | `vmbr3` sem tag | ⚠️ **nenhuma rede macvlan ativa aponta pra cá** |
| `ens22` | `62:57:F1:9B:D5:58` | `vmbr15` (2) | ⚠️ **nenhuma rede macvlan ativa aponta pra cá** |

🆕 **Achado:** `vmbr3` sem tag (`ens20`) e a segunda `vmbr15` (`ens22`) estão **up com link
detectado** (cabo conectado) mas **sem nenhuma rede Docker macvlan usando-as como parent** — só
existem redes órfãs com driver `null` (`MACVLAN-16-IPPUBLICO`, `NTPServer-1`, `NTP_SERVER_15`,
`SEVERINO`, `SpeedTest`, `MONSTA_17`), que não têm containers ativos. Interpretação mais provável:
**capacidade sobrando/não utilizada** (interfaces cabeadas mas sem função hoje) — a confirmar com
o usuário antes de assumir que dá pra remover essas 2 portas do plano de portas da migração; pode
ser resquício de configuração antiga (os nomes `null` sugerem redes criadas e depois abandonadas,
sem limpar).

## 2. Proxmox Zabbix — ⚠️ caso à parte, hypervisor parece estar direto no IP público

> ✅ **11 VMs confirmadas por consulta direta ao host (`proxmox3`), 2026-07-24** — todas batem com
> o Dude, nenhuma reclassificação necessária. `Dude-VLSul` tem um segundo IP (`100.6.6.4`, faixa
> CGNAT) ligado à participação dela em OSPF (confirmado pelo usuário) — não é anomalia.

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **"Proxmox Zabbix"** | `177.72.104.5` | **Hewlett Packard** | ⚠️ ver nota abaixo |
| Zabbix | `177.72.104.6` ✅ | `4E:01:6C:C9:F0:78` | VM pública |
| Fusion - VoIP - PM CPV (`Fusionpbx-PM-CPV`) | `177.72.104.14` ✅ | `EE:2A:8A:5A:EE:E0` | VM pública |
| Fusion - VoIP - 0800 NETPAL (`Fusion-0800-Netpal`) | `177.72.104.18` ✅ | `16:8C:EF:D4:03:FD` | VM pública |
| Zeus - TIP - VoIP (`TIP-VOIP`) | `177.72.104.13` ✅ | `8A:26:35:E8:3A:BF` | VM pública |
| DOCS Cloud (`Docs`) | `177.72.104.7` ✅ | `B2:63:2D:95:56:FD` | VM pública |
| Servidor VPN (`OVPN`) | `177.72.104.9` ✅ | `56:EC:57:EB:68:14` | VM pública |
| Fusion - VoIP - PM MST (`Fusionpbx-PM-MST`) | `177.72.104.17` ✅ | `1A:97:C3:E0:DC:D3` | VM pública |
| SFTP - Netpal - OPA (`SFTP-OPA-CHAT`) | `177.72.104.20` ✅ | `F2:19:E1:4A:8C:8A` | VM pública |
| Dude VLSUL (`Dude-VLSul`) | `192.168.17.38` ✅ (+ `100.6.6.4`, ligado a OSPF) | `DE:5F:56:B1:1A:14` | VM **privada**, sem IP público |
| Dude PM CPV (`Dude-PM-CPV`) | `192.168.17.42` ✅ | `22:C6:6C:11:AB:E3` | VM **privada**, sem IP público |
| Servidor Monsta (`Monsta`) | `192.168.115.62` ✅ | `E2:E9:C9:DC:BA:BF` | VM **privada**, sem IP público |

Todas as 11, sem exceção, estão no mesmo `vmbr0`, **sem VLAN tag** — público e privado convivem no
mesmo domínio L2 hoje (ver nota no topo do documento).

⚠️ **Diferente dos outros 3 clusters, não existe nenhum IP de gerência privada para este
hypervisor no Dude.** O device chamado literalmente `"Proxmox Zabbix"` está no IP **público**
`177.72.104.5` e tem MAC de fabricante real (**Hewlett Packard**) — evidência de que é hardware
físico, não uma VM.

✅ **Confirmado (usuário, 2026-07-23):** hipótese (a) procede — **é standalone** (não faz parte de
cluster Proxmox, então trocar o IP não exige reconfigurar corosync/quorum) e tem **~10 VMs**
(bate com a contagem daqui: 8 públicas + 3 privadas = 11, ordem de grandeza consistente).
Isso confirma que migrar esse host é redesenho (dar a ele gerência privada pela primeira vez), não
só reapontar gateway — mas também confirma que é a operação **mais simples possível** desse tipo
(sem cluster pra coordenar).

**Ainda falta confirmar** antes da troca: se algo está amarrado no `.5` como IP do host em si
(GUI/API do Proxmox porta `8006`, job de backup, allowlist de firewall) — ver checklist de troca
em [03-decisoes-pendentes.md](03-decisoes-pendentes.md), decisão #12.

## 3. Proxmox HubSoft

> ✅ **2 VMs confirmadas por consulta direta ao host (`px-hubsoft`), 2026-07-24** — batem exatamente.

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox HubSoft** (hypervisor) | `192.168.115.210/30` ✅ **confirmado por `ip addr` direto no host (2026-07-24)** | Dell Inc. | gerência privada — ⚠️ fora do plano da CCR1036 (decisão #12) |
| HubSoft (`HUBSOFT`) | `177.72.104.16` ✅ | `72:56:05:A7:29:E9` | VM pública |
| Radius HubSoft (`HUBSOFT-RADIUS`) | `192.168.115.214` ✅ | `96:4F:38:AB:86:21` | VM **privada**, sem IP público |

MAC **Dell** de novo no hypervisor — mesmo padrão do cluster Docker.
`192.168.115.214` (Radius HubSoft) já aparecia na lista `FORA_DO_NAT_RADIUS` do RB3011
([07](07-enderecamento-ip.md)) — agora sabe-se de qual VM/cluster é. Assim como no Zabbix, **as duas
VMs estão no mesmo `vmbr0` sem VLAN tag** — público e privado juntos no mesmo domínio L2.

## 4. Proxmox DNS

> ✅ **Confirmado por consulta direta (`proxmox-dns`), 2026-07-24** — 4 VMs, incluindo a resolução
> de `.26` (mistério antigo, ver [07](07-enderecamento-ip.md)/[11](11-cruzamento-dude-devices.md))
> e a descoberta de que `.28` e `.58` são o mesmo host. Dados brutos em
> [`config/proxmox-dns/mapeamento-vms.csv`](../config/proxmox-dns/mapeamento-vms.csv).

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox DNS** (hypervisor) | ~~`192.168.115.138/30`~~ → ✅ `192.168.254.12/24` (VLAN 100, concluído em 2026-08-05) | Hewlett Packard | gerência privada; gateway `192.168.254.1`; IP e gateway antigos removidos |
| OLT CLOUD (`OLT-CLOUD`) | `177.72.104.24` ✅ | `BC:24:11:89:AD:23` | VM pública (Web Server) |
| DNS MASTER / NetPal (`NS-UNBOUND`) | `177.72.104.28/27` + `.58/32` + `.59/32` ✅ | `BC:24:11:E7:B0:75` | VM pública — **um único host com três IPs**; `.58`/`.59` são secundários/loopbacks |
| AUTOMACOES | `177.72.104.29` ✅ | `BC:24:11:BF:0B:B5` | VM pública (Web Server) |
| 🆕 API-ZAP | `177.72.104.26` | `BC:24:11:50:14:F9` | VM pública — **resolve o mistério do `.26`**. ~~Provável destino da notificação da decisão #6~~ descartado (2026-07-24): o script `dude` do RB3011 chama `api.focuschat.com.br` direto, sem host local — função real de API-ZAP segue desconhecida |

## Resumo — o que falta pra fechar o endereçamento

> ✅ **Os 4 clusters foram consultados diretamente (2026-07-24)** — endereçamento das VMs 100%
> confirmado. O que resta é decisão de desenho (portas/VLANs na CCR1036), não mais incerteza de IP.

| Item | Status |
|---|---|
| Gerência do cluster Docker na CCR1036 | ✅ no plano (`ether3`) |
| Gerência dos clusters HubSoft e DNS | DNS ✅ concluído em `192.168.254.12/24`; HubSoft ❌ adiado para CCR/Datacom (decisão #12) |
| Gerência do cluster Zabbix | ✅ confirmado standalone, sem gerência privada hoje (checklist da decisão #12) |
| VMs privadas fora do `/30` de gerência (Radius HubSoft, Dude VLSUL, Dude PM CPV, Servidor Monsta) | ✅ IPs confirmados por consulta direta — ❌ caminho de rede (VLAN dedicada) ainda não definido |
| VMs públicas (19 no total) | ✅ regra geral: VLAN 16 sem passar pela CCR1036; **exceção confirmada:** CdnTV `.107`/`.108` e `.109` usam a rede própria `/29` pela `vmbr2` untagged/VLAN 23 |
| Separação público/privado nos hosts HubSoft e Zabbix | ❌ hoje não existe — todas as VMs dividem o mesmo `vmbr0` sem VLAN. Precisam de bridge VLAN-aware + tag por VM pra caber no modelo de gerência privada/pública do desenho alvo |
| Separação público/privado no host Docker/CDNTV | ✅ **já existe parcialmente** — usa VLAN tag (`18`, `38`) em parte das interfaces macvlan; não é o mesmo problema do HubSoft/Zabbix |
| 🆕 Sistemas descobertos sem relação com o RB3011 (NetBox, phpIPAM, Portainer, PowerDNS, NTP server, UniFi, Wiki, Smokeping, API-ZAP) | ✅ identificados — impacto na migração é indireto (definem a origem real do NTP; a notificação da decisão #6 não depende de nenhum deles — vai direto pra `api.focuschat.com.br`), mas não mudam o desenho de rede do DM4170/CCR1036 |
| 🆕 `.107`, `.108`, `.109` (CdnTV) e `177.93.247.138` (SpeedTest) | ✅ CDN confirmado fora do `/27`: `.107`/`.108`/`.109` usam `vmbr2`/`enp8s0f0` untagged até a VLAN 23 no NE8000; SpeedTest continua em caminho próprio |

Ver decisões #6, #9 e #12 em [03-decisoes-pendentes.md](03-decisoes-pendentes.md).
