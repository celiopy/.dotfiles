#!/bin/bash

set -euo pipefail  # Exit immediately if a command fails, with error if a variable is unset, and propagate exit code in pipes
readonly LOG_FILE="/var/log/post_install.log"

# Logging function
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    echo "$message"
}

# Error logging function
log_error() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $message" >> "$LOG_FILE"
    echo "ERROR: $message"
}

# Add repository keys and setup Chaotic AUR
setup_chaotic_aur() {
    log "Setting up Chaotic AUR repositories"
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    chaotic_config="\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n"
    echo -e "$chaotic_config" >> /etc/pacman.conf
}

# Update packages
update_packages() {
    log "Updating repositories and packages"
    pacman -Syu --noconfirm
}

# Configure Plymouth
configure_plymouth() {
    log "Configuring Plymouth"

    pacman -S --noconfirm plymouth

    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        sed -i '/^HOOKS=/ s/udev/& plymouth/' /etc/mkinitcpio.conf
    fi

    plymouth-set-default-theme -R spinfinity

    if pacman -Qi "grub" >/dev/null ; then
        sudo sed -i.bak 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        sed -i '/^options / s/rw/rw quiet splash/' /boot/loader/entries/*linu*.conf
    fi
}

# Install necessary packages
install_packages() {
    local packages=(
        "archlinux-wallpaper"
        "xdg-user-dirs"
        "bash-completion"
        "git"
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
        "emacs"
        "libreoffice-fresh"
        "firefox"
        "chromium"
        "discord"
        "imagemagick"
        "webp-pixbuf-loader"
        "vlc"
        "stremio"
        "cups"
        "system-config-printer"
        "sane"
        "python-pillow"
        "python-pyqt5"
        "hplip"
    )

    log "Installing necessary packages"
    pacman -S --noconfirm "${packages[@]}"
    systemctl enable cups.service

    # Install XFCE plugins if XFCE is installed
    if pacman -Qi "xfce4-panel" >/dev/null ; then
        log "Installing XFCE plugins"
        pacman -S --noconfirm xfce4-panel-profiles xfce4-docklike-plugin
    fi
}

# Install pfetch-rs
install_pfetch_rs() {
    log "Installing pfetch-rs"
    wget -qO- https://github.com/Gobidev/pfetch-rs/releases/download/v2.9.1/pfetch-linux-gnu-x86_64.tar.gz | tar -xzf - && install -Dm755 pfetch /usr/bin/pfetch && rm -f pfetch
}

# Append line to all user's .bashrc
append_to_bashrc() {
    log "Appending pfetch to user's .bashrc"
    for user_home in /home/*; do
        echo -e "\n\npfetch" >> "$user_home/.bashrc"
    done
}

# Main function
main() {
    setup_chaotic_aur
    update_packages
    configure_plymouth
    install_packages
    install_pfetch_rs
    append_to_bashrc
    log "Post-installation script completed successfully"
}

main
