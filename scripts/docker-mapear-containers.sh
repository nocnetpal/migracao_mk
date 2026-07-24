#!/bin/bash
# Roda DENTRO da VM que tem o Docker instalado (não no host Proxmox). Read-only.
# Uso: bash docker-mapear-containers.sh > /tmp/docker-<vm>.csv
set -euo pipefail

echo "container,imagem,rede,ip,gateway,portas"

for cid in $(docker ps -q); do
  name=$(docker inspect --format '{{.Name}}' "$cid" 2>/dev/null | sed 's#^/##')
  image=$(docker inspect --format '{{.Config.Image}}' "$cid" 2>/dev/null || true)
  portas=$(docker port "$cid" 2>/dev/null | paste -sd ';' - || true)
  networks=$(docker inspect --format \
    '{{range $net,$conf := .NetworkSettings.Networks}}{{$net}}|{{$conf.IPAddress}}|{{$conf.Gateway}}{{"\n"}}{{end}}' \
    "$cid" 2>/dev/null || true)

  if [ -z "$networks" ]; then
    echo "$name,$image,,,,$portas"
    continue
  fi

  while IFS='|' read -r net ip gw; do
    [ -z "$net" ] && continue
    echo "$name,$image,$net,$ip,$gw,$portas"
  done <<< "$networks"
done
