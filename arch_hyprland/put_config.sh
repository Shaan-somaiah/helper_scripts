#!/bin/bash
echo "Putting configurations...."

cp -f configs/.bashrc ~
cp -f configs/.bash_profile ~     
cp -f configs/.bash_logout ~
cp -f ../common_deps/.gitconfig ~
cp -rf ../common_deps/kitty ~/.config/
cp -rf configs/waybar ~/.config/
cp -rf configs/hypr ~/.config/
cp -rf configs/rofi ~/.config/
cp -rf ../common_deps/nvim ~/.config/
cp -f ../common_deps/background ~/.config/
mkdir -p ~/.config/libvirt/ && cp -f ../common_deps/libvirt.conf ~/.config/libvirt/

echo "Done putting configurations.."
