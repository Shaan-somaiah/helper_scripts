#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file> <path on remote host>"
  echo "Example: $0 file.txt /tmp/"
  exit 1
fi

HOST_LIST="/home/shaan/scripts/host_list"

while IFS= read -r host; do
  echo "========== $host =========="
  scp -o BatchMode=yes -o ConnectTimeout=5 "$1" "$host:$2"
done < "$HOST_LIST"
