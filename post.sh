#!/bin/bash

set -e  # Exit immediately if a command fails
log_file="/var/log/post_install.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# chaotic setup
log "Setting up chaotic repositories"
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
pacman-key --lsign-key 3056513887B78AEB &&
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' &&
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Append [chaotic-aur] configuration to pacman.conf
log "Configuring pacman.conf for chaotic-aur"
chaotic_config="[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n"
echo -e "$chaotic_config" >> /etc/pacman.conf

# Update packages
log "Updating packages"
pacman -Syu --noconfirm

# XDG
log "Installing XDG related packages"
pacman -S --noconfirm bash-completion git meson xdg-user-dirs

# Hinokitsune
log "Installing Hinokitsune packages"
pacman -S --noconfirm noto-fonts noto-fonts-emoji firefox

# Image thingy
log "Installing Image related packages"
pacman -S --noconfirm imagemagick webp-pixbuf-loader

# Printers setup
log "Setting up printers"
pacman -S --noconfirm --needed sane python-pillow cups hplip system-config-printer
systemctl enable cups.service

# Plugins for XFCE
log "Installing XFCE plugins"
pacman -S --noconfirm xfce4-panel-profiles xfce4-docklike-plugin

# pfetch-rs | rust fork of pfetch
log "Installing pfetch-rs"
wget -qO- https://github.com/Gobidev/pfetch-rs/releases/download/v2.9.1/pfetch-linux-gnu-x86_64.tar.gz | tar -xzf - && install -Dm755 pfetch /usr/bin/pfetch && rm -f pfetch

# Append line to all user's .bashrc
log "Appending pfetch to all users' .bashrc"
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        echo "Appending to $user_home/.bashrc"
        echo -e "\n\npfetch" >> "$user_home/.bashrc"
    fi
done

# Make it less stupid
log "Configuring sudoers"
echo -e "\nDefaults pwfeedback" >> /etc/sudoers

echo "You still must run hp-setup -i"
