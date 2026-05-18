#!/bin/bash
mkdir -p ~/.config/ 
old=$(pwd)
cd ~
sudo pacman -Syu
sudo pacman -S --needed stow git base-devel
yay || {
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
}
cd "$old"
stow .
./hidden/install-packages-arch.sh
yes | yay -Scc
# plymouth 
sudo mkdir -p /usr/share/plymouth/themes/
tar -xzf ./hidden/catppuccin-mocha-plymouth.tar.gz -C /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R catppuccin-mocha

cd ./hidden/Catppuccin-GTK-Theme/themes/
./build.sh 
./install.sh ./install.sh --tweaks -t mauve -l

