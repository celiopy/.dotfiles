#!/bin/bash

# chaotic setup
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
pacman-key --lsign-key 3056513887B78AEB &&
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' &&
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Append [chaotic-aur] configuration to pacman.conf
chaotic_config="[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n"
echo -e "$chaotic_config" >> /etc/pacman.conf

# Update packages
pacman -Syu --noconfirm

# XDG
pacman -S bash-completion git meson xdg-user-dirs

# Hinokitsune
pacman -S --noconfirm noto-fonts noto-fonts-emoji firefox

# Image thingy
pacman -S --noconfirm imagemagick webp-pixbuf-loader

# Printers setup
pacman -S --noconfirm --needed cups sane python-pillow hplip system-config-printers
systemctl enable --now cups.service

# Plugins for XFCE
pacman -S --noconfirm xfce4-panel-profiles xfce4-docklike-plugin

# Download pfetch
wget https://github.com/Gobidev/pfetch-rs/releases/download/v2.9.1/pfetch-linux-gnu-x86_64.tar.gz

# Extract pfetch
tar -xzf pfetch-linux-gnu-x86_64.tar.gz

# Install pfetch binary
install -Dm755 pfetch /usr/bin/pfetch

# Append line to all user's .bashrc
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        echo "Appending to $user_home/.bashrc"
        echo -e "\n\npfetch" >> "$user_home/.bashrc"
    fi
done

echo "You still must run hp-setup -i"
