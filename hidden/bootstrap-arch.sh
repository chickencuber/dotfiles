#!/bin/bash
sudo mkdir -p ~/.config/ 
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
# ly
sudo mkdir -p /etc/ly
if [ -f "/etc/ly/config.ini" ]; then
    sudo rm -f /etc/ly/config.ini
fi
sudo cp ./hidden/lyconfig.ini /etc/ly/config.ini
sudo chown root:root /etc/ly/config.ini
sudo chmod 644 /etc/ly/config.ini
sudo systemctl enable ly@tty1.service
# plymouth 
sudo mkdir -p /usr/share/plymouth/themes/
tar -xzf ./hidden/catppuccin-mocha-plymouth.tar.gz -C /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R catppuccin-mocha
