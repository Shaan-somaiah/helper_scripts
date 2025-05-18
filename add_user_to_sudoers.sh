#!/bin/bash

# Check if a username is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# The username to be added to sudoers
USER=$1

# Check if the user exists
if ! id "$USER" &>/dev/null; then
  echo "User '$USER' does not exist."
  exit 1
fi

# Backup the sudoers file before making any changes
cp /etc/sudoers /etc/sudoers.bak

# Add the user to sudoers without password
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Check if the operation was successful
if [ $? -eq 0 ]; then
  echo "User '$USER' has been added to sudoers with no password prompt."
else
  echo "An error occurred while modifying sudoers."
  exit 1
fi




