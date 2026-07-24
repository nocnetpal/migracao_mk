# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repositório

Não é código — é a **documentação viva de um projeto de migração de rede** da ISP NetPal
(Capivari do Sul/RS): substituir os Mikrotik RB3011 "GW Servidores" + RB2011 por um switch
**Datacom DM4170** (L2 puro — QinQ termination) e o **Huawei NE8000** (já existente, assume
firewall L3, inter-VLAN routing/SVIs e o bloco público `/27`) + uma **CCR1036** nova (NAT, VPN,
ligada ao NE8000 via trunk com o DM4170).

## Idioma

- **Sempre responder em português.**
- Commit messages em português.
- Código, variáveis e funções em inglês; comentários e documentação em português.

Comece sempre por `docs/00-visao-geral.md` — o status atual, os bloqueios e o índice estão lá.
O desenho de papéis acima já mudou de forma (decisão #13: DM4170 perdeu o roteamento inter-VLAN
que tinha originalmente; NAT foi corrigido de NE8000 pra CCR1036) — não assumir a arquitetura de
memória, sempre conferir o `00` e o `03-decisoes-pendentes.md` antes de afirmar quem faz o quê.

## Estrutura

- `docs/00`–`13` — documentos numerados, encadeados por links relativos. `03-decisoes-pendentes.md`
  é o registro central de decisões (numeradas, com **Status** cada — a fonte de verdade sobre o
  que já foi fechado); `04-plano-migracao.md` é o plano de corte; `07`/`08` são o inventário
  técnico completo do RB3011 (endereçamento e topologia L2/QinQ); `09` é o mapeamento VLAN a VLAN
  para o desenho alvo; `12` é o mapeamento dos 4 clusters Proxmox (IPs de hypervisors e VMs); `13`
  é o runbook operacional da janela de corte.
- `config/<equipamento>/` — exports e dumps de CLI brutos (RouterOS `.rsc`, Huawei `.txt`, CSVs
  gerados pelos scripts de coleta). São a **fonte primária**; os docs derivam deles. 🆕 **O export
  completo do RB3011 chegou em 2026-07-24** (`gw-servidores-export-completo-2026-07-24.rsc`) — não
  está mais truncado. O antigo `gw-servidores-export.rsc` era o truncado (falta o início); as
  coletas manuais `gw-servidores-*.txt` preenchiam as lacunas e agora são redundantes (mas os docs
  ainda referenciam o truncado por número de linha em vários pontos — cuidado ao cruzar).
- `scripts/` — scripts read-only de coleta, pra rodar diretamente nos hosts (não no chat):
  `proxmox-mapear-vms.sh` roda em cada hypervisor Proxmox (usa `qm`/`pct`) e mapeia VM→IP/VLAN/MAC
  por captura passiva de tráfego (tap) quando o host não fala L3 com a VM; `docker-mapear-containers.sh`
  roda dentro de uma VM com Docker e lista container→rede→IP. Saída em CSV, redirecionada e salva
  em `config/<equipamento>/`.

## Fluxo de trabalho estabelecido

O usuário cola saídas de CLI (RouterOS/Huawei/Linux) diretamente no chat. Ao receber um dump:

1. **Salvar o dump bruto** em `config/<equipamento>/` (arquivo novo ou append no arquivo de coleta
   existente), antes de analisar.
2. **Cruzar com os exports existentes** — os achados mais importantes até agora vieram de cruzar
   config do MK com a do NE8000 (ex.: dependências de FlowSpec/next-hop na decisão #8) ou releituras
   de um export já salvo contra uma hipótese registrada (ex.: decisão #6 — o script de notificação
   citava a API de terceiros `focuschat.com.br`, não uma VM interna como se supunha).
3. **Propagar as conclusões em todos os docs afetados**, corrigindo explicitamente análises
   anteriores que ficaram erradas (usar ~~riscado~~ + "✅ resolvido/reclassificado", não apagar
   silenciosamente). O `03-decisoes-pendentes.md` é o registro central — se uma decisão fecha,
   ela **tem** que ser sincronizada lá, mesmo que a conclusão já esteja em outro doc.
4. Responder com os achados **em ordem de importância** e sugerir os próximos comandos de coleta.

Análise profunda é esperada: ausência de uma seção num export ordenado é informação (as seções do
`/export` do RouterOS têm ordem fixa — dá para distinguir "truncado" de "não configurado").

## Regras

- **Credenciais**: os exports contêm senhas/chaves/tokens em texto claro. Tratar como sensível —
  **não copiar valores de credenciais para os docs** (regra registrada em `docs/01`). Tudo será
  rotacionado (ou revogado, se a automação associada foi descartada) no descomissionamento
  (fase 4 do plano).
- **Não portar config 1:1**: o princípio do projeto é redesenho limpo (`docs/05`). Há uma lista
  explícita de "o que NÃO migra" no `docs/04`.
- Ao fechar uma decisão ou invalidar uma premissa, atualizar também o **Status** em
  `docs/00-visao-geral.md` e `docs/03-decisoes-pendentes.md`.

## Contexto técnico mínimo (o que exige ler vários arquivos para entender)

- O RB3011 é um **router-on-a-stick**: ~50 VLANs (estrutura QinQ: tag externa = site, interna =
  serviço) entram por uma única SFP 1GE vinda de um switch de topo de rack **ainda não
  inventariado**, fora de escopo (a rede de acesso não é tocada). Detalhes em `docs/08`.
  🆕 **Export completo do RB3011 obtido 2026-07-24** (`config/rb3011/gw-servidores-export-completo-2026-07-24.rsc`) —
  o antigo `gw-servidores-export.rsc` era truncado. A relação VLAN↔IP consolidada está em
  `config/rb3011/relacao-vlan-ip.md`.
- 🆕 **São TRÊS Mikrotiks no trecho, não dois** (topologia física do usuário,
  `config/topologia-fisica-rack.md`): RB3011 (router), RB2011 e **RB750** (duas bridges L2
  intermediárias — os servidores penduram nelas, não direto no RB3011: RB2011 no `ether6` = TS SIX/
  Dude/RRFlow/CGNAT-1 mgmt; RB750 no `ether10` = gerência NE8000/Zabbix/HubSoft). **Decisão #2
  (2026-07-24): os 3 saem, o DM4170 absorve tudo** — cada servidor pluga direto numa porta GE do
  DM4170 (~8 precisam de transceiver SFP-RJ45).
- O NE8000 **não é só o futuro firewall** — é o core BGP/OSPF em produção da ISP inteira
  (`docs/06`) e hoje **depende do RB3011** (next-hops, alcance ao route-reflector de FlowSpec) —
  decisão #8. A proposta de resolver isso é a decisão #9 (NE8000 assume o `/27` público). Com a
  decisão #13, o NE8000 também herda o roteamento inter-VLAN (SVIs sobre as ~50 VLANs QinQ) que
  seria do DM4170 — concentra ainda mais função crítica (por isso a decisão #3, sem redundância,
  aceita esse risco conscientemente).
- Equipamentos: **RB3011 + RB2011 + RB750 saem**; **DM4170** chega zerado, fica só em L2 (datasheet
  em `docs/datacom-dm4170-datasheet.pdf` — **não tem NAT**, por isso NAT foi pra CCR1036, não pro
  NE8000); **CCR1036** (variante 8G-2S+) é equipamento novo, dedicado a NAT (IP `177.72.104.4`) +
  VPN, alcança os servidores locais via trunk com o DM4170 (não tem porta física dedicada a eles).
