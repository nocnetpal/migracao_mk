# Plano de migração (corte)

> **Status: rascunho v1** — escrito após o fechamento do inventário técnico do RB3011
> ([07](07-enderecamento-ip.md), [08](08-vlans-e-portas.md)). Ainda há bloqueios externos
> (lista abaixo), mas a estrutura do plano já está definida.

## Pré-requisitos — status

- [x] Configuração do RB3011 documentada (export + coletas manuais 1 e 2 — **completo**)
- [x] Configuração do RB2011 documentada
- [x] Modelo do Datacom confirmado (DM4170; falta só a variante 12×10GE vs 4×10GE+2×40GE)
- [x] Decisão NAT/DHCP (🆕 NAT → **CCR1036**, corrigido 2026-07-23; NE8000 fica só com `/27` +
      firewall; DHCP é um escopo único, trivial)
- [x] ~~**Identificar o switch de topo de rack**~~ → ✅ identificado (2026-07-23). Escopo
      fechado: **a rede de acesso não se mexe**; o DM4170 recebe o cabo do trunk QinQ no lugar
      do RB3011
- [ ] **Confirmações DmOS com a Datacom**: SVI roteada sobre tag interna QinQ; limite de IPs
      secundários por SVI; redistribute connected/static no OSPF
- [ ] Decisão #9: quem fica dono do `177.72.104.0/27` ([03](03-decisoes-pendentes.md))
- [ ] **MTU no novo desenho**: validar baby giants/QinQ no DM4170 e no trunk 10GE (hoje a `sfp1`
      roda l2mtu 1600 → outer 1596 → inner 1592) e manter o equivalente ao MSS-clamp do mangle
- [ ] Esclarecer a sobreposição do `177.72.104.60/30` (decisão #10 em
      [03](03-decisoes-pendentes.md)) antes do corte
