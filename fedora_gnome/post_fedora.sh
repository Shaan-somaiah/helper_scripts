#!/bin/bash

## ADD USER TO SUDOERS WITHOUT PASS
chmod +x ../scripts/add_user_to_sudoers.sh 
sudo ../scripts/add_user_to_sudoers.sh $USER 
chmod -x ../scripts/add_user_to_sudoers.sh

# SET LOG DEST
LOGS=post_fedora.log
date > $LOGS

## SET STATIC NW WITH SYSTEMD-NETWORKD
chmod +x ../scripts/configure_network.sh
sudo ../scripts/configure_network.sh 192.168.0.25 192.168.0.1 192.168.0.1 
chmod -x ../scripts/configure_network.sh

#INSTALL UPDATES
echo -n > $LOGS;
date | tee -a $LOGS;
echo "Running dnf update.This may take a while...." | tee -a $LOGS;
sudo dnf update -y &>> $LOGS ;
echo "Done running dnf update" | tee -a $LOGS;


#ADD PACKAGES FROM INSTALL_PACKAGES FILE
echo "Installing packages from install_packages.txt" | tee -a $LOGS;
xargs sudo dnf install -y < install_packages.txt &>> $LOGS;
sudo dnf group install --with-optional virtualization -y &>> $LOGS;
echo "Done installing packages" | tee -a $LOGS;


#REMOVE PREINSTALLED PACKAGES
echo "Removing packages from remove_packages.txt" | tee -a $LOGS;
xargs sudo dnf remove -y < remove_packages.txt &>> $LOGS;
sudo rpm -e --nodeps gnome-contacts &>> $LOGS; 
sudo rpm -e --nodeps gnome-connections &>> $LOGS;
sudo rpm -e --nodeps gnome-boxes &>> $LOGS; 
sudo rpm -e --nodeps gnome-disk-utility &>> $LOGS;
sudo rpm -e --nodeps gnome-tour &>> $LOGS;
sudo rpm -e --nodeps gnome-maps &>> $LOGS;
sudo rpm -e --nodeps baobab &>> $LOGS;
sudo rpm -e --nodeps gnome-system-monitor &>> $LOGS;
sudo rpm -e --nodeps gnome-logs  &>> $LOGS;
sudo rpm -e --nodeps rhythmbox  &>> $LOGS;
sudo rpm -e --nodeps mediawriter &>> $LOGS;
sudo rpm -e --nodeps gnome-abrt  &>> $LOGS;
sudo rpm -e --nodeps libreoffice-writer  &>> $LOGS;
sudo rpm -e --nodeps libreoffice-calc  &>> $LOGS;
sudo rpm -e --nodeps libreoffice-impress  &>> $LOGS;
sudo rpm -e --nodeps malcontent-0  &>> $LOGS;
sudo rpm -e --nodeps malcontent-libs  &>> $LOGS;
sudo rpm -e --nodeps malcontent-ui-libs  &>> $LOGS;
sudo rpm -e --nodeps malcontent-control  &>> $LOGS;
echo "Done removing preinstalled packages" | tee -a $LOGS;


#ENABLE FIREWALL
echo "Setting up firewall" | tee -a $LOGS;
sudo ufw disable &>> $LOGS;
sudo ufw default deny incoming &>> $LOGS;
sudo ufw default allow outgoing &>> $LOGS;
sudo ufw enable &>> $LOGS;
echo "Done setting up firewall" | tee -a $LOGS;


#VIRTUALIZATION SETUP 
echo "Setting up virtualization" | tee -a $LOGS;
sudo systemctl enable --now libvirtd &>> $LOGS;
sudo usermod -aG libvirt,kvm $USER &>> $LOGS;
echo "Done setting up Virtualisation" | tee -a $LOGS;


#SETTING UP CONFIG FILES
chmod +x put_config.sh;
./put_config.sh
chmod -x put_config.sh


#SETTING UP VM NETWORKING AND HOSTNAME
virsh net-autostart --disable default &>> $LOGS;
virsh net-destroy default &>> $LOGS;
virsh net-undefine default $>> $LOGS;
sudo hostnamectl set-hostname fedora &>> $LOGS;
sudo dnf autoremove -y &>> $LOGS;

#EOS
echo "SCRIPT ENDED , ENJOY YOUR SYSTEM";
