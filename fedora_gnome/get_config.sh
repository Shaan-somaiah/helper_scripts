#!/bin/bash
echo "Getting configurations...."

mkdir -p ./configs/
mkdir -p ../common_deps/

cp -f ~/.gitconfig ../common_deps/
cp -f ~/.bashrc configs/
cp -f ~/.bash_profile configs/
cp -f ~/.bash_logout configs/
cp -rf ~/.config/nvim/ ../common_deps/
cp -rf ~/.local/share/gnome-shell/extensions/* configs/ 
cp -f ~/.config/monitors.xml configs/
cp -f ~/.config/libvirt/libvirt.conf ../common_deps/
cp -f ~/.config/background ../common_deps/
dconf dump /org/gnome/ > configs/dconf_settings.ini;


echo "Done getting configurations.."
