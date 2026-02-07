#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USER=$1

if ! id "$USER" &>/dev/null; then
  echo "User '$USER' does not exist."
  exit 1
fi

# Create a sudoers file in /etc/sudoers.d/
SUDOERS_FILE="/etc/sudoers.d/$USER"
echo "$USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"

# Set correct permissions
chmod 440 "$SUDOERS_FILE"

# Validate syntax
if visudo -cf "$SUDOERS_FILE"; then
  echo "User '$USER' has been added to sudoers.d with NOPASSWD."
else
  echo "Syntax error in sudoers file. Removing it."
  rm -f "$SUDOERS_FILE"
  exit 1
fi

# Start and enable openssh server
sudo systemctl enable --now ssh

# Update cache and upgrade packages
sudo apt update
sudo apt upgrade

# Install qemu quest agent
sudo apt update
sudo apt install qemu-guest-agent

# Truncate machine ID
sudo truncate -s 0 /etc/machine-id

# Disable cloud init
sudo systemctl disable --now cloud-init cloud-init-local cloud-config cloud-final
