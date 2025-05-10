#!/bin/bash


## LOG FILE
#LOGS=~/post_arch.log

## ADD USER TO SUDOERS WITHOUT PASS
chmod +x ../scripts/add_user_to_sudoers.sh 
sudo ../scripts/add_user_to_sudoers.sh $USER 
chmod -x ../scripts/add_user_to_sudoers.sh 

## SET STATIC NW WITH SYSTEMD-NETWORKD
chmod +x ../scripts/configure_network.sh
sudo ../scripts/configure_network.sh 192.168.0.35 192.168.0.1 192.168.0.1 
chmod -x ../scripts/configure_network.sh

## ADD NEEDED PACKAGES TO ARR
declare -a myArray
myArray=(`cat ./packages.txt`)

## INSTALL PACKAGES
sudo pacman -Syu --noconfirm 
sudo pacman -S reflector curl rsync --noconfirm
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &> /dev/null
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm "${myArray[@]}" 
sudo yes 1 | sudo pacman -S firefox --noconfirm

## UPDATE FONT CACHE
fc-cache

## ENABLE INSTALLED SERVICES
sudo systemctl enable --now bluetooth
sudo systemctl enable --now libvirtd
sudo systemctl enable --now cronie

## ADD USER TO NEEDED GROUPS
sudo usermod -aG libvirt,kvm $USER

## REMOVE VIRSH DEFAULT NETWORK
virsh net-autostart --disable default 
virsh net-destroy default
virsh net-undefine default

## SETUP FIREWALL
sudo ufw disable
sudo ufw default deny incoming
sudo ufw default allow outgoing 
sudo ufw enable


## PLACE CONFIG FILES
chmod +x put_config.sh
./put_config.sh
chmod -x put_config.sh

echo "SCRIPT DONE"



