# 18 — Acesso remoto na virada: WireGuard na CCR com origem 177.72.104.19

> 🆕 **Criado 2026-08-07.** O pessoal vai retirar o **RB2011 e o RB750** (WireGuard `.19`) —
> o plano original dizia que o RB750 ficava até o WG migrar **pós-migração**; agora a retirada
> acontece **na própria janela**, então o WireGuard precisa subir na **CCR1036** antes (Etapa A).
> O usuário opera **remoto** (outra internet) e o acesso depende desta VPN.

## Decisão (usuário, 2026-08-07 — revisada no mesmo dia)

- 🆕 **Abordagem A (recomendada e escolhida): WireGuard na CCR com endpoint
  `177.72.104.15`** (o IP de NAT da CCR) — só para o operador acessar durante a janela. É a
  mais simples: o `.15` já é IP da CCR (**sem conflito ARP** com o RB750) e, com
  **SRC-NAT do pool → `.15`**, o retorno sempre volta para a CCR (não depende do OSPF
  anunciar o pool — e não colide com o anúncio do RB750 enquanto ele estiver no ar).
  Origem `.15` já liberada: NE8000 rule 70 (VS e PPPOE — `/27` inteiro), DM4170 whitelist
  (`/27`), CCR forward (vê `10.150.150.0/24`).
- **Variante B (descartada por ora): origem `.19`** — exigiria IP secundário `.19` na CCR,
  esperar o RB750 sair (ARP duplicado) e SRC-NAT→`.19`. Mantida como opção pós-virada se
  quiserem preservar o endereço histórico.
- **Revisa a decisão #5** (WireGuard só pós-migração) → WG entra **na Etapa A da noite**;
  **revisa a decisão #2** (RB750 "fica até a VPN migrar") → RB750 **sai na janela** (2026-08-12→13).

## Desenho

```
Você remoto → Internet → 177.72.104.15:13231 (WG na CCR, VLAN 16)
                        → CCR (wg1 · pool 10.150.150.0/24)
                        → SRC-NAT → origem .15 (IP da CCR)
                        → default via .1 → NE8000 (.240/.241/.242) ✓
                        → VLANs privadas (100/15/66/109/116) ✓
```

| Item | Valor | Obs |
|---|---|---|
| Endpoint WG | `177.72.104.15:13231` | IP de NAT da CCR — sem conflito ARP |
| IP do servidor WG | `10.150.150.1/24` | pool mantido |
| Peer (janela) | `10.150.150.x/32` — só o operador (Leonardo) | novo peer na CCR |
| SRC-NAT | `10.150.150.0/24 → 177.72.104.15` | retorno sempre volta p/ CCR — não precisa anunciar o pool no OSPF |
| OSPF do pool | **não anunciar** (SRC-NAT resolve) | evita dupla origem com o RB750 |

## ⚠️ Cuidados técnicos

1. ~~**ARP duplicado (variante B/.19)**~~ — não se aplica à abordagem A (o `.15` é IP da CCR).
   O RB750 pode continuar no ar com o `.19` sem conflito.
2. **Firewall da CCR:** liberar **UDP/13231 no input** (hoje o input é restrito:
   established/.19/NOC/drop — sem isso o handshake WG é descartado).
3. **OSPF do pool:** **não anunciar** — o SRC-NAT→`.15` faz o retorno voltar sempre para a CCR.
   (Anunciar só se no futuro quiserem clientes WG alcançáveis de dentro, após a saída do RB750.)
4. **Chave WG:** a CCR gera **par novo** (não reutilizar a do RB750) — é só **um client** na
   janela (o operador), atualizar a public-key no device dele.

## Config proposta na CCR (bancada, segunda-feira — aplicar com WG disabled)

```rsc
# Interface WireGuard (anotar a public-key gerada — vai no client)
/interface wireguard add name=wireguard1 listen-port=13231 mtu=1380
/ip address add address=10.150.150.1/24 interface=wireguard1 comment="WG SERVIDOR"

# Peer do operador (Leonardo) — só ele na janela; public-key = chave pública do client
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.5/32 comment="Leonardo REMOTO" public-key="…" persistent-keepalive=25s

# SRC-NAT do pool → .15 (IP da CCR — retorno volta sempre para ela)
/ip firewall nat add chain=srcnat src-address=10.150.150.0/24 action=src-nat to-addresses=177.72.104.15 comment="WG REMOTO ORIGEM .15"

# Liberar o handshake no input
/ip firewall filter add chain=input protocol=udp dst-port=13231 action=accept comment="WIREGUARD REMOTO"

# ⚠️ NÃO anunciar o pool no OSPF (SRC-NAT resolve o retorno; evita dupla origem com o RB750)
```
> No client (device do operador): endpoint `177.72.104.15:13231` + a public-key da CCR.
> Não depende da saída do RB750 — só do trunk da CCR subir (Etapa A).

## Ordem na noite (2026-08-12→13)

1. Etapa A: cabos da CCR (XS2 ↔ sfp1) e do NE8000 (GE0/1/3 ↔ XS1) — validar L2
2. Na CCR: habilitar `wireguard1` (endpoint `.15:13231`) — **não precisa esperar o RB750 sair**
3. Operador remoto conecta: handshake WG OK → `ping 10.200.255.241/242` → SSH no NE8000 → alcançar VLAN 100/privadas
4. Pessoal retira **RB2011 + RB750** (a partir daqui o `.19` deixa de existir)
5. Pós-virada: decidir se mantém o `.15` (recomendado) ou replica o `.19` (variante B)

## Rollback

- Se o WG da CCR não funcionar: o RB750 permanece configurado até a retirada — o operador usa o WG antigo (`.19`) como reserva enquanto ele existir.
- Depois da retirada: RB750/RB2011 ficam desligados mas configurados por N semanas (rollback físico — fase 4 do plano).


## 🆕 Dois WireGuards na CCR (decisão 2026-08-10)

A CCR sobe **os dois WGs que hoje vivem no RB750** (que sai na janela):

| Interface | Porta | Rede | IP na CCR | Uso |
|---|---|---|---|---|
| wireguard1 | 13231 | 10.150.150.0/24 | 10.150.150.1/24 | VPN usuários/equipe — remoto (endpoint .15) |
| wg-mgmt | 51820 | 10.99.0.0/24 (+10.90.0.0/22) | 10.99.0.1/24 | gerência Condominio RARO (peer26, public-key em config/rb750gr3-wireguard/) |

Replicar na CCR:
- peer26 do wg-mgmt (allowed-address 10.99.0.2/32,10.90.0.0/22) + chave pública salva
- firewall do wg-mgmt (RB750): accept wg-mgmt→wg-mgmt; drop dst 10.90.0.0/16 fora do wg-mgmt
- SRC-NAT do wg-mgmt → .15 (mesma lógica do wireguard1: retorno sempre volta p/ CCR)
- ⚠️ O lado cliente (RARO) precisa atualizar: endpoint → 177.72.104.15:51820 + public-key nova da CCR

## Pendências para segunda-feira

- [x] Abordagem A escolhida: endpoint `.15` (2026-08-07)
- [ ] Aplicar a config acima na CCR (wg1 + peer do operador + SRC-NAT→.15 + UDP/13231)
- [ ] Atualizar o device do operador: endpoint `177.72.104.15:13231` + public-key da CCR
- [ ] Registrar o wg1 no monitoramento/backup da CCR
