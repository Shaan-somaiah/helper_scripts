#!/bin/bash

## Print usage
if [ $# -eq 0 ]; then
  echo "Usage $0 <command>"
  echo "Example $0 uptime"
  exit 1
fi

HOST_LIST="/home/shaan/scripts/host_list"

while IFS= read -r host; do
  echo "========== $host =========="
  ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$host" "$@"
done < "$HOST_LIST"
