# Plano de migração (corte)

> **Status: rascunho v1** — escrito após o fechamento do inventário técnico do RB3011
> ([07](07-enderecamento-ip.md), [08](08-vlans-e-portas.md)). Ainda há bloqueios externos
> (lista abaixo), mas a estrutura do plano já está definida.
>
> ## 🆕 Ordem atual (2026-07-27): Etapa 1 Proxmox/Datacom **antes** da virada `/27`
>
> 1. **Etapa 1** — VLANs nos Proxmox + portas trunk no DM4170 ([16](16-etapa1-proxmox-vlans-datacom.md))
> 2. **Etapa A** — instalar DM4170 + CCR ligados ao NE8000 (pode sobrepor a 1)
> 3. **Etapa B** — virada `/27`/NAT + demais servidores
> 4. **Janela futura** — QinQ `sfp1`
>
> Detalhe Etapa 1: **[16-etapa1-proxmox-vlans-datacom.md](16-etapa1-proxmox-vlans-datacom.md)**.
> Etapa A/B geral: abaixo e [15](15-plano-migracao-servidores-177.md) se o link antigo apontar.

## Pré-requisitos — status

- [x] Configuração do RB3011 documentada (export + coletas manuais 1 e 2 — **completo**)
- [x] Configuração do RB2011 documentada
- [x] Modelo do Datacom confirmado: **DM4170 24GX+12XS** (24× GE SFP + 12× 10GE SFP+, todo óptico
      — usuário, 2026-07-24)
- [x] Decisão NAT/DHCP (🆕 NAT → **CCR1036**, corrigido 2026-07-23; NE8000 fica só com `/27` +
      firewall; DHCP é um escopo único, trivial)
- [x] ~~**Identificar o switch de topo de rack**~~ → ✅ identificado (2026-07-23). Escopo
      fechado: **a rede de acesso não se mexe**; o DM4170 recebe o cabo do trunk QinQ no lugar
      do RB3011
- [x] ~~**Confirmações DmOS com a Datacom**: SVI roteada sobre tag interna QinQ; limite de IPs
      secundários por SVI~~ → ✅ **caiu (decisão #13, 2026-07-24):** DM4170 fica só em L2 (QinQ
      termination), não precisa mais dessa confirmação. **Continua pendente:** redistribute
      connected/static no OSPF — agora responsabilidade do **NE8000**, não do DM4170.
- [x] Decisão #9: quem fica dono do `177.72.104.0/27` → **NE8000** ([03](03-decisoes-pendentes.md))
- [x] ~~**MTU no novo desenho**: validar baby giants/QinQ nos dois trechos~~ → ✅ **estratégia
      decidida (usuário, 2026-07-24):** jumbo frame máximo suportado por cada equipamento, nos
      trechos rede de acesso↔DM4170 **e** DM4170↔NE8000, em vez de replicar o l2mtu 1600 exato do
      RB3011. Número concreto de cada equipamento e o MSS-clamp equivalente ficam pra hora de
      configurar.
