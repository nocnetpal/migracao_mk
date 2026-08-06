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

O trunk SFP permanece fisicamente desconectado. Nao conectar ao dominio de producao enquanto o
RB3011 ainda usar `192.168.254.1` na VLAN 100.

## Planejado, ainda nao aplicado/validado

- `04-acesso-roteado-redes-privadas.rsc`: origens de gerencia, destino `REDES-PRIVADAS` e excecao
  de input para OSPF do NE8000. O script foi preparado depois da ultima validacao colada no chat.
- OSPF RouterOS 7 entre NE8000 `177.72.104.1` e CCR `177.72.104.4`, area `0.0.0.1`, sobre a VLAN
  16, com autenticacao; VLANs privadas entram como passivas.
- VLAN 15 na CCR, gateway `192.168.116.9/30`, para o container NTP
  `192.168.116.10/30`. A rede `192.168.116.8/30` sera passiva/anunciada no OSPF.
- Regra de firewall permitindo UDP/123 para `192.168.116.10` a partir das redes roteadas da
  NetPal. A lista exata de prefixos de origem ainda precisa ser consolidada.
- Cliente NTP da propria CCR apontando para `192.168.116.10`; ainda sem saida de validacao.
- Demais VLANs privadas (TS SIX, Dude, DNS recursivo, OLT e outras) a consolidar do RB3011.
- DST-NAT Dude/TS SIX: decisao `.1` versus `.4` continua aberta.
- WireGuard: somente depois de toda a migracao concluida e validada.

## Hardware

- Temperaturas e ventoinhas normais na bancada.
- `psu2-state=fail` e esperado: a segunda fonte estava sem alimentacao na bancada.
