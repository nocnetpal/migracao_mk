#!/bin/bash
# Roda LOCALMENTE em cada host Proxmox (usa qm/pct). Read-only.
# Uso: bash proxmox-mapear-vms.sh > /tmp/proxmox-<cluster>.csv
set -euo pipefail

CAPTURA_SEGUNDOS="${CAPTURA_SEGUNDOS:-8}"

node=$(hostname)
echo "node,tipo,id,nome,status,bridge,vlan,mac,ip_metodo,ips"

resolve_ip_by_mac() {
  local mac="$1"
  [ -z "$mac" ] && return 0
  ip -4 neigh show 2>/dev/null | grep -i "$mac" | awk '{print $1}' | sort -u | paste -sd ';' - || true
}

# Fallback para VMs só bridgeadas (L2 puro): o host nunca fala L3 com elas,
# então ip neigh fica vazio. Captura passiva no tap filtrando pelo MAC da própria
# VM pega o IP de origem em tráfego real (pacotes IP) ou em ARP request (who-has/tell).
capturar_ip_por_tap() {
  local tap="$1" mac="$2"
  [ -z "$tap" ] || [ -z "$mac" ] && return 0
  command -v tcpdump >/dev/null 2>&1 || return 0
  ip link show "$tap" >/dev/null 2>&1 || return 0
  timeout "$CAPTURA_SEGUNDOS" tcpdump -i "$tap" -nn -c 30 "ether src $mac" 2>/dev/null \
    | sed -nE 's/.*IP ([0-9]{1,3}(\.[0-9]{1,3}){3})\.[0-9]+ >.*/\1/p; s/.*tell ([0-9]{1,3}(\.[0-9]{1,3}){3}).*/\1/p' \
    | sort -u | paste -sd ';' - || true
}

parse_net_line() {
  local line="$1"
  local bridge vlan mac
  bridge=$(echo "$line" | grep -oP 'bridge=\K[^,]+' || true)
  vlan=$(echo "$line" | grep -oP '(?:^|,)tag=\K[0-9]+' || true)
  mac=$(echo "$line" | grep -oP '(?:virtio|e1000|e1000e|rtl8139|vmxnet3|hwaddr)=\K[0-9A-Fa-f:]+' || true)
  echo "${bridge}|${vlan}|${mac}"
}

if command -v qm >/dev/null 2>&1; then
  for vmid in $(qm list 2>/dev/null | awk 'NR>1{print $1}'); do
    cfg=$(qm config "$vmid" 2>/dev/null || true)
    name=$(echo "$cfg" | grep -oP '^name:\s*\K.+' || echo "vm$vmid")
    status=$(qm status "$vmid" 2>/dev/null | awk '{print $2}' || echo "?")
    nets=$(echo "$cfg" | grep -E '^net[0-9]+:' || true)
    if [ -z "$nets" ]; then
      echo "$node,qemu,$vmid,$name,$status,,,,sem-rede,"
      continue
    fi
    while IFS= read -r netline; do
      netidx=$(echo "$netline" | grep -oP '^net\K[0-9]+' || true)
      IFS='|' read -r bridge vlan mac <<< "$(parse_net_line "$netline")"
      ips=""
      metodo="nao-encontrado"
      if command -v jq >/dev/null 2>&1 && [ "$status" = "running" ]; then
        agent=$(qm guest cmd "$vmid" network-get-interfaces 2>/dev/null || true)
        if [ -n "$agent" ]; then
          ips=$(echo "$agent" | jq -r --arg mac "$mac" \
            '.[] | select((."hardware-address"//"")|ascii_downcase==($mac|ascii_downcase)) | ."ip-addresses"[]? | select(."ip-address-type"=="ipv4") | ."ip-address"' \
            2>/dev/null | paste -sd ';' - || true)
          [ -n "$ips" ] && metodo="guest-agent"
        fi
      fi
      if [ -z "$ips" ] && [ -n "$mac" ]; then
        ips=$(resolve_ip_by_mac "$mac")
        [ -n "$ips" ] && metodo="arp-neigh"
      fi
      if [ -z "$ips" ] && [ "$status" = "running" ] && [ -n "$netidx" ]; then
        ips=$(capturar_ip_por_tap "tap${vmid}i${netidx}" "$mac")
        [ -n "$ips" ] && metodo="tcpdump-tap"
      fi
      echo "$node,qemu,$vmid,$name,$status,$bridge,$vlan,$mac,$metodo,$ips"
    done <<< "$nets"
  done
fi

if command -v pct >/dev/null 2>&1; then
  for ctid in $(pct list 2>/dev/null | awk 'NR>1{print $1}'); do
    cfg=$(pct config "$ctid" 2>/dev/null || true)
    name=$(echo "$cfg" | grep -oP '^hostname:\s*\K.+' || echo "ct$ctid")
    status=$(pct status "$ctid" 2>/dev/null | awk '{print $2}' || echo "?")
    nets=$(echo "$cfg" | grep -E '^net[0-9]+:' || true)
    if [ -z "$nets" ]; then
      echo "$node,lxc,$ctid,$name,$status,,,,sem-rede,"
      continue
    fi
    while IFS= read -r netline; do
      netidx=$(echo "$netline" | grep -oP '^net\K[0-9]+' || true)
      IFS='|' read -r bridge vlan mac <<< "$(parse_net_line "$netline")"
      ips=""
      metodo="nao-encontrado"
      if [ "$status" = "running" ]; then
        ips=$(pct exec "$ctid" -- ip -4 -o addr show scope global 2>/dev/null \
          | awk '{print $4}' | cut -d/ -f1 | paste -sd ';' - || true)
        [ -n "$ips" ] && metodo="pct-exec"
      fi
      if [ -z "$ips" ] && [ -n "$mac" ]; then
        ips=$(resolve_ip_by_mac "$mac")
        [ -n "$ips" ] && metodo="arp-neigh"
      fi
      if [ -z "$ips" ] && [ "$status" = "running" ] && [ -n "$netidx" ]; then
        ips=$(capturar_ip_por_tap "veth${ctid}i${netidx}" "$mac")
        [ -n "$ips" ] && metodo="tcpdump-tap"
      fi
      echo "$node,lxc,$ctid,$name,$status,$bridge,$vlan,$mac,$metodo,$ips"
    done <<< "$nets"
  done
fi
