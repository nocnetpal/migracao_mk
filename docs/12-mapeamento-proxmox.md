# Mapeamento de IPs — clusters Proxmox

> Fonte: `docs/Devices.csv` (Dude), cruzado com [07-enderecamento-ip.md](07-enderecamento-ip.md)
> (regras do RB3011) e [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md) (plano de portas
> da CCR1036). Todos os IPs, sem omitir nenhum.

## Modelo

Cada cluster Proxmox = **1 host físico (hypervisor)** + **N VMs**, cada VM com IP próprio. O
hypervisor normalmente tem um IP de **gerência privada** — exceto o cluster Zabbix, que é um caso
à parte (ver abaixo). As VMs com IP público não passam pela CCR1036: saem por uma NIC/bridge
própria do host direto na VLAN 16 (rede de acesso). VMs com IP **privado** (fora do `/30` de
gerência) ainda têm o caminho de rede **não confirmado**.

## 1. Proxmox Docker (CDNTV)

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox Docker - CDNTV** (hypervisor) | `192.168.116.122/30` | Dell Inc. | gerência privada — ✅ já no plano da CCR1036 (`ether3`) |
| OpenVPN - 2 | `177.72.104.12` | — | VM pública |
| Fusion - VoIP - Painéis Simples | `177.72.104.25` | — | VM pública |
| Fusion - VoIP - Elaborados - Full | `177.72.104.22` | — | VM pública |
| Aplicações /etc/scripts | `177.72.104.23` | — | VM pública |
| Opa ChatBot | `177.72.104.30` | — | VM pública |

MAC de fabricante **Dell** no hypervisor — consistente com ser hardware físico real, não uma VM.

## 2. Proxmox Zabbix — ⚠️ caso à parte, hypervisor parece estar direto no IP público

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **"Proxmox Zabbix"** | `177.72.104.5` | **Hewlett Packard** | ⚠️ ver nota abaixo |
| Zabbix | `177.72.104.6` | — | VM pública |
| Fusion - VoIP - PM CPV | `177.72.104.14` | — | VM pública |
| Fusion - VoIP - 0800 NETPAL | `177.72.104.18` | — | VM pública |
| Zeus - TIP - VoIP | `177.72.104.13` | — | VM pública |
| DOCS Cloud | `177.72.104.7` | — | VM pública |
| Servidor VPN | `177.72.104.9` | — | VM pública |
| Fusion - VoIP - PM MST | `177.72.104.17` | — | VM pública |
| SFTP - Netpal - OPA | `177.72.104.20` | — | VM pública |
| Dude VLSUL | `192.168.17.38` | — | VM **privada**, sem IP público |
| Dude PM CPV | `192.168.17.42` | — | VM **privada**, sem IP público |
| Servidor Monsta | `192.168.115.62` | — | VM **privada**, sem IP público |

⚠️ **Diferente dos outros 3 clusters, não existe nenhum IP de gerência privada para este
hypervisor no Dude.** O device chamado literalmente `"Proxmox Zabbix"` está no IP **público**
`177.72.104.5` e tem MAC de fabricante real (**Hewlett Packard**) — evidência de que é hardware
físico, não uma VM. Duas hipóteses:
- **(a)** Este hypervisor não tem gerência privada separada — a própria interface física do
  servidor está no bloco público. Também é o mesmo IP usado pelas regras "Hubsoft"/"CallSys" no
  firewall do RB3011 (multiplexado por porta) — pode ser coincidência de numeração com outra
  função, ou o mesmo host acumulando papéis.
- **(b)** Existe gerência privada, mas não está cadastrada no Dude.

O plano da CCR1036 (`ether5`, "mgmt privada nova") já assume que este cluster **vai ganhar** uma
gerência privada nova — ou seja, se a hipótese (a) for verdadeira, isso não é só "migrar", é
**redesenhar** esse host pra sair do modelo atual (hypervisor com IP público direto).
**Confirmar com o usuário antes de seguir.**

## 3. Proxmox HubSoft

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox HubSoft** (hypervisor) | `192.168.115.210/30` | Dell Inc. | gerência privada — ⚠️ fora do plano da CCR1036 |
| HubSoft | `177.72.104.16` | — | VM pública |
| Radius HubSoft | `192.168.115.214` | — | VM **privada**, sem IP público |

MAC **Dell** de novo no hypervisor — mesmo padrão do cluster Docker.
`192.168.115.214` (Radius HubSoft) já aparecia na lista `FORA_DO_NAT_RADIUS` do RB3011
([07](07-enderecamento-ip.md)) — agora sabe-se de qual VM/cluster é.

## 4. Proxmox DNS

| Host/VM | IP | MAC (fabricante) | Tipo |
|---|---|---|---|
| **Proxmox DNS** (hypervisor) | `192.168.115.138/30` | Hewlett Packard | gerência privada — ⚠️ fora do plano da CCR1036 |
| OLT CLOUD | `177.72.104.24` | — | VM pública (Web Server) |
| DNS MASTER | `177.72.104.58` | — | VM pública (DNS Server) |
| AUTOMACOES | `177.72.104.29` | — | VM pública (Web Server) |

## Resumo — o que falta pra fechar o endereçamento

| Item | Status |
|---|---|
| Gerência do cluster Docker na CCR1036 | ✅ no plano (`ether3`) |
| Gerência dos clusters HubSoft e DNS na CCR1036 | ❌ faltam porta/VLAN (decisão #12) |
| Gerência do cluster Zabbix | ⚠️ pode não existir hoje — confirmar hipótese (a)/(b) acima antes de planejar |
| VMs privadas fora do `/30` de gerência (Radius HubSoft, Dude VLSUL, Dude PM CPV, Servidor Monsta) | ❌ caminho de rede não definido |
| VMs públicas (17 no total, listadas acima) | ✅ modelo definido: segunda NIC/bridge direto na VLAN 16, sem passar pela CCR1036 |

Ver decisões #9 e #12 em [03-decisoes-pendentes.md](03-decisoes-pendentes.md).