- [ ] 🆕 **Mecanismo de NAT na CCR1036**: qual IP público usar (`.1` ou outro) e como roteá-lo até
      a CCR1036 via NE8000 (decisão #9 corrigida em [03](03-decisoes-pendentes.md))
- [ ] Passo 1 da limpeza: quais sistemas ainda estão vivos ([05](05-limpeza-politicas.md))
- [ ] Destino das VPNs (L2TP+OpenVPN) e das automações (backup FTP, netwatch→API)
- [ ] Solução de acesso do NOC (o EoIP morre com o Mikrotik — e já está down)

## Mapa função → destino

| Função hoje no RB3011 | Destino | Situação |
|---|---|---|
| Roteamento inter-VLAN (~50 VLANs QinQ) | DM4170 | Depende da confirmação QinQ no DmOS |
| OSPF area1 (adjacências + redistribute connected/static E1) | DM4170 | Reproduzir; oportunidade de anúncios explícitos |
| Dono do `177.72.104.0/27` (VLAN 16 sobe em L2) | **NE8000** — ✅ decidido 2026-07-23 (#9, Opção B) | Só IP público + firewall — **não faz mais o NAT** |
| SRC-NAT/DST-NAT | 🆕 **CCR1036** — corrigido 2026-07-23 | Substitui a resposta anterior (NE8000). Falta definir qual IP e a rota até a CCR1036 |
| Firewall de servidores | NE8000 (modelo de zonas do [05](05-limpeza-politicas.md)) | Aguarda passo 1 |
| DHCP (`VLAN1066 - GERADOR MST`) | Datacom ou NE8000 | Trivial, decidir na config |
| VPN equipe (L2TP **e** OpenVPN) | **CCR1036** (ligada direto ao NE8000) — ✅ definido 2026-07-23 | Redesenho, não porte |
| Backup semanal FTP + netwatch→API (script `dude`) | **CCR1036** (candidata — RouterOS roda os scripts de hoje) ou NMS existente | Em aberto |
| Bridge L2 dos servidores (RB2011 + `Bridge IP Publico`) | Gerência privada dos servidores locais → **CCR1036** (5 portas RJ45); VLAN 16 (pública) sobe em L2 pelo **DM4170** até o NE8000; servidores que precisarem de IP público usam **segunda NIC** na VLAN 16 | Direto |
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
1. Resolver os bloqueios da lista de pré-requisitos (especialmente #9 e as confirmações DmOS).
2. Montar a config completa do DM4170 em bancada: todas as VLANs/QinQ, SVIs, OSPF (interfaces
   passivas), ACL de gerência no padrão `IPV4_NOC_NETPAL` do NE8000.
3. Pré-criar no NE8000: zonas de firewall (conforme [05](05-limpeza-politicas.md)), tudo
   **desativado/sem aplicar** — **e a subinterface/VLAN dedicada** para a adjacência OSPF de
   estágio com o DM4170 (usada na fase 1). Pré-criar na **CCR1036**: regras de NAT (SRC-NAT geral +
   DST-NAT Dude/TS SIX), também desativadas até a janela.
4. Montar o novo serviço de VPN e migrar os 4 usuários (pode ser feito antes de tudo — a VPN nova
   convive com a velha). **Atenção aos certificados:** o OpenVPN atual exige certificado de
   cliente (`require-client-certificate=yes`) — exportar a CA/certs do MK ou reemitir para os 4
   usuários, senão os clientes não conectam no serviço novo.
5. Migrar as automações (backup/notificação) para o servidor escolhido.
6. **Não portar** nada da lista "o que não migra" (abaixo).

### Fase 1 — Estágio
1. DM4170 instalado no rack, ligado ao NE8000 pelo link 10GE novo. **Sem trunk para a rede de
   acesso** — ela não será mexida; o cabo QinQ só muda na janela (fase 2).
2. DM4170 entra na OSPF area1 como **mais um vizinho** (adjacência própria com o NE8000 pela
   VLAN dedicada de núcleo — não mexe na do MK; a ponta do NE8000 foi pré-criada na fase 0).
3. Validar: tabela de rotas do DM4170, FlowSpec/NetStream intactos, e config de todas as SVIs
   revisada contra o [09](09-l2-mapeamento-vlans.md).

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
- [ ] VLAN 16 / `177.72.104.0/27` (todas as sub-redes da antiga `Bridge IP Publico`) — para o dono
      definido na decisão #9
- [ ] `.1` para de existir no MK; anúncio OSPF do `/27` muda de origem
- [ ] Segmento `177.72.104.52/30` com o NE8000 (`.53`)
- [ ] Ativar NAT na **CCR1036** (SRC-NAT geral + DST-NAT Dude/TS SIX) e **desativar no MK**
- [ ] Rotas estáticas locais (`10.8.0.0/21` via `.9`, `10.254.0.0/22` via `.12`,
      `10.30.0.0/30`+`10.150.150.0/24` via `.19`, DNS loopbacks via `.28`)
- [ ] Adjacência OSPF principal (VLAN 28: `192.168.116.34` + secundário `177.72.104.53`)
- [ ] Servidores locais do MK (`ether6`–`10`) recabeados para portas do DM4170 (ou para o SW topo)
- [ ] **Validar FlowSpec e NetStream imediatamente** (sessão BGP `177.72.104.27`, fluxo na porta 3055)

### Fase 4 — Descomissionamento
1. RB3011 e RB2011 ficam **desligados mas configurados** por N semanas (rollback físico).
2. **Rotação de credenciais** (tudo vazou em texto claro nos exports): chave OSPF MD5 `ntprb1030`
   (rede toda, coordenar! — estratégia na decisão #11 de [03](03-decisoes-pendentes.md)), senha
   BGP do peer Google, credenciais FTP de backup (`mkbkp`/`hwbkp`),
   senhas PPP dos 4 usuários, token da API focuschat, community SNMP.
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
- [ ] DNS recursivo (`10.200.255.253`) e DNS públicos (`.28/.58/.59`) respondendo
- [ ] Hubsoft/Fusion/VOIP acessíveis de fora (os que o passo 1 confirmar como vivos)
- [ ] DHCP do gerador MST entregando lease
- [ ] VPN nova: os 4 usuários conectam
- [ ] Backup automático rodou no novo lugar

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
