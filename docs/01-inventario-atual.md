# Inventário atual (antes da migração)

> Todo o parque a ser substituído nesse trecho é Mikrotik (não é só o gateway principal).
> Lista de equipamentos ainda sendo levantada — atualizar conforme informações chegarem.

## Equipamentos Mikrotik em uso

| # | Equipamento/Modelo | Identidade (system identity) | Função hoje | Fica ou sai? | Observações |
|---|---------------------|-------------------------------|-------------|--------------|-------------|
| 1 | Mikrotik RB3011 | **GW Servidores** | Ver detalhes completos abaixo | Sai | ⚠️ Export **truncado** (falta todo o início: `/interface*`, `/ip address`, `/ip pool`, `/ip dhcp-server`…) — [`config/rb3011/gw-servidores-export.rsc`](../config/rb3011/gw-servidores-export.rsc), ver [07-enderecamento-ip.md](07-enderecamento-ip.md) |
| 2 | Mikrotik RB2011UiAS | **RB Bridge Servidores** | Bridge L2 simples (switch burro) — pendura na GW Servidores | Sai | Export completo em [`config/rb2011uias/rb-bridge-servidores-export.rsc`](../config/rb2011uias/rb-bridge-servidores-export.rsc) |
| 3 | *(a confirmar)* | | | | |

> ⚠️ O arquivo de export contém credenciais em texto claro (senhas de VPN, usuário/senha de FTP,
> chave MD5 de OSPF, token de API de terceiros). Tratar como sensível — não copiar os valores
> para outros documentos. Rotacionar tudo ao desativar este equipamento.

## Detalhamento: "GW Servidores" (RB3011)

Esse é o Mikrotik citado na primeira mensagem — o "gw servidor". Ele faz **muito mais** que só
NAT/firewall/roteamento entre VLANs; é o ponto onde converge o roteamento dinâmico da rede e o
acesso a diversos sistemas internos do provedor (a ISP **NetPal**, NOC em Capivari do Sul/RS —
confirmado pelo AS 52828 e pela ACL `IPV4_NOC_NETPAL` no NE8000, ver
[06-ne8000-bgp-core.md](06-ne8000-bgp-core.md)).

### Interfaces / enlaces identificados

> ⚠️ **Revisado.** A lista abaixo (8 interfaces) veio da seção OSPF do export truncado e estava
> muito incompleta. O `/ip address print` revelou **101 endereços em ~52 interfaces, sendo ~45
> VLANs** — este equipamento é o roteador de agregação L3 de toda a rede de acesso (POPs, OLTs,
> switches, clientes corporativos), não apenas um gateway de servidores. Inventário completo e
> análise de escala em [07-enderecamento-ip.md](07-enderecamento-ip.md).
>
> ✅ **Topologia física fechada pela coleta 2** ([08-vlans-e-portas.md](08-vlans-e-portas.md)):
> é um **router-on-a-stick** — todas as VLANs (em QinQ) entram por uma única SFP de 1 GE vinda do
> switch de topo de rack; os servidores locais usam `ether6`–`ether10`. E **`ether1`–`ether5`
> estão queimadas** ("ESTRAGADA") — metade das portas do equipamento. A substituição é também uma
> questão de hardware em degradação, não só de arquitetura.

Interfaces originalmente identificadas (subconjunto):
- `sfp1 - UPLINK SW TOPO DO RACK` — uplink para o switch no topo do rack; carrega **duas** sub-redes
  (`192.168.116.34/30` e `177.72.104.53/30`), ambas com o NE8000 do outro lado
- `ether3`
- `Bridge IP Publico` — `177.72.104.1/27` + ~24 sub-redes privadas (multinetting pesado)
- `VLAN13 - DUDE` — link dedicado ao servidor de monitoramento (The Dude)
- `VLAN713 - GW SOLIDAO` — enlace ponto a ponto (`172.31.254.33/30`)
- `VLAN11_eoip` — túnel EoIP; leva `192.168.15.49/30` = **"GERENCIA SW DATACOM"** (já existe um
  Datacom gerenciado na rede)
- `VLAN198 - Pantano => Juca Ana` — enlace ponto a ponto com IP público (`177.72.104.61/30`)
- `loopback` — `172.16.200.5/32`

### Roteamento — **OSPF ativo (area1)**
- O MK é vizinho OSPF de outros equipamentos da rede, com autenticação MD5 em quase todas as
  interfaces P2P listadas acima. **Isso não estava mapeado antes** — ele não é só borda, participa
  do roteamento dinâmico interno da rede toda.
- Dezenas de redes `/30` e algumas `/24` anunciadas na area1 (enlaces ponto a ponto para POPs/torres
  e sub-redes internas de servidores, faixas `192.168.x.x` e `172.x.x.x`).
- Rotas estáticas adicionais: default via `192.168.116.33` (comentário "NETPAL"), e rotas
  específicas para `10.8.0.0/21`, `10.30.0.0/30`, `10.150.150.0/24`, `10.254.0.0/22`,
  `192.168.88.0/24`, além de rotas fixas para os dois loopbacks de DNS.