- [x] ~~Esclarecer a sobreposição do `177.72.104.60/30`~~ → ✅ **investigado (2026-07-24, decisão
      #10):** não é conflito real — NE8000 não tem interface nesse /30, statement OSPF inerte.
- [x] 🆕 **Mecanismo de NAT na CCR1036**: `.4/27` chega pela VLAN 16 no trunk DM4170↔CCR; a CCR
      é o gateway das redes privadas (VLAN 100 `.1/24` e demais), portanto o tráfego atravessa o
      SRC-NAT sem PBR no NE8000. Definido em 2026-08-06; falta teste integrado
- [x] ~~🆕 **Dimensionamento do NE8000** (decisão #13): confirmar capacidade para +30
      subinterfaces/adjacências OSPF novas~~ → ✅ **confirmado (usuário, 2026-07-24): capacidade
      livre**, sem restrição de licença/hardware.
- [ ] Passo 1 da limpeza: quais sistemas ainda estão vivos ([05](05-limpeza-politicas.md)) — 🟡
      conscientemente adiado (2026-07-24), voltar depois de fechar o resto
- [x] Destino/ordem da VPN: **WireGuard na CCR somente pós-migração** (usuário, 2026-08-06).
      L2TP/OpenVPN não serão recriados na bancada nem na janela inicial. As automações também não
      migram (decisão #6)
- [ ] Solução de acesso do NOC (o EoIP morre com o Mikrotik — e já está down)

## Mapa função → destino

| Função hoje no RB3011 | Destino | Situação |
|---|---|---|
| Roteamento inter-VLAN (~50 VLANs QinQ + simples de serviço) | **NE8000**, exceto redes privadas locais na CCR | VLAN 15/NTP reclassificada para a CCR em 2026-08-06; DM4170 fica só L2 |
| OSPF area1 (adjacências + redistribute connected/static E1) | **NE8000** (decisão #13 — antes seria o DM4170) | Reproduzir; oportunidade de anúncios explícitos |
| Dono do `177.72.104.0/27` (VLAN 16 sobe em L2) | **NE8000** — ✅ decidido 2026-07-23 (#9, Opção B) | Só IP público + firewall — **não faz mais o NAT** |
| SRC-NAT/DST-NAT | **CCR1036** | `.4/27` na VLAN 16 via DM4170; CCR é gateway das redes privadas, sem PBR no NE8000 |
| Firewall de servidores | NE8000 (modelo de zonas do [05](05-limpeza-politicas.md)) | Aguarda passo 1 |
| DHCP (`VLAN1066 - GERADOR MST`) | Datacom ou NE8000 | Trivial, decidir na config |
| VPN equipe | **CCR1036, somente pós-migração** | WireGuard depois de toda a migração concluída; não entra na bancada/janela inicial |
| ~~Backup semanal FTP + netwatch→API~~ | — | ✅ descartados; não migram (decisão #6) |
| Bridge L2 dos servidores (RB2011 + `Bridge IP Publico`) | Servidores plugam no **DM4170**; VLAN 16 sobe em L2 até o NE8000 **e a CCR**, e redes privadas seguem nos trunks necessários | Direto |
| EoIP NOC (`.1` ↔ `177.93.244.165`) | Substituir por rota/VPN padrão (já está fora do ar) | Em aberto |

## Estratégia: ~~fatiada por VLAN~~ → janela única com troca de cabo (revisado 2026-07-23)

> ~~A topologia descoberta em [08](08-vlans-e-portas.md) permite evitar o big-bang: como o fan-out
> físico é do **switch de topo de rack** (o RB3011 é router-on-a-stick), o DM4170 pode entrar como
> **segundo trunk** no mesmo switch e as VLANs migram **uma a uma**.~~
> **Revisado:** a rede de acesso está **fora do escopo** (não será mexida) — sem segundo trunk,
> não há como fatiar. O corte vira **janela única**: config 100% pré-montada no DM4170 (fases 0–1, sem tocar
> em produção), troca do cabo QinQ na janela (fase 2) + núcleo (fase 3), rollback = religar o
> cabo no RB3011. O preparo sem janela (fases 0–1) continua igual e é onde está todo o risco
> mitigável.

### Fase 0 — Preparação (sem tocar em produção)
1. Resolver os bloqueios restantes da lista de pré-requisitos: testar o mecanismo de rota do NAT
   na CCR1036 e montar/validar no novo L2 as portas/VLANs Proxmox de HubSoft e Zabbix — decisão
   #12. O DNS já foi migrado para a VLAN 100.
2. 🆕 Montar a config completa do **DM4170** em bancada: **só L2** (decisão #13) — QinQ
   termination de todas as VLANs de acesso, trunk 802.1q pro NE8000, ACL de gerência no padrão
   `IPV4_NOC_NETPAL`. **Nenhuma SVI, nenhum OSPF no DM4170.**
3. 🆕 Montar no **NE8000** todas as SVIs + adjacências OSPF area1 que **antes seriam do DM4170**
   (as 27 QinQ + 2 simples de serviço do [09](09-l2-mapeamento-vlans.md)) — mesmo padrão que já
   usa hoje pras VLANs de POP (`MK_POP_*`), tudo sobre o trunk novo vindo do DM4170. Pré-criar
   também: zonas de firewall (conforme [05](05-limpeza-politicas.md)), tudo
   **desativado/sem aplicar**. Pré-criar na **CCR1036**: regras de NAT (SRC-NAT geral +
   DST-NAT Dude/TS SIX). 🆕 A base atual da CCR (VLAN 16, `.4`, VLAN 100, default e SRC-NAT) foi
   deixada **habilitada em bancada por decisão do usuário em 2026-08-06**; permanece isolada pelo
   SFP desconectado. DST-NAT ainda não foi criado. Não conectar o trunk antes da coordenação com o
   RB3011, que ainda usa `.1` na VLAN 100.
4. ~~Montar a nova VPN antes do corte.~~ → ❌ **adiado pelo usuário em 2026-08-06:** WireGuard
   somente depois de toda a migração concluída e validada. Não configurar VPN na bancada nem na
   janela inicial.
5. ~~Migrar as automações (backup/notificação) para o servidor escolhido.~~ ✅ **removido
   (2026-07-24):** as duas automações (backup FTP semanal, notificação netwatch→FocusChat) foram
   descartadas (decisão #6) — nada a migrar aqui.
6. **Não portar** nada da lista "o que não migra" (abaixo).

### Fase 1 — Estágio
1. DM4170 instalado no rack, ligado ao NE8000 pelo link 10GE novo (trunk 802.1q com todas as
   VLANs de acesso QinQ-terminadas + as simples destinadas ao NE8000). **Sem trunk para a rede de
   acesso** — ela não será mexida; o cabo QinQ só muda na janela (fase 2).
2. 🆕 **Validar as SVIs e adjacências OSPF já criadas no NE8000** (fase 0, item 3) contra o
   [09](09-l2-mapeamento-vlans.md) — como o DM4170 não fala OSPF (decisão #13), não há
   "vizinho novo" a validar nele, só o encaminhamento L2 do trunk.
3. Validar: tabela de rotas do NE8000 pras VLANs recém-criadas, FlowSpec/NetStream intactos.

### Fase 2 — ~~Migração fatiada por VLAN~~ → janela única de corte do trunk

> ⚠️ **Revisado (2026-07-23):** sem mexer na rede de acesso não existe trunk paralelo — a estratégia
> fatiada deixa de ser possível. O corte do trunk QinQ acontece em **janela única**:
> desligar a `sfp1` do MK → mover o cabo para o DM4170 → validar site a site (mesma ordem que
> se usaria na fatiada: gerências de OLT/SW primeiro, POPs com clientes por último). Como a
> config do DM4170 chega 100% pré-montada e testada da fase 1, o risco da janela é baixo; o
> rollback é religar o cabo no RB3011 (minutos). Pode ser combinada com a fase 3 na mesma
> janela, ou feita em janela anterior separada — decidir no agendamento.

### Fase 3 — Janela do núcleo (a única com indisponibilidade real)
Migrar em bloco, na mesma janela:
- [ ] ~~VLAN 16 / `177.72.104.0/27` (todas as sub-redes da antiga `Bridge IP Publico`)~~ — o NE8000
      passa a anunciar o `/27` por SVI própria (decisão #9); ~~a bridge morre~~
- [ ] `.1` para de existir no MK; anúncio OSPF do `/27` muda de origem
- [ ] ~~Segmento `177.72.104.52/30` com o NE8000 (`.53`)~~ — morre com o MK; NE8000 passa a terminar
      o `/27` em SVI própria (VLAN 16 via DM4170), não precisa do `.52/30`
- [ ] Ativar NAT na **CCR1036** (SRC-NAT geral + DST-NAT Dude/TS SIX) e **desativar no MK**
- [ ] Rotas estáticas locais (`10.8.0.0/21` via `.9`, `10.254.0.0/22` via `.12`,
      `10.30.0.0/30`+`10.150.150.0/24` via `.19`, DNS loopbacks via `.28`) — rever quais viram
      *connected* no NE8000 e quais migram para a CCR
- [ ] ~~Adjacência OSPF principal (VLAN 28: `192.168.116.34` + secundário `177.72.104.53`)~~ — a
      VLAN 28 morre com o MK; a nova adjacência OSPF CCR↔NE8000 será sobre a VLAN 16 (`.4`↔`.1`)
- [ ] Servidores locais do MK (`ether6`–`10`) recabeados para portas GE do **DM4170** (🆕
      confirmado 2026-07-24 — não mais a CCR1036; usar transceiver SFP-RJ45 nas portas ópticas)
- [ ] **Validar FlowSpec e NetStream imediatamente** (sessão BGP `177.72.104.27`, fluxo na porta 3055)

### Fase 4 — Descomissionamento
1. RB3011 e RB2011 ficam **desligados mas configurados** por N semanas (rollback físico). RB750
   permanece ativo (WireGuard).
2. **Rotação de credenciais** (tudo vazou em texto claro nos exports): chave OSPF MD5 `ntprb1030`
   (rede toda, coordenar! — estratégia na decisão #11 de [03](03-decisoes-pendentes.md)), senha
   BGP do peer Google, senhas PPP dos 4 usuários, community SNMP. 🆕 Credenciais FTP de backup
   (`mkbkp`/`hwbkp`) e token da API FocusChat **não precisam rotacionar** — as duas automações que
   os usavam foram **descartadas** (decisão #6, [03](03-decisoes-pendentes.md)); só
   **revogar/desativar** as duas, não recriar em lugar nenhum.
3. Remover do NE8000 o que referenciava o MK (subinterface `.28` antiga se substituída, ACLs).
4. Atualizar documentação/monitoramento (Dude, LibreNMS) para os novos equipamentos.

## Validação pós-corte (checklist mínimo)

- [ ] Adjacências OSPF: mesmo número de vizinhos de antes (NE8000 + POPs)
- [ ] FlowSpec: sessão BGP com `177.72.104.27` estabelecida no NE8000
- [ ] NetStream chegando em `177.72.104.27:3055`
- [ ] NAT: saída mascarada funcionando de uma rede da antiga lista `NAT`; DST-NAT do Dude e TS SIX
- [ ] Um ping/gerência por site: cada OLT, cada SW, cada POP (usar a tabela do [08](08-vlans-e-portas.md))
- [ ] **MTU fim a fim**: ping com DF e payload grande (ex.: 1500) para um POP QinQ e para um
      servidor da VLAN 16 — valida baby giants no trunk novo e o MSS-clamp equivalente
- [ ] ~~DNS recursivo (`10.200.255.253`)~~ → ❌ fora do plano da CCR (usuário, 2026-08-06) — e DNS públicos (`.28/.58/.59`) respondendo
- [ ] Hubsoft/Fusion/VOIP acessíveis de fora (os que o passo 1 confirmar como vivos)
- [ ] DHCP do gerador MST entregando lease
- [ ] ~~VPN nova: os 4 usuários conectam~~ — VPN não migra no corte; WireGuard só pós-migração
      (decisão #5, [03](03-decisoes-pendentes.md))
- [ ] ~~Backup automático rodou no novo lugar~~ — automações de backup descartadas (decisão #6,
      [03](03-decisoes-pendentes.md)); validar apenas que o RB750 (WireGuard) segue íntegro

## Rollback

- Fase 1: sem impacto — nada em produção mudou.
- Fase 2: religar o cabo do trunk na `sfp1` do RB3011 — minutos, sem reconfig (o MK fica intacto,
  só com a `sfp1` desligada durante a janela).
- Fase 3: religar `sfp1`, reativar SVIs/NAT no MK, derrubar as ativações no NE8000/Datacom/CCR1036 —
  manter um "script de rollback" escrito passo-a-passo **antes** da janela.
- Critério de abortar: FlowSpec ou NAT não validando em X minutos → rollback (definir X na janela).

## O que NÃO migra (limpeza já decidida ou identificada)

- Address-list `BRASIL` (decisão do [05](05-limpeza-politicas.md))
- `182.168.83.0/24` / `182.168.84.0/24` em `FORA_DO_NAT` (typo de `192.168.x` — confirmar e corrigir)
- VLANs sem função L3: `VLAN13`, `VLAN17`, `VLAN21-GERENCIA-GGV`, `VLAN51`, `VLAN53`, `VLAN92`,
  `VLAN250`, `VLAN742` ou `VLAN770`, `VLAN772` ([08](08-vlans-e-portas.md))
- Pools DHCP órfãos (8 de 10), bridges `EOIP-NOC` e `loopNETPAL`, IP da `ether1` ("REGUA VOLT")
- Regras de firewall de sistemas mortos (aguarda passo 1 do [05](05-limpeza-politicas.md))
- Perfis PPP sem criptografia e `mschap1` (a VPN nova nasce limpa)
- `1.1.1.0/24` como numeração interna — aproveitar para eliminar das allowlists
