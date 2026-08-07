# 18 — Acesso remoto na virada: WireGuard na CCR com origem 177.72.104.19

> 🆕 **Criado 2026-08-07.** O pessoal vai retirar o **RB2011 e o RB750** (WireGuard `.19`) —
> o plano original dizia que o RB750 ficava até o WG migrar **pós-migração**; agora a retirada
> acontece **na própria janela**, então o WireGuard precisa subir na **CCR1036** antes (Etapa A).
> O usuário opera **remoto** (outra internet) e o acesso depende desta VPN.

## Decisão (usuário, 2026-08-07)

- **Manter o IP `177.72.104.19` como origem da VPN na CCR** — em vez de usar o `.15`:
  todos os firewalls/ACLs já liberam o `.19` (NE8000 rule 11 da VS, input da CCR, whitelist do
  DM4170 via `/27`). Zero mudança nos acessos existentes.
- **Revisa a decisão #5** (WireGuard só pós-migração) → WG entra **na Etapa A da noite**;
  **revisa a decisão #2** (RB750 "fica até a VPN migrar") → RB750 **sai na janela** (2026-08-12→13).

## Desenho

```
Você remoto → Internet → 177.72.104.19:13231 (WG na CCR, VLAN 16)
                        → CCR (wg1 · pool 10.150.150.0/24)
                        → SRC-NAT → origem .19
                        → default via .1 → NE8000 (.240/.241/.242) ✓
                        → VLANs privadas (100/15/66/109/116) ✓
```

| Item | Valor | Origem |
|---|---|---|
| Endpoint WG | `177.72.104.19:13231` | igual ao RB750 — clientes não mudam endpoint |
| IP do servidor WG | `10.150.150.1/24` | pool mantido |
| Peers | `10.150.150.2/.4/.5/.6/.7/.8` (Leonardo, Bruno, Regis…) | idênticos ao RB750 |
| SRC-NAT | `10.150.150.0/24 → 177.72.104.19` | mesma regra do RB750 |
| IP secundário na CCR | `177.72.104.19/27` na VLAN 16 | **disabled** até o RB750 sair |

## ⚠️ Cuidados técnicos

1. **ARP duplicado:** enquanto o RB750 estiver no ar com o `.19`, a CCR **não pode** ativar o
   `.19` (dois donos = ARP flap). Sequência: cabos da CCR (trunk) → pessoal tira
   RB750/RB2011 → **habilitar `.19` + WG na CCR** → usuário conecta.
2. **Firewall da CCR:** liberar **UDP/13231 no input** (hoje o input é restrito:
   established/.19/NOC/drop — sem isso o handshake WG é descartado).
3. **OSPF do pool:** a CCR não pode anunciar `10.150.150.0/24` enquanto o RB750 o anunciar
   (dupla origem). Anunciar passivamente **depois** da saída do RB750.
4. **Chave WG — pendência (decidir segunda-feira):** (a) CCR gera par novo → atualizar a chave
   pública nos clients; ou (b) **reutilizar a chave privada do RB750** → zero mudança nos
   clients (migração instantânea; risco da chave já ter sido usada).

## Config proposta na CCR (bancada, segunda-feira — aplicar com WG disabled)

```rsc
# IP secundário .19 (origen VPN — DISABLED até o RB750 sair)
/ip address add address=177.72.104.19/27 interface=vlan16-PUBLICA comment="ORIGEM VPN WG (era RB750 .19)" disabled=yes

# Interface WireGuard (pegar a public-key gerada para os clients)
/interface wireguard add name=wireguard1 listen-port=13231 mtu=1380
/ip address add address=10.150.150.1/24 interface=wireguard1 comment="WG SERVIDOR"

# Peers (idênticos ao RB750 — conferir public-keys no export rb750gr3-wireguard)
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.2/32 comment="Leonardo" public-key="…" persistent-keepalive=25s
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.4/32 comment="Leonardo PC CASA" public-key="…" persistent-keepalive=25s
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.5/32 comment="Leonardo IPHONE" public-key="…" persistent-keepalive=25s
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.6/32 comment="Bruno" public-key="…" persistent-keepalive=25s
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.7/32 comment="Leonardo" public-key="…" persistent-keepalive=25s
/interface wireguard peers add interface=wireguard1 allowed-address=10.150.150.8/32 comment="PC Regis" public-key="…" persistent-keepalive=25s

# SRC-NAT do pool → .19 (mesma do RB750)
/ip firewall nat add chain=srcnat src-address=10.150.150.0/24 action=src-nat to-addresses=177.72.104.19 comment="WG REMOTO ORIGEM .19"

# Liberar o handshake no input
/ip firewall filter add chain=input protocol=udp dst-port=13231 action=accept comment="WIREGUARD REMOTO"

# OSPF passivo do pool — só DEPOIS do RB750 sair (senão dupla origem)
# /routing ospf interface-template add area=area0.0.0.1 interfaces=wireguard1 passive comment="OSPF PASSIVA WG"

# Deixar tudo desligado até a hora:
/interface wireguard disable wireguard1
```

## Ordem na noite (2026-08-12→13)

1. Etapa A: cabos da CCR (XS2 ↔ sfp1) e do NE8000 (GE0/1/3 ↔ XS1) — validar L2
2. Pessoal retira **RB2011 + RB750**
3. Na CCR: habilitar `wireguard1` + IP `.19` (desabilitar o disabled) + (se aplicável) OSPF passivo do pool
4. Clientes: se chave nova, atualizar a public-key do servidor; se reutilizou a do RB750, **nada a mudar**
5. Validação remota (de outra internet): handshake WG OK → `ping 10.200.255.241/242` → SSH no NE8000 → alcançar VLAN 100/privadas

## Rollback

- Se o WG da CCR não funcionar: religar o RB750 (ele permanece configurado) — o `.19` volta para ele; a CCR desativa o `.19` e o wg1.
- O RB750/RB2011 ficam desligados mas configurados por N semanas (rollback físico — fase 4 do plano).

## Pendências para segunda-feira

- [ ] Decidir chave WG: nova (atualizar clients) ou reutilizar a do RB750
- [ ] Conferir as public-keys dos peers no export `config/rb750gr3-wireguard/export-2026-07-27.rsc`
- [ ] Aplicar a config acima na CCR (WG disabled)
- [ ] Registrar o IP `.19` e o wg1 no monitoramento/backup da CCR