- Filtro de rota OSPF: só aceita anunciar `177.72.104.56/30` (rota de entrada filtrada).

### NAT
- **SRC-NAT**: tráfego da address-list `NAT` (e `NAT_RADIUS`) sai mascarado como `177.72.104.1`
  (exceto quando o destino é `192.168.116.30`).
- **DST-NAT (port-forward)**:
  - `177.72.104.1:18291` → `192.168.116.30:8291` (Winbox do servidor "The Dude")
  - `177.72.104.1:15389` → `192.168.66.14:15389` ("TS SIX")

### Firewall
- Dezenas de regras `accept` liberando, por IP de destino específico, acesso a sistemas internos
  da operação: **Hubsoft** (billing/ERP do provedor), **Fusion Netpal** (RADIUS/PPPoE de
  assinantes — clientes "elaborados" e "simples"), **SBC/TIP VOIP**, **OPA Suite** (chat, com regra
  específica restringindo a porta 45345 por lista de rede liberada), DNS internos, "Dude"
  (monitoramento), "Servidor sala", **CallSys**, **Belluno**, **SixTelecom**, **CGNAT**.
- Bloqueios explícitos de portas de gerência (SSH 15320, Winbox 8291, API 8728/8729, WWW 8858,
  4443, Telnet 21-23/2323, MySQL 3306, 2122/2534/2756/27591 etc.) para quem **não** está na
  address-list `RANGENETPAL` — proteção do acesso de gerência contra a internet.
- Address-list **`BRASIL`**: centenas de faixas de IP nacionais (provavelmente para permitir
  apenas tráfego de origem brasileira em determinados serviços/geo-allowlist). Propósito exato a
  confirmar antes de decidir se e onde recriar essa lógica.
- Mangle: clamp de MSS para PMTU em SYN (ajuste de MTU, comum atrás de PPPoE/túneis).

### VPN
- Regra de firewall liberando UDP 500, 1701, 4500 — mas em `chain=forward`, **não** `chain=input`.
- Usuários PPP individuais para acesso remoto de equipe: `bruno`, `vpnbruno`, `isaac`, `leonardo`.
  Apenas `bruno` e `isaac` usam `profile=default-encryption`; os outros dois caem no profile padrão,
  sem criptografia obrigatória.
- ⚠️ **Não há `/ip ipsec peer` nem `/ip ipsec identity` no export** (ausência confirmada, não é efeito
  do truncamento). Apesar do nome da regra, isso **não é IPSec**. Se a VPN termina aqui ou em outro
  equipamento ainda é ambíguo — análise completa em
  [07-enderecamento-ip.md](07-enderecamento-ip.md).

### Outros serviços rodando neste MK
- **SNMP** habilitado (contato `noc@netpal.com.br`, local "Capivari do Sul").
- **NTP client** apontando para `192.168.116.10`.
- **Backup automático semanal** (scheduler + script `backup_ftp`): gera backup + export e envia
  por FTP para um servidor interno, depois limpa os arquivos locais.
- **Script de notificação** (`dude`, acionado por netwatch/probes): dispara mensagem via API HTTP
  de terceiros (estilo WhatsApp) quando um dispositivo monitorado sobe/cai.
- Serviços de gerência com portas não-padrão e allowlist de IP: SSH (porta 15320), API, Winbox,
  FTP — todos restritos a faixas específicas (`RANGENETPAL`, IPs públicos próprios).
- Netwatch: monitora `200.160.0.8`, habilita/desabilita a rota "NETPAL" automaticamente conforme
  o host responde (hoje desabilitado).

## Detalhamento: "RB Bridge Servidores" (RB2011UiAS)

Confirmado pelo usuário: **esse equipamento sai da GW Servidores** — ou seja, é um switch pendurado
diretamente na "GW Servidores" (rede `192.168.116.20/30`, gateway `192.168.116.21` = provavelmente
a própria GW Servidores ou algo nesse segmento ponto a ponto).

- Função: **puro bridge L2** — todas as 10 portas ethernet (`ether1`–`ether10`) estão no mesmo
  `bridge1`. Não faz roteamento, NAT, firewall ou DHCP. É essencialmente um switch não-gerenciado
  (mas com gerência habilitada via IP de management).
- Uma única porta SFP existe e está desabilitada.
- Mesma automação de backup semanal via FTP do "GW Servidores" (mesmo script, mesmo servidor de
  destino `177.72.104.131`, mesmas credenciais).
- Mesmo NTP, mesmo contato SNMP (`noc@netpal.com.br`, "Capivari do Sul").
- Portas de gerência com o mesmo padrão de allowlist (SSH 15320, Winbox, FTP 2122) do outro MK.

