# Rotina de corte — runbook da janela de madrugada

> Este é o **runbook operacional** (passo a passo, com checkbox, pra seguir ao vivo na noite do
> corte). A justificativa e o desenho de cada decisão estão em
> [04-plano-migracao.md](04-plano-migracao.md) (estratégia) e
> [03-decisoes-pendentes.md](03-decisoes-pendentes.md) (decisões). Este documento **consome** os
> dois — não repete o raciocínio, só a sequência de execução.
>
> ## 🆕 Duas janelas distintas (2026-07-24)
>
> | Janela | O quê | Doc |
> |---|---|---|
> | **Etapa A** | Instalar DM4170 + CCR no NE8000 — **sem** corte de produção | [15 § Etapa A](15-plano-migracao-servidores-177.md) — checklist lá; não precisa madrugada |
> | **Etapa B** | Migrar só servidores `177.*` + virada `/27`/NAT; QinQ fica no RB3011 | [15 § Etapa B](15-plano-migracao-servidores-177.md) + seção **Etapa B** abaixo |
> | **Futura** | Troca QinQ `sfp1` + SVIs POP + desliga RB3011 | Restante deste runbook (T-14 / janela QinQ) |
>
> 🚨 **Etapa B ainda não está pronta pra agendar** enquanto o bloqueador #3 (teste da rota NAT
> `.15` → CCR no NE8000) estiver aberto. ~~e #8 (novo L2 para HubSoft/Zabbix)~~ ✅ concluído
> 2026-08-05. Os passos `⛔ BLOQUEADO` continuam válidos.

## 🚦 Bloqueadores — precisam fechar antes de marcar a data

