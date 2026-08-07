# Plano temporário HubSoft por switch gigabit não gerenciável - 2026-08-05

## Status

✅ Executado e validado em 2026-08-05. HubSoft `.16`, RADIUS `.214` e hypervisor `.13` usam o
novo caminho pela `eno2`; `vmbr0/eno1` ficou sem IP e sem VMs. Como o cabo não pôde ser retirado,
a porta `ether4 - Proxmox HubSoft` foi desativada na RB750 e a `eno1` confirmou `NO-CARRIER`.

## Objetivo

Levar a VLAN 100 diretamente da `bridge-servidores` ao Proxmox HubSoft sem usar o caminho
RB750 -> `ether10` -> `Bridge IP Publico`, que produz QinQ `16,100` no handoff entre as bridges.

## Cabeamento temporário

```text
RB3011 ether8 (VLAN 100 native/untagged + VLAN 16 tagged)
                         |
             switch gigabit não gerenciável
                  |                    |
          Proxmox DNS             HubSoft eno2

HubSoft eno1 -> RB750 ether4 (usado apenas durante a transição; agora sem dependências)
```

O switch apenas replica o L2 que já existe na `ether8`. Não há alteração planejada na RB3011 nem
no Proxmox DNS para inserir o equipamento.

## Sequência segura

1. Energizar o switch sem conectá-lo à rede.
2. Intercalar o switch entre a RB3011 `ether8` e o cabo atual do Proxmox DNS.
3. Conectar somente RB3011 + DNS e validar `.12`, gateway `.1` e VMs públicas na VLAN 16.
4. Se qualquer teste falhar, retirar o switch e reconectar o DNS diretamente à `ether8`.
5. Somente após validar o DNS, conectar uma segunda porta do switch à `eno2` do HubSoft.
6. Manter `eno1` do HubSoft ligada à RB750; ela continua sustentando `.210`, RADIUS `.214` e
   HubSoft `.16` durante a transição.
7. Criar uma bridge nova sobre `eno2` e testar `192.168.254.13/24` em paralelo, sem remover
   `.210/30` nem trocar imediatamente a rota default.

## Migração concluída

- [x] Hypervisor: `.13/24` pela VLAN 100 untagged, gateway `.1`.
- [x] VM HubSoft `.16`: VLAN 16 tagged pelo novo caminho.
- [x] RADIUS `.214`: untagged; gateway `.213/30` movido para `vlan100-servidores`.
- [x] `.210/30` removido; `vmbr0/eno1` sem IP e sem VMs.
- [x] Caminho antigo isolado: `ether4 - Proxmox HubSoft` desativada na RB750; `eno1` sem carrier.

Evidência operacional: [`teste-vmbr1-segundo-cabo-2026-08-05.txt`](teste-vmbr1-segundo-cabo-2026-08-05.txt).

## Restrições

- O switch deve transportar quadros 802.1Q de 1522 bytes sem alterar as tags.
- Não conectar o switch a duas portas da RB3011; isso criaria loop L2.
- Não colocá-lo entre RB750 e `ether10`; esse caminho mantém o problema já diagnosticado.
- O uplink de 1 Gbit/s será compartilhado por DNS e HubSoft.
- Não usar os scripts antigos HubSoft/Zabbix: eles continuam bloqueados porque redesenham o
  RB750 e não correspondem a este plano de dois cabos.
