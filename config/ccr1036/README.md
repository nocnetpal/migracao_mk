# CCR1036 - estado da bancada em 2026-08-06

## Aplicado e validado

- Equipamento: CCR1036-8G-2S+ r2.
- RouterOS e RouterBOOT: `7.23.3 stable`.
- Identity: `CCR-GW_PRIV_SERVIDORES-VPN_WG`.
- Gerencia temporaria: `ether1-MGMT`, `192.168.88.1/24`.
- Uplink unico do alvo: `sfp1-TRUNK-DM` para o DM4170; `sfp2-RESERVA` desativada.
- VLAN 16: `177.72.104.4/27`, gateway/default `177.72.104.1`.
- VLAN 100: gateway `192.168.254.1/24`.
- SRC-NAT de `NAT-PRIVADAS` para `177.72.104.4`.
- VLANs, enderecos, rota, lista NAT e regra SRC-NAT ficaram habilitados por decisao do usuario.
- Chain `input`: established/related, drop invalid, ICMP, gerencia de bancada e drop final.
- Chain `forward`: established/related, drop invalid, futuro DST-NAT, privadas para internet e
  drop final.
- IPv6 desativado; MAC server, MAC Winbox e descoberta limitados a `MGMT`.
- Servicos desnecessarios, inclusive `reverse-proxy`, desativados.
- Export criado no equipamento: `ccr-base-ativa-2026-08-06.rsc`.
- `04-acesso-roteado-redes-privadas.rsc`: address-lists (`ORIGENS-GERENCIA`, `REDES-PRIVADAS`),
  3 regras (forward gerencia->privadas, input OSPF do NE8000, forward UDP/123 NTP) e cliente NTP
  da CCR para `192.168.116.10` — aplicados e validados no Terminal.
- Acesso de gerencia confirmado via WireGuard `.19` (RB750): `ORIGENS-GERENCIA` ja inclui
  `177.72.104.19/32`, entao nao e necessario mais nenhuma regra de firewall na CCR para acesso
  administrativo.
- VLAN 15 na CCR: `vlan15-NTP` com `192.168.116.9/30` — aplicada.
- OSPF RouterOS 7 (instance `ospf1` router-id `177.72.104.4`, area `0.0.0.1`) com 6
  interface-templates validados no equipamento: `vlan16-PUBLICA` `type=ptp` `auth=md5`
  `auth-id=1` (chave `ntprb1030` — decisao #11); `vlan100-PRIVADA`, `vlan15-NTP`,
  `vlan66-TS-SIX`, `vlan109-OLT-CPV` e `vlan116-DUDE` passivas.
- `06-vlans-privadas-restantes.rsc`: VLANs 66 (`192.168.66.1/28`), 109 (`192.168.115.41/30`) e
  116 (`192.168.116.29/30`) + templates OSPF passivas + redes adicionadas em `REDES-PRIVADAS` —
  aplicado e validado no Terminal.
- Sintaxe real do firmware 7.23.3 (confirmada com `?` no equipamento): o parametro de chave e
  `auth-key` (NAO `authentication-key`, que da `bad parameter`) e `passive` e flag pura (sem
  `=yes`, que da `expected end of command`). A doc oficial do ROS diverge nesses pontos.
- OSPF ainda sem vizinho: o trunk SFP permanece desconectado (esperado ate o corte).

O trunk SFP permanece fisicamente desconectado. Nao conectar ao dominio de producao enquanto o
RB3011 ainda usar `192.168.254.1` na VLAN 100.

## Planejado, ainda nao aplicado/validado

- Validar OSPF com vizinho: conectar o trunk ao DM4170 e NE8000 e conferir adjacencia FULL
  (`/routing ospf neighbor print`).
- Validar NTP da CCR contra `192.168.116.10` (container ainda precisa estar no ar).
- Liberacao equivalente de UDP/123 no NE8000 (APs/sites consultam o NTP) — lado Huawei pendente.
- ~~Roteamento das demais VLANs privadas locais: pendentes na CCR `vlan66` (`192.168.66.1/28` TS
  SIX), `vlan109` (`192.168.115.41/30` OLT CPV) e `vlan116` (`192.168.116.29/30` Dude).~~ →
  ✅ **aplicado em 2026-08-06** (script `06`). ~~vlan10 (DNS recursivo)~~ e ~~vlan999
  (Callcenter)~~ foram removidos do plano pelo usuario em 2026-08-06.
- ~~DST-NAT Dude/TS SIX: decisao `.1` versus `.4` continua aberta.~~ → ✅ **decisao #9 fechada
  (usuário, 2026-08-06): DST-NAT movem para a CCR `.4`** (`07-dstnat-dude-tssix.rsc`). Quem acessa
  de fora passa a usar `177.72.104.4`. NE8000 sem NAT server nem rota `.1/32`.
- `07` e `08` aplicados e validados: DST-NAT Dude (`:18291`→`192.168.116.30:8291`) e TS SIX
  (`:15389`→`192.168.66.14:15389`) ativos; `NAT-PRIVADAS` agora com VLAN 100, 66 e 116 (OLT 109
  fica fora do NAT, igual ao RB3011 — so gerencia). Consulta DNS dos servidores privados aos DNS
  publicos `.28/.58/.59` sai mascarada como `.4` pela VLAN 16 — sem regra DNS especifica.
- WireGuard: somente depois de toda a migracao concluida e validada.

## Hardware

- Temperaturas e ventoinhas normais na bancada.
- `psu2-state=fail` e esperado: a segunda fonte estava sem alimentacao na bancada.
