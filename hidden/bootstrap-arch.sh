#!/bin/bash
old = $(pwd)
mkdir -p ~/.config/ 

# add chaotic aur
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

sudo cp ./hidden/pacman.conf /etc/pacman.conf
# finish
sudo pacman -Syu
sudo pacman -S --needed stow git base-devel

stow .
./hidden/install-packages-arch.sh
yes | sudo pacman -Scc
# plymouth 
sudo mkdir -p /usr/share/plymouth/themes/
tar -xzf ./hidden/catppuccin-mocha-plymouth.tar.gz -C /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R catppuccin-mocha
cd "$old"
cd ./hidden/Catppuccin-GTK-Theme/themes/
./build.sh 
./install.sh ./install.sh --tweaks -t mauve -l

# papirus-catppuccin
cd "$old"
cd ./hidden/papirus-folders/
sudo cp -r src/* /usr/share/icons/Papirus  
curl -LO https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders && chmod +x ./papirus-folders
./papirus-folders -C cat-mocha-mauve --theme Papirus-Dark
cd "$old"
