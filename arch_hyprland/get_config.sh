#!/bin/bash
echo "Getting configurations...."

mkdir -p configs
mkdir -p ../common_deps

cp -f ~/.gitconfig ../common_deps/
cp -f ~/.bashrc configs/
cp -f ~/.bash_profile configs/   
cp -f ~/.bash_logout configs/
cp -rf ~/.config/kitty/ ../common_deps/
cp -rf ~/.config/waybar/ configs/
cp -rf ~/.config/hypr/ configs/
cp -rf ~/.config/rofi/ configs/
cp -rf ~/.config/nvim/ ../common_deps/
cp -f ~/.config/background ../common_deps/

echo "Done getting configurations.."
