#!/bin/bash
old=$(pwd)
cd ~
sudo pacman -S --needed stow git base-devel
yay || {
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
}
cd "$old"
stow .
yay -S --needed - < "./hidden/packagesarch.txt"


