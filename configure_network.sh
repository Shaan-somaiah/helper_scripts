#!/bin/bash

# Script to configure network using systemd-networkd (Disables NetworkManager)
# Usage:
#	FOR DHCP 		./configure_network.sh dhcp
#	FOR STATIC IP 	./configure_network.sh <IP> <GATEWAY> <DNS>

# Function to setup bridge interface 

setBridge() {
	cat <<EOF | sudo tee /etc/systemd/network/br.netdev	
[NetDev]
Name=br0
Kind=bridge

EOF

	cat <<EOF | sudo tee /etc/systemd/network/1-br0-bind.network
[Match]
Name=en*

[Network]
Bridge=br0

EOF
} 

# Function to set DHCP

setDhcp() {
	
	cat <<EOF | sudo tee /etc/systemd/network/2-br0-dhcp.network
[Match]
Name=br0

[Network]
DHCP=ipv4

EOF
}

# Function to check if provided ip is valid

isValidIp() {
	local answer=0
	arguments = "$1 $2 $3"
	for argument in arguments
	do
		if [[ "$argument" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
  			answer=$((answer + 1))
		fi
	done	
	
	if [ $answer -eq 3 ]
	then
		return 0
	else
		return 1
	fi	
}

# Function to set static ip

setStaticIp() {

	cat <<EOF | sudo tee /etc/systemd/network/2-br0-static.network
[Match]
Name=br0

[Network]
Address=$1/24
Gateway=$2
DNS=$3

EOF
}

# Function to print error

printError() {

	echo "Usage : "
	echo "For dhcp : $0 dhcp"
	echo "For static ip : $0 <IP> <GATEWAY> <DNS>"

}

# Function to cleanup and prepare environment for new configurations

cleanUp() {

	sudo systemctl disable --now NetworkManager &> /dev/null
	sudo systemctl stop systemd-networkd &> /dev/null
	sudo rm /etc/systemd/network/*
}

# Logic for dhcp
if [ "$#" -eq 1 ] && [ "$1" == "dhcp"  ]
then
	cleanUp
	setBridge
	setDhcp
	sudo systemctl enable --now systemd-networkd &> /dev/null
	echo "Done setting up DHCP"

# Logic for static IP	
elif [ "$#" -eq 3 ] 
then
	cleanUp
	setBridge
	setStaticIp $1 $2 $3
	sudo systemctl enable --now systemd-networkd &> /dev/null
	echo "Done setting up Static IP"
# Error handling
else
	printError
fi


















