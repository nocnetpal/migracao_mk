# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repositório

Não é código — é a **documentação viva de um projeto de migração de rede** da ISP NetPal
(Capivari do Sul/RS): substituir o Mikrotik RB3011 "GW Servidores" por um switch L3 Datacom DM4170
(inter-VLAN routing) + Huawei NE8000 (firewall/NAT). Todo o trabalho é em **português (pt-BR)**.

Comece sempre por `docs/00-visao-geral.md` — o status atual, os bloqueios e o índice estão lá.

## Estrutura

- `docs/00`–`09` — documentos numerados, encadeados por links relativos. `03-decisoes-pendentes.md`
  é o registro central de decisões (numeradas, com **Status** cada); `04-plano-migracao.md` é o
  plano de corte; `07`/`08` são o inventário técnico completo do RB3011 (endereçamento e topologia
  L2/QinQ); `09` é o mapeamento VLAN a VLAN para o desenho alvo (etapa L2).
- `config/<equipamento>/` — exports e dumps de CLI brutos (RouterOS `.rsc`, Huawei `.txt`). São a
  **fonte primária**; os docs derivam deles. O export do RB3011 está **truncado** (falta o início
  do arquivo); as lacunas foram preenchidas pelos arquivos `gw-servidores-*.txt` de coleta manual.

## Fluxo de trabalho estabelecido

O usuário cola saídas de CLI (RouterOS/Huawei) diretamente no chat. Ao receber um dump:

1. **Salvar o dump bruto** em `config/<equipamento>/` (arquivo novo ou append no arquivo de coleta
   existente), antes de analisar.
2. **Cruzar com os exports existentes** — os achados mais importantes até agora vieram de cruzar
   config do MK com a do NE8000 (ex.: dependências de FlowSpec/next-hop na decisão #8).
3. **Propagar as conclusões em todos os docs afetados**, corrigindo explicitamente análises
   anteriores que ficaram erradas (usar ~~riscado~~ + "✅ resolvido/reclassificado", não apagar
   silenciosamente).
4. Responder com os achados **em ordem de importância** e sugerir os próximos comandos de coleta.

Análise profunda é esperada: ausência de uma seção num export ordenado é informação (as seções do
`/export` do RouterOS têm ordem fixa — dá para distinguir "truncado" de "não configurado").

## Regras

- **Credenciais**: os exports contêm senhas/chaves/tokens em texto claro. Tratar como sensível —
  **não copiar valores de credenciais para os docs** (regra registrada em `docs/01`). Tudo será
  rotacionado no descomissionamento (fase 4 do plano).
- **Não portar config 1:1**: o princípio do projeto é redesenho limpo (`docs/05`). Há uma lista
  explícita de "o que NÃO migra" no `docs/04`.
- Ao fechar uma decisão ou invalidar uma premissa, atualizar também o **Status** em
  `docs/00-visao-geral.md` e `docs/03-decisoes-pendentes.md`.

## Contexto técnico mínimo (o que exige ler vários arquivos para entender)

- O RB3011 é um **router-on-a-stick**: ~50 VLANs (estrutura QinQ: tag externa = site, interna =
  serviço) entram por uma única SFP 1GE vinda de um switch de topo de rack **ainda não
  inventariado**. Detalhes em `docs/08`.
- O NE8000 **não é só o futuro firewall** — é o core BGP/OSPF em produção da ISP inteira
  (`docs/06`) e hoje **depende do RB3011** (next-hops, alcance ao route-reflector de FlowSpec) —
  decisão #8. A proposta de resolver isso é a decisão #9 (NE8000 assume o `/27` público).
- Equipamentos: RB3011 e RB2011 saem; DM4170 chega zerado (datasheet em
  `docs/datacom-dm4170-datasheet.pdf` — **não tem NAT**, por isso NAT → NE8000).