| # | Bloqueador | Doc | Status |
|---|---|---|---|
| 1 | ~~SVI roteada sobre tag interna de QinQ no DmOS~~ | [03 #13](03-decisoes-pendentes.md) | ✅ **caiu (2026-07-24)** — decisão #13: DM4170 fica só L2, quem termina a SVI é o NE8000 |
| 2 | ~~MTU/baby giants nos dois trechos novos~~ | [03 #4](03-decisoes-pendentes.md) | ✅ **estratégia fechada (2026-07-24)** — jumbo frame máximo de cada equipamento; número concreto na hora de configurar |
| 3 | Mecanismo de NAT na CCR1036 — como o IP público chega nela | [03 #9](03-decisoes-pendentes.md) | ✅ **CCR dentro do `/27`** (~~`.4`~~ → 🆕 **`.15`** VLAN 16, troca 2026-08-07 — LoopBack1 `.4/32` do NE8000; ver `config/ne8000/check-177.72.104.15-livre-2026-08-07.md`); ~~`/32` P2P~~ descartado; falta testar + DST-NAT na CCR `.15` |
| 4 | ~~Sobreposição `177.72.104.60/30`~~ | [03 #10](03-decisoes-pendentes.md) | ✅ **investigado e resolvido (2026-07-24)** — não é conflito real, NE8000 não tem interface nesse /30 |
| 5 | ~~Estratégia da chave OSPF MD5 da area1 no corte~~ | [03 #11](03-decisoes-pendentes.md) | ✅ **fechado (2026-07-24)** — Opção A: mantém a chave atual no corte, rotaciona na fase 4 |
| 6 | ~~Variante da CCR1036~~ | [02](02-arquitetura-alvo.md) | ✅ **decidido (2026-07-24): 8G-2S+** |
| 7 | Passo 1 da limpeza — quais sistemas do firewall antigo ainda estão vivos | [05](05-limpeza-politicas.md) | 🟡 conscientemente adiado (2026-07-24) — voltar depois de fechar o resto |
| 8 | ~~Portas/VLANs Proxmox HubSoft e Zabbix~~ | [03 #12](03-decisoes-pendentes.md) | ✅ **concluído (2026-08-05):** os 4 hypervisors estão `.10`–`.13` na VLAN 100; públicas tag 16, privadas untagged. Portas antigas RB750 `ether3/ether4` desativadas — ver [16](16-etapa1-proxmox-vlans-datacom.md) |
| 9 | ~~Destino final das automações (backup FTP, netwatch→API)~~ | [03 #6](03-decisoes-pendentes.md) | ✅ **fechado (2026-07-24)** — as duas descartadas, não migram, nada a implementar aqui |
| 10 | ~~VPN nova durante a migração~~ | [03 #5](03-decisoes-pendentes.md) | ✅ retirada da janela: WireGuard somente pós-migração |
| 11 | Solução de acesso do NOC (EoIP morre com o MK) | [03 #8](03-decisoes-pendentes.md) | 🟡 NE8000 já libera `177.93.244.165` direto na ACL de gerência — provavelmente já resolvido, falta confirmar |
| 12 | ~~Dimensionamento do NE8000 para +30 subinterfaces/adjacências OSPF novas~~ | [03 #13](03-decisoes-pendentes.md) | ✅ **confirmado (2026-07-24): capacidade livre** |

**Dos bloqueadores originais, resta de verdade o teste do mecanismo de rota do item 3
(NAT/CCR1036).** O item 8 foi concluído. Os
itens 7, 10 e 11 podem correr em paralelo até a véspera; o 7 foi conscientemente deixado pro final.

---

## Etapa B — runbook servidores 177 (QinQ permanece no RB3011)

> Pré-condição: **Etapa A pronta** ([15 § A.7](15-plano-migracao-servidores-177.md)). Lista de
> hosts: [14](14-ips-servidores-e-17772.md). Detalhe de escopo: [15](15-plano-migracao-servidores-177.md).

### 🆕 Acesso garantido ao NE8000 (checklist — 2026-08-07)

> Regra de ouro: **caminho novo sobe e valida ANTES de derrubar o antigo.** Nunca remover o
> `.1/27` do RB3011 (ou derrubar VLAN 28/VE .1014) sem SSH alternativo validado.

- [x] LoopBacks de gerência criadas (2026-08-07): `10.200.255.241/32` (PPPOE, chassi) e
      `10.200.255.242/32` (BGP_NETPAL, VS) — anunciadas no OSPF area 0.0.0.1. Registro:
      `config/ne8000/loopbacks-gerencia-2026-08-07.md`
- [ ] Testar SSH ao NE8000 por `10.200.255.241` e `10.200.255.242` **de fora** (RB3011/RB750/NOC)
- [ ] Confirmar ping `10.200.255.241` do RB3011/RB750 antes de qualquer janela
- [ ] Gerência local `192.168.15.2` validada (caminho próprio 2026-08-05 — doc 03)
- [ ] Console do NE8000 acessível no rack (último recurso da janela)
- [ ] Atualizar o Dude: "BGP - Jardim Formoso" sai de `177.72.104.54` → `10.200.255.242`
- [ ] Na janela QinQ: novo router-id/source do BGP FlowSpec (`.27` fica diretamente conectado
      quando o `/27` subir — decisão #8) e NetStream source saindo do `.54`

### Pré-corte Etapa B

- [ ] Critério de pronto da Etapa A OK (pings mgmt; FlowSpec/NetStream intactos via caminho antigo)
- [ ] Rota ~~`177.72.104.4`~~ 🆕 **`177.72.104.15`** → CCR testada no NE8000 (bloqueador #3) — ⛔ se aberto
- [ ] SFP-RJ45 instalados nas portas do mapa [15 § A.5](15-plano-migracao-servidores-177.md)
- [ ] Script de rollback escrito: repor `177.72.104.1/27` no RB3011 + `shutdown` SVI no NE8000 +
      religar cabo na porta antiga (RB2011/RB750/RB3011)
- [ ] NAT na CCR ainda **desabilitado** até o corte L3 do `/27`

### Ordem de hosts (um a um)

| # | Host | Validar após plugar |
|---|---|---|
| 1 | RRFlow `.27` | Sessão FlowSpec + NetStream `:3055` no **novo** caminho |
| 2 | Proxmox Docker/CDNTV + containers 177 | Ping GW; HTTP/serviços públicos |
| 3 | Proxmox Zabbix `.10` + VMs 177 | ✅ L2 organizado; Ping GW; Zabbix/OVPN |
| 4 | Proxmox HubSoft `.13` + VM `.16` | ✅ L2 organizado |
| 5 | Proxmox DNS `.12` (`.24` `.26` `.28`/`.58` `.29`) | ✅ L2 organizado; resolver DNS |
| 6 | Demais 177 (WireGuard `.19`, CGNAT `.66`, …) | Conforme [14](14-ips-servidores-e-17772.md) |

Por host:

- [ ] Plugar na porta GE do DM4170 (SFP-RJ45); segunda NIC / bridge VLAN 16 se tiver IP público
- [ ] Gateway do host: RB3011 `.1` → NE8000 (quando o `/27` já tiver virado) **ou** manter `.1` no
      RB3011 até o corte L3 único abaixo
- [ ] Ping gateway, DNS, serviço público, ARP no DM4170

### Corte L3 do `/27` (momento único)

- [ ] Remover `177.72.104.1/27` (e anúncio OSPF do `/27`) do RB3011
- [ ] Ativar SVI/anúncio do `/27` no NE8000
- [ ] Ativar NAT na CCR (~~`.4`~~ 🆕 `.15`) + DST-NAT Dude/TS SIX se esses hosts já migraram
- [ ] RB2011: só o que for bridge de servidor — **não** mexer no `sfp1` QinQ. RB750 **não se mexe**:
      permanece ativo com o WireGuard `.19` (migra pós-corte)

### Rollback Etapa B

Religar servidor na porta antiga; se o `/27` já virou, rodar o script da véspera (`.1` de volta no
RB3011, SVI NE8000 down, NAT CCR off).

---

## Janela futura — QinQ / descomissionamento RB3011

> O que segue (T-14, T-1, janela) é o corte do trunk QinQ + núcleo completo. **Não executar** na
> mesma noite da Etapa B. Etapa A cobre a parte “montar DM4170+CCR sem produção”; não duplicar
> aqui o checklist da A.

## T-14 dias: preparação QinQ (sem tocar em produção)

- [ ] Fechar o bloqueador restante acima (**#3** — teste da rota NAT; os 🟡 #7 e #11 podem correr
      em paralelo). ~~2, 5, 6, 12~~ ✅ todos fechados
- [ ] 🆕 Montar a config do **DM4170** em bancada — **só L2** (decisão #13): QinQ termination de
      todas as VLANs de acesso, trunk 802.1q pro NE8000, ACL de gerência no padrão
      `IPV4_NOC_NETPAL`. **Nenhuma SVI, nenhum OSPF nele.** 🆕 Incluir também: portas dos
      servidores locais (com transceiver SFP-RJ45 — a confirmar) + trunk novo pra CCR1036 com as
      VLAN 16 + VLANs privadas (100, 15/NTP e demais; ver [02](02-arquitetura-alvo.md))
- [ ] 🆕 Montar no **NE8000** as SVIs + adjacências OSPF area1 das ~50 VLANs de acesso (27 QinQ +
      2 simples de serviço; VLAN 15/NTP vai para a CCR) — mesmo padrão que já usa hoje pras VLANs
      de POP (`MK_POP_*`) — ver [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)
- [x] Base da CCR1036 montada em bancada (2026-08-06): RouterOS/RouterBOOT 7.23.3, VLANs 16/100,
      ~~`.4/27`~~ 🆕 `.15/27` (troca 2026-08-07 — reconfigurar), `.1/24`, SRC-NAT e firewall
      ativos, isolados pelo SFP desconectado. OSPF, VLAN 15,
      ACL roteada e demais VLANs seguem pendentes — ver [10](10-enderecamento-ccr1036.md)
- [ ] Pré-criar no NE8000, **desativado**: zonas de firewall ([05](05-limpeza-politicas.md)),
      subinterfaces pros links da CCR1036
- [ ] WireGuard na CCR somente depois de toda a migração concluída e validada
- [ ] Testar integrado: VLAN 16 ~~`.4`~~ 🆕 `.15`↔`.1`, NAT, OSPF ~~`.4`~~ `.15`↔`.1`, VLAN 100, VLAN 15/NTP, VLAN 66
  (TS SIX), VLAN 109 (OLT CPV) e VLAN 116 (Dude)
- [ ] Trocar o IP do Proxmox Zabbix (`177.72.104.5` → privado novo) — **pode ser feito
      independente do resto**, é standalone, sem indisponibilidade real (checklist na
      [decisão #12](03-decisoes-pendentes.md))
- [ ] Confirmar fisicamente o mapeamento porta-a-porta dos enlaces P2P (Solidão, Pantano, Juca Ana)
      contra as subinterfaces `MK_POP_*` do NE8000

## T-1 dia: checklist final

- [ ] Confirmar os bloqueadores restantes fechados (**#3, #7, #11** — os demais já estão ✅)
- [ ] Config do DM4170 e da CCR1036 revisadas e testadas em bancada uma última vez
- [ ] Script de rollback escrito passo a passo (não improvisar na hora)
- [ ] Definir o critério de abortar (ex.: "se FlowSpec ou NAT não validar em 15 min, rollback")
- [ ] Confirmar quem participa da janela e os canais de comunicação (NOC, equipe de campo se
      precisar trocar cabo fisicamente)
- [ ] Avisar os sistemas/parceiros com dependência conhecida (Hubsoft, Fusion, Belluno, SixTelecom
      — os que o Passo 1 confirmar como vivos)

## Noite do corte

### Fase 1 — Estágio (sem indisponibilidade)

- [ ] DM4170 instalado no rack, link 10GE novo até o NE8000 ativo (trunk 802.1q com as VLANs de
      acesso QinQ-terminadas + VLANs simples destinadas ao NE8000)
- [ ] 🆕 Validar as SVIs e adjacências OSPF **já criadas no NE8000** (T-14, item 3) contra o
      [09](09-l2-mapeamento-vlans.md) — o DM4170 não fala OSPF (decisão #13), só encaminha o
      trunk em L2; nada de "vizinho novo" a validar nele
- [ ] Validar: tabela de rotas do NE8000 pras VLANs recém-criadas; FlowSpec e NetStream intactos
- [ ] CCR1036 instalada com seu **único uplink**, o trunk até o DM4170 (VLAN 16 + privadas), ativo;
      não existe link direto CCR↔NE8000. Validar ~~`.4`~~ 🆕 `.15`↔`.1`, OSPF, NAT, VLAN 100 e VLAN 15/NTP antes
      de assumir tráfego real

> Até aqui, nada em produção mudou. Ponto seguro pra pausar se precisar.

### Fase 2 — Corte do trunk QinQ (janela real começa aqui)

- [ ] ⏱️ Registrar horário de início
- [ ] Desligar `sfp1` do RB3011
- [ ] Mover o cabo do trunk QinQ (rede de acesso) para o DM4170
- [ ] Validar site a site, gerências primeiro, POPs com cliente por último — tabela completa em
      [08-vlans-e-portas.md](08-vlans-e-portas.md)
- [ ] ping/gerência: cada OLT, cada switch, cada POP
- [ ] **MTU fim a fim**: ping com DF e payload grande (1500) pra um POP QinQ

🔴 **Critério de abortar aqui:** se um site crítico não responde e não é diagnosticável em poucos
minutos → religar `sfp1` no RB3011 (rollback é imediato, o MK está intacto).

### Fase 3 — Corte do núcleo (bloco público + NAT + OSPF principal)

- [ ] VLAN 16 / `177.72.104.0/27` — todas as sub-redes da antiga `Bridge IP Publico` migram para o
      NE8000 (decisão #9)
- [ ] `.1` para de existir no RB3011; anúncio OSPF do `/27` muda de origem pro NE8000
- [ ] ~~Segmento `177.72.104.52/30` com o NE8000 ativo (`.53` do lado novo)~~ — morre com o MK; o
      NE8000 termina o `/27` em SVI própria (VLAN 16 via DM4170)
- [ ] Ativar NAT na **CCR1036** (SRC-NAT geral + DST-NAT Dude `:18291`/TS SIX `:15389`) e
      **desativar no RB3011**
- [ ] Rotas estáticas locais reavaliadas (`10.8.0.0/21` via `.9`, `10.254.0.0/22` via `.12`,
      `10.30.0.0/30`+`10.150.150.0/24` via `.19`, DNS loopbacks via `.28`) — viram *connected*
- [ ] ~~Adjacência OSPF principal ativa (VLAN 28: `192.168.116.34` + secundário `177.72.104.53`)~~ —
      VLAN 28 morre com o MK; nova adjacência CCR↔NE8000 sobre a VLAN 16 (~~`.4`~~ 🆕 `.15`↔`.1`)
- [ ] Servidores locais do RB3011 (`ether6`–`ether10`) recabeados para portas GE do **DM4170**
      (🆕 confirmado 2026-07-24 — não mais a CCR1036; transceiver SFP-RJ45, ver
      [02](02-arquitetura-alvo.md) e [10](10-enderecamento-ccr1036.md))
- [ ] 🚨 **Validar FlowSpec e NetStream imediatamente**: sessão BGP com `177.72.104.27`
      estabelecida no NE8000; fluxo chegando na porta `3055`

🔴 **Critério de abortar aqui:** FlowSpec ou NAT não validando em X minutos (definir X na véspera)
→ rollback completo (abaixo).

### Validação final da janela

- [ ] Adjacências OSPF: mesmo número de vizinhos de antes (NE8000 + POPs)
- [ ] ~~DNS recursivo (`10.200.255.253`)~~ → ❌ fora do plano da CCR (usuário, 2026-08-06) — e DNS públicos (`.28`/`.58`/`.59`) respondendo
- [ ] DHCP do gerador MST entregando lease
- [ ] ~~VPN nova: os 4 usuários conectam~~ — VPN não migra no corte; WireGuard só pós-migração
      (decisão #5, [03](03-decisoes-pendentes.md)). O WireGuard antigo (RB750 `.19`) deve seguir
      respondendo normalmente
- [ ] Sistemas confirmados vivos no Passo 1 (Hubsoft, Fusion, VOIP etc.) acessíveis de fora
- [ ] ~~Backup automático roda no novo destino (próxima execução agendada, não precisa esperar a
      semana)~~ — automações de backup descartadas (decisão #6, [03](03-decisoes-pendentes.md))
- [ ] ⏱️ Registrar horário de término

## Rollback

| Fase | Como reverter | Tempo esperado |
|---|---|---|
| 1 (estágio) | Nenhum — nada em produção mudou | — |
| 2 (trunk) | Religar o cabo na `sfp1` do RB3011 | minutos |
| 3 (núcleo) | Religar `sfp1`, reativar SVIs/NAT no RB3011, desfazer as ativações no
NE8000/DM4170/CCR1036 (script escrito na véspera, não improvisar) | alvo: <15 min |

## Pós-janela (dias seguintes)

- [ ] RB3011 e RB2011 ficam **desligados mas configurados** por N semanas (rollback físico de
      longo prazo). RB750 permanece ativo (WireGuard) até migrar para a CCR
- [ ] Atualizar Dude/LibreNMS para monitorar os equipamentos novos
- [ ] **Rotação de credenciais** — só depois que o RB3011/RB2011 saírem de vez: chave OSPF MD5
      (estratégia da [decisão #11](03-decisoes-pendentes.md)), senha BGP do peer Google,
      credenciais FTP de backup, senhas PPP, community SNMP. 🆕 Token da API FocusChat: **revogar**
      (não rotacionar) — automação descartada, decisão #6
- [ ] Remover do NE8000 o que referenciava o MK antigo (ACLs, subinterface velha)
- [ ] Fechar o item "o que NÃO migra" — conferir que nada da lista foi portado por engano
      ([04](04-plano-migracao.md))
