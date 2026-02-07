#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file> <path on remote host>"
  echo "Example: $0 file.txt /tmp/"
  exit 1
fi

HOST_LIST="/home/shaan/scripts/host_list"

while read -r ip hostname; do
  ## Skip empty line and comment
  [[ -z "$ip" || "$ip" =~ ^# ]] && continue

  echo "========== $ip $hostname =========="
  scp -o BatchMode=yes -o ConnectTimeout=5 "$1" "$ip:$2"
done < "$HOST_LIST"
