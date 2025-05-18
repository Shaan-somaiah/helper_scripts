#!/bin/bash

## ADD NEEDED PACKAGES TO ARR
declare -a myArray
myArray=(`cat ./packages.txt`)

## INSTALL PACKAGES
sudo pacman -Syu --noconfirm 
sudo pacman -S --noconfirm "${myArray[@]}" 

## ENABLE INSTALLED SERVICES
sudo systemctl enable --now gitea 
sudo systemctl enable --now sshd 
sudo systemctl enable --now cronie
sudo systemctl enable --now ufw
sudo systemctl enable --now nfs-server

## SETUP FIREWALL
sudo ufw disable
sudo ufw default deny incoming
sudo ufw default allow outgoing 
sudo ufw limit ssh
sudo ufw allow from 192.168.0.20 to any port 2049
sudo ufw allow 3000
sudo ufw enable

mkdir -p /exports


## PLACE CONFIG FILES
echo "/exports 192.168.0.0/255.255.255.0(rw,sync,no_subtree_check)" >> /etc/exports
echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf

sudo systemctl restart nfs-server

exportfs -arv

echo "SCRIPT DONE , REBOOT NOW"



