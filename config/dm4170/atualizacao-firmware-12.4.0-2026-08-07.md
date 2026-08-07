# DM4170 — atualização de firmware para 12.4.0 (bancada, 2026-08-07)

## Antes

| Versão | Estado |
|---|---|
| 9.8.0-263-1-g759c968883 | Active |
| 9.8.0-263-1-g759c968883 | Inactive |

## Procedimento executado

1. Servidor HTTP local (`python -m http.server 8000` em
   `config/dm4170/DmOS-12.4.0-DM4170/Firmware/`) servindo `1139-61-DmOS-12.4.0-DM4170.swu`
   (130.477.056 bytes).
2. Integridade conferida antes do download:
   - md5sum:    `b48fd9be3d0a8ee57ab75a66bdd210f9` ✅ (bate com 1139.txt)
   - sha256sum: `879de6d2b51c80c5c4a6add3d9fd8a1bc5f0d08c9340e0b101c6b8a0c6cf5372` ✅
3. `request firmware add http://192.168.0.49:8000/1139-61-DmOS-12.4.0-DM4170.swu`
   → `Firmware upgrade: Successful operation.`
4. `show firmware` → 12.4.0-270 em `Inactive`
5. `request firmware activate` → confirmado; reboot automático (~3 min de queda do SSH)
6. Pós-reboot: `Last reboot reason: Firmware activation requested by user 'admin'`

## Depois

| Versão | Estado |
|---|---|
| 9.8.0-263-1-g759c968883 | Inactive |
| 12.4.0-270-1-g57b3a30648 | **Active** |

> Config preservada: a ativação não apaga config; o equipamento estava com config de fábrica
> mesmo (factory reset feito antes). Senha admin/admin preservada.
> Manuais do 12.4.0 agora disponíveis localmente em `config/dm4170/DmOS-12.4.0-DM4170/Manual/`.
