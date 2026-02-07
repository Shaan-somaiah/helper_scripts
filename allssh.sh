#!/bin/bash

## Print usage
if [ $# -eq 0 ]; then
  echo "Usage $0 <command>"
  echo "Example $0 uptime"
  exit 1
fi

HOST_LIST="/home/shaan/scripts/host_list"

while read -r ip hostname; do
  ## Skip comment / empty line
  [[ -z "$ip" || "$ip" =~ ^# ]] && continue

  echo "========== $ip $hostname =========="
  ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$ip" "$@"
done < "$HOST_LIST"
