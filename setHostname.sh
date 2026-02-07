#!/bin/bash
set -e

NEW_HOSTNAME="$1"

if [[ -z "$NEW_HOSTNAME" ]]; then
  echo "Usage: $0 <hostname>"
  exit 1
fi

sudo hostnamectl set-hostname "$NEW_HOSTNAME"
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname >/dev/null

sudo sed -i \
  -e "s/^\(127\.0\.1\.1[[:space:]]\+\).*/\1$NEW_HOSTNAME/" \
  -e "s/^\(127\.0\.0\.1[[:space:]]\+\).*/\1localhost $NEW_HOSTNAME/" \
  /etc/hosts

echo "Hostname set to $NEW_HOSTNAME"

