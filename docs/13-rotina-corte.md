# Rotina de corte — runbook da janela de madrugada

> Este é o **runbook operacional** (passo a passo, com checkbox, pra seguir ao vivo na noite do
> corte). A justificativa e o desenho de cada decisão estão em
> [04-plano-migracao.md](04-plano-migracao.md) (estratégia) e
> [03-decisoes-pendentes.md](03-decisoes-pendentes.md) (decisões). Este documento **consome** os
> dois — não repete o raciocínio, só a sequência de execução.
>
> 🚨 **Ainda não está pronto pra agendar.** Tem bloqueador real em aberto (lista abaixo). Os
> passos que dependem de um bloqueador estão marcados `⛔ BLOQUEADO`, com placeholder pro dado que
> falta. Conforme cada decisão fechar, volto aqui e preencho.

## 🚦 Bloqueadores — precisam fechar antes de marcar a data

| # | Bloqueador | Doc | Status |
|---|---|---|---|
| 1 | ~~SVI roteada sobre tag interna de QinQ no DmOS~~ | [03 #13](03-decisoes-pendentes.md) | ✅ **caiu (2026-07-24)** — decisão #13: DM4170 fica só L2, quem termina a SVI é o NE8000 |
| 2 | ~~MTU/baby giants nos dois trechos novos~~ | [03 #4](03-decisoes-pendentes.md) | ✅ **estratégia fechada (2026-07-24)** — jumbo frame máximo de cada equipamento; número concreto na hora de configurar |
| 3 | Mecanismo de NAT na CCR1036 — como rotear o IP público até ela | [03 #9](03-decisoes-pendentes.md) | 🟡 IP definido (`177.72.104.4`, 2026-07-24) — falta só desenhar a rota |
| 4 | ~~Sobreposição `177.72.104.60/30`~~ | [03 #10](03-decisoes-pendentes.md) | ✅ **investigado e resolvido (2026-07-24)** — não é conflito real, NE8000 não tem interface nesse /30 |
| 5 | ~~Estratégia da chave OSPF MD5 `ntprb1030` no corte~~ | [03 #11](03-decisoes-pendentes.md) | ✅ **fechado (2026-07-24)** — Opção A: mantém `ntprb1030` no corte, rotaciona na fase 4 |
| 6 | ~~Variante da CCR1036~~ | [02](02-arquitetura-alvo.md) | ✅ **decidido (2026-07-24): 8G-2S+** |
| 7 | Passo 1 da limpeza — quais sistemas do firewall antigo ainda estão vivos | [05](05-limpeza-politicas.md) | 🟡 conscientemente adiado (2026-07-24) — voltar depois de fechar o resto |
| 8 | Portas/VLANs da CCR1036 para os clusters Proxmox HubSoft e DNS | [03 #12](03-decisoes-pendentes.md) | ⛔ em aberto |
| 9 | ~~Destino final das automações (backup FTP, netwatch→API)~~ | [03 #6](03-decisoes-pendentes.md) | ✅ **fechado (2026-07-24)** — as duas descartadas, não migram, nada a implementar aqui |
| 10 | VPN nova (L2TP+OpenVPN) implementada e testada na CCR1036 | [03 #5](03-decisoes-pendentes.md) | 🟡 destino definido, falta implementar/testar |
| 11 | Solução de acesso do NOC (EoIP morre com o MK) | [03 #8](03-decisoes-pendentes.md) | 🟡 NE8000 já libera `177.93.244.165` direto na ACL de gerência — provavelmente já resolvido, falta confirmar |
| 12 | ~~Dimensionamento do NE8000 para +30 subinterfaces/adjacências OSPF novas~~ | [03 #13](03-decisoes-pendentes.md) | ✅ **confirmado (2026-07-24): capacidade livre** |

**Dos bloqueadores originais, resta de verdade só o mecanismo de rota do item 3 (NAT/CCR1036) e o
item 8 (portas/VLANs Proxmox HubSoft/DNS)** — mudam a config que vai ser montada. Os itens 7, 10,
11 podem correr em paralelo até a véspera; o 7 foi conscientemente deixado pro final.

## T-14 dias: preparação (sem tocar em produção)

- [ ] Fechar os bloqueadores restantes acima (2, 3, 5, 6, 12)
- [ ] 🆕 Montar a config do **DM4170** em bancada — **só L2** (decisão #13): QinQ termination de
      todas as VLANs de acesso, trunk 802.1q pro NE8000, ACL de gerência no padrão
      `IPV4_NOC_NETPAL`. **Nenhuma SVI, nenhum OSPF nele.** 🆕 Incluir também: portas dos
      servidores locais (com transceiver SFP-RJ45 — a confirmar) + trunk novo pra CCR1036 com as
      VLANs de gerência privada (correção 2026-07-24, ver [02](02-arquitetura-alvo.md))
- [ ] 🆕 Montar no **NE8000** as SVIs + adjacências OSPF area1 das ~50 VLANs de acesso (27 QinQ +
      3 simples de serviço) que antes seriam do DM4170 — mesmo padrão que já usa hoje pras VLANs
      de POP (`MK_POP_*`) — ver [09-l2-mapeamento-vlans.md](09-l2-mapeamento-vlans.md)
- [ ] Montar a config da CCR1036 em bancada (VLANs de gerência, NAT desativado, VPN, firewall) —
      ver [10-enderecamento-ccr1036.md](10-enderecamento-ccr1036.md)
- [ ] Pré-criar no NE8000, **desativado**: zonas de firewall ([05](05-limpeza-politicas.md)),
      subinterfaces pros links da CCR1036
- [ ] Implementar e testar a VPN nova na CCR1036 com os 4 usuários (pode ser feito bem antes,
      convive com a antiga) — exportar/reemitir certificados do OpenVPN atual
      (`require-client-certificate=yes`)
- [ ] Definir e testar a rota do IP de NAT até a CCR1036 (bloqueador #3)
- [ ] Trocar o IP do Proxmox Zabbix (`177.72.104.5` → privado novo) — **pode ser feito
      independente do resto**, é standalone, sem indisponibilidade real (checklist na
      [decisão #12](03-decisoes-pendentes.md))
- [ ] Confirmar fisicamente o mapeamento porta-a-porta dos enlaces P2P (Solidão, Pantano, Juca Ana)
      contra as subinterfaces `MK_POP_*` do NE8000

## T-1 dia: checklist final

- [ ] Confirmar todos os bloqueadores restantes fechados (2, 3, 5, 6, 7, 8, 12)
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
      acesso QinQ-terminadas + as 3 simples de serviço)
- [ ] 🆕 Validar as SVIs e adjacências OSPF **já criadas no NE8000** (T-14, item 3) contra o
      [09](09-l2-mapeamento-vlans.md) — o DM4170 não fala OSPF (decisão #13), só encaminha o
      trunk em L2; nada de "vizinho novo" a validar nele
- [ ] Validar: tabela de rotas do NE8000 pras VLANs recém-criadas; FlowSpec e NetStream intactos
- [ ] CCR1036 instalada, link até o NE8000 ativo (pro IP público do NAT) **e** 🆕 trunk novo até o
      **DM4170** ativo (VLANs de gerência dos servidores locais — correção 2026-07-24); NAT/VPN/
      firewall dela testados mas **sem assumir tráfego real ainda**

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
- [ ] Segmento `177.72.104.52/30` com o NE8000 ativo (`.53` do lado novo)
- [ ] Ativar NAT na **CCR1036** (SRC-NAT geral + DST-NAT Dude `:18291`/TS SIX `:15389`) e
      **desativar no RB3011**
- [ ] Rotas estáticas locais reavaliadas (`10.8.0.0/21` via `.9`, `10.254.0.0/22` via `.12`,
      `10.30.0.0/30`+`10.150.150.0/24` via `.19`, DNS loopbacks via `.28`) — viram *connected*
- [ ] Adjacência OSPF principal ativa (VLAN 28: `192.168.116.34` + secundário `177.72.104.53`)
- [ ] Servidores locais do RB3011 (`ether6`–`ether10`) recabeados para portas GE do **DM4170**
      (🆕 confirmado 2026-07-24 — não mais a CCR1036; transceiver SFP-RJ45, ver
      [02](02-arquitetura-alvo.md) e [10](10-enderecamento-ccr1036.md))
- [ ] 🚨 **Validar FlowSpec e NetStream imediatamente**: sessão BGP com `177.72.104.27`
      estabelecida no NE8000; fluxo chegando na porta `3055`

🔴 **Critério de abortar aqui:** FlowSpec ou NAT não validando em X minutos (definir X na véspera)
→ rollback completo (abaixo).

### Validação final da janela

- [ ] Adjacências OSPF: mesmo número de vizinhos de antes (NE8000 + POPs)
- [ ] DNS recursivo (`10.200.255.253`) e DNS públicos (`.28`/`.58`/`.59`) respondendo
- [ ] DHCP do gerador MST entregando lease
- [ ] VPN nova: os 4 usuários conectam
- [ ] Sistemas confirmados vivos no Passo 1 (Hubsoft, Fusion, VOIP etc.) acessíveis de fora
- [ ] Backup automático roda no novo destino (próxima execução agendada, não precisa esperar a
      semana)
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
      longo prazo)
- [ ] Atualizar Dude/LibreNMS para monitorar os equipamentos novos
- [ ] **Rotação de credenciais** — só depois que o RB3011/RB2011 saírem de vez: chave OSPF MD5
      (estratégia da [decisão #11](03-decisoes-pendentes.md)), senha BGP do peer Google,
      credenciais FTP de backup, senhas PPP, community SNMP. 🆕 Token da API FocusChat: **revogar**
      (não rotacionar) — automação descartada, decisão #6
- [ ] Remover do NE8000 o que referenciava o MK antigo (ACLs, subinterface velha)
- [ ] Fechar o item "o que NÃO migra" — conferir que nada da lista foi portado por engano
      ([04](04-plano-migracao.md))
