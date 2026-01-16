#!/bin/bash
old=$(pwd)
cd ~
sudo pacman -Sy
sudo pacman -S --needed stow git base-devel
yay || {
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
}
cd "$old"
stow .
while IFS= read -r pkg; do
    echo "Installing $pkg..."
    yay -S --needed "$pkg" --noconfirm </dev/tty 
done < "./hidden/packagesarch.txt"


