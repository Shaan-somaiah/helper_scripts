#!/bin/bash

cp -f configs/.bashrc ~
cp -f configs/.bash_profile ~
cp -f configs/.bash_logout ~
mkdir -p ~/.local/share/gnome-shell/extensions/ && cp -rf configs/gnome_extensions/* ~/.local/share/gnome-shell/extensions/;
cp -f configs/monitors.xml ~/.config/;
cp -f ../common_deps/background ~/.config/;
cp -rf ../common_deps/kitty ~/.config/
mkdir -p ~/.config/libvirt/ && cp -f ../common_deps/libvirt.conf ~/.config/libvirt/;
cp -f ../common_deps/.gitconfig ~
dconf load -f /org/gnome/ < configs/dconf_settings.ini;