### ⚠️ Achado de segurança (não relacionado à migração em si, mas vale registrar)
- **SNMP community com `write-access=yes` e `addresses=0.0.0.0/0`** — ou seja, qualquer IP na
  internet pode usar a community `netpaltelecom` para **escrever** configuração via SNMP. Isso é
  uma exposição séria, independente da migração. Recomendo restringir o range de IP e revogar
  write-access assim que possível, e **não replicar essa configuração** no Datacom.
- ~~O log de boot mostra tentativas de login falhas no Winbox vindas de `177.93.244.165`~~ —
  ✅ **reclassificado**: esse IP é o **endpoint do NOC/site remoto** (fecha o túnel EoIP com a GW
  Servidores e está na ACL de gerência `IPV4_NOC_NETPAL` do NE8000). As falhas eram quase
  certamente acesso legítimo com senha errada, não força bruta. Ver
  [08-vlans-e-portas.md](08-vlans-e-portas.md).

Como é um switch L2 puro sem nenhuma função de rede além de "encaminhar pacote", a substituição
dele pelo Datacom é direta — não há lógica de roteamento/NAT/firewall para migrar, só portas físicas.

## Funções desempenhadas hoje pelo(s) Mikrotik(s)

- [x] NAT / Firewall (com port-forward e regras por sistema interno)
- [x] Roteamento entre VLANs
- [x] **Roteamento dinâmico (OSPF)** com vizinhança/autenticação — descoberto ao analisar o export
- [x] VPN — **L2TP puro, sem IPSec** (`use-ipsec: no` confirmado), 4 usuários locais. ~~Possível
      segundo serviço OpenVPN (pool `ovpn-pool` existe) — confirmar.~~ ✅ **confirmado (coleta 2):
      OpenVPN habilitado** (TCP 1194, certificado de cliente obrigatório, AES-256) — ver decisão
      #5 em [03-decisoes-pendentes.md](03-decisoes-pendentes.md).
- [x] DHCP Server — **existe, mas é mínimo**: 1 servidor operante (`VLAN1066 - GERADOR MST`) + 1
      inválido. 8 de 10 pools são órfãos. Ver [07-enderecamento-ip.md](07-enderecamento-ip.md).
- [ ] PPPoE/Hotspot — não aparece neste MK; "Fusion Netpal" parece ser o sistema de RADIUS/PPPoE
      dos assinantes, mas rodando em servidor à parte, não no MK

## Topologia atual

- Este MK ("GW Servidores") fica entre o uplink do rack (`sfp1`) e uma série de enlaces para
  outros POPs/torres (Solidão, Pantano) e para servidores internos da operação.
- ~~Falta mapear: onde entra o NE8000 na topologia atual (já existe e faz parte da area1 OSPF, ou é
  um equipamento novo que ainda vai entrar?), e o desenho físico completo (quem conecta em cada
  porta do MK hoje).~~ ✅ **Resolvido:** o NE8000 já existe e é vizinho OSPF hoje, pela
  subinterface `Gi0/1/8.28` (VLAN 28, via switch de topo de rack) — ver
  [06-ne8000-bgp-core.md](06-ne8000-bgp-core.md). O desenho físico do MK foi fechado na coleta 2
  (router-on-a-stick na `sfp1` + servidores em `ether6`–`ether10`) — ver
  [08-vlans-e-portas.md](08-vlans-e-portas.md).

## Perguntas em aberto para fechar o inventário

> ✅ **Inventário técnico concluído** (coletas 1 e 2) — a maioria destas perguntas já foi
> respondida; mantidas aqui com o encaminhamento de cada uma. As pendências vivas migraram para
> [03-decisoes-pendentes.md](03-decisoes-pendentes.md).

- Quantos outros equipamentos Mikrotik existem nesse trecho, e o que cada um faz? (este primeiro,
  "GW Servidores", já está mapeado em detalhe) — **ainda em aberto**, aguardando lista do usuário
  (decisão #2)
- ~~O NE8000 já participa da OSPF area1 hoje, ou é um componente novo do desenho alvo?~~ —
  ✅ **já participa**: vizinho OSPF pela subinterface `Gi0/1/8.28`, mesma area1 e mesma chave MD5
  (decisão #4, [06-ne8000-bgp-core.md](06-ne8000-bgp-core.md))
- ~~DHCP: onde está rodando hoje, se não é neste MK?~~ — ✅ **está neste MK sim**, mas é mínimo:
  1 único escopo operante (`VLAN1066 - GERADOR MST`); decisão #1 encerrada
- ~~A address-list `BRASIL` (geo-allowlist) precisa ser recriada no novo desenho?~~ — ✅ **não:
  decidido descartar** ([05-limpeza-politicas.md](05-limpeza-politicas.md), passo 2)
- O que fazer com VPN L2TP/IPSec de equipe, backup automático e notificações via API — esses
  serviços não têm equivalente natural em um switch L3; precisam de outro lugar para rodar.
  — **parcialmente respondido**: a VPN não é L2TP/IPSec (é L2TP sem criptografia + OpenVPN, ambos
  neste MK); o **destino** dos dois serviços e das automações segue em aberto (decisões #5 e #6)
