#!/bin/bash

set -e  # Exit immediately if a command fails
log_file="/var/log/post_install.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
    echo ""
    echo $1
}

hide_desktop_files() {
    local APPLICATION_PATH="/usr/share/applications"
    local FIRST_USER_HOME=$(ls -d /home/* | head -n 1)
    local USER_APPLICATION_PATH="${FIRST_USER_HOME}/.local/share/applications"
    local files=("$@")

    for FILE in "${files[@]}"; do
        if [ -e "${APPLICATION_PATH}/${FILE}" ]; then
            echo "Creating file ${USER_APPLICATION_PATH}/${FILE}"
            echo "NoDisplay=true" > "${USER_APPLICATION_PATH}/${FILE}"
        elif [ ! -e "${APPLICATION_PATH}/${FILE}" ] && [ -e "${USER_APPLICATION_PATH}/${FILE}" ]; then
            echo "Deleting unnecessary file ${USER_APPLICATION_PATH}/${FILE}"
            rm "${USER_APPLICATION_PATH}/${FILE}" 
        fi
    done
}

# Make it less stupid
log "Stupid shit"
echo -e "\nDefaults pwfeedback" >> /etc/sudoers
sed -i '/^#Color/s/^#//' /etc/pacman.conf
sed -i 's/\(OPTIONS=.*\) debug/\1 !debug/' /etc/makepkg.conf

# List of files to process
files=(
    "avahi-discover.desktop" \
    "bssh.desktop" \
    "bvnc.desktop" \
    "qv4l2.desktop" \
    "qvidcap.desktop"
)

# Call the function with the list of files
log "Hide those pesky little shits"
hide_desktop_files "${files[@]}"

# chaotic setup
log "Setting up chaotic repositories"
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
pacman-key --lsign-key 3056513887B78AEB &&
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' &&
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Append [chaotic-aur] configuration to pacman.conf
log "Configuring pacman.conf for chaotic-aur"
chaotic_config="\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n"
echo -e "$chaotic_config" >> /etc/pacman.conf

# Update packages
log "Updating repositories and packages"
pacman -Syu --noconfirm

# Completing installation (?)
log "Completing Arch install"
pacman -S --noconfirm plymouth xdg-user-dirs

# Configure plymouth, setting default theme automatically regenerates the image
log "Adding plymouth and setting plymouth theme"
HOOKS_LINE=$(grep "^HOOKS=" /etc/mkinitcpio.conf); if ! echo "$HOOKS_LINE" | grep -q "plymouth"; then sudo sed -i '/^HOOKS=/ s/udev/& plymouth/' /etc/mkinitcpio.conf; fi
sed -i '/^options / s/rw/rw quiet splash/' /boot/loader/entries/*linux-zen.conf
plymouth-set-default-theme -R spinfinity

# Devel Things
log "Installing building stuff"
pacman -S --noconfirm bash-completion git meson

# Hinokitsune
log "Installing Hinokitsune and fonts packages"
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk firefox

# Other apps?
log "Installs some other apps"
pacman -S --noconfirm chromium discord

# Image thingy
log "Installing Image related packages"
pacman -S --noconfirm imagemagick webp-pixbuf-loader

# HP Printers Setup
log "Setting up printers"
pacman -S --noconfirm --needed cups system-config-printer
systemctl enable cups.service

log "Installing hplip and deps"
sudo pacman -S --noconfirm sane python-pillow python-pyqt5 hplip
log "NOTE: After reboot run hp-setup -i"

# Plugins for XFCE, thanks to chaotic-aur
log "Installing XFCE plugins"
pacman -S --noconfirm xfce4-panel-profiles xfce4-docklike-plugin

# pfetch-rs | rust fork of pfetch
log "Installing pfetch-rs"
wget -qO- https://github.com/Gobidev/pfetch-rs/releases/download/v2.9.1/pfetch-linux-gnu-x86_64.tar.gz | tar -xzf - && install -Dm755 pfetch /usr/bin/pfetch && rm -f pfetch

# Append line to all user's .bashrc
log "Appending pfetch to user's .bashrc"
echo -e "\n\npfetch" >> $(ls -d /home/* | head -n 1)/.bashrc
