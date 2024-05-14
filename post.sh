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

# Hinokitsune
pacman -S --noconfirm noto-fonts noto-fonts-emoji firefox

# Plugins for XFCE
pacman -S --noconfirm xfce4-docklike-plugin

# Good conversions
pacman -S --noconfirm imagemagick

# Printers setup
pacman -S --noconfirm cups \
    sane \
    python-pillow \
    hplip \
    system-config-printers
systemctl enable --now cups.service

echo "You still must run `hp-setup -i`"
