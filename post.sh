#!/bin/bash

set -euo pipefail  # Exit immediately if a command fails, with error if a variable is unset, and propagate exit code in pipes
readonly LOG_FILE="/var/log/post_install.log"

# Logging function
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    echo "$message" ; sleep 1
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

    plymouth-set-default-theme -R spinner

    if pacman -Qi "grub" >/dev/null ; then
        sudo sed -i.bak 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        sed -i '/^options / s/rw/rw quiet splash/' /boot/loader/entries/*linu*.conf
    fi
}

#!/bin/bash

# Function to install packages from an array
install_packages_from_array() {
    local category="$1"
    shift
    local packages=("$@")

    echo "Installing packages for $category..."
    sudo pacman -S --noconfirm "${packages[@]}"
    echo "Done."
    echo
}

# Main function
install_packages() {
    # Define arrays for different categories
    local base_system=(
        "base-devel"
        "git"
        "xdg-user-dirs"
    )

    local desktop_environment=(
        "archlinux-wallpaper"
        "lightdm-gtk-greeter-settings"
    )

    local web_browsers=(
        "firefox"
        "chromium"
    )

    local productivity=(
        "libreoffice-fresh"
    )

    local fonts=(
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
    )

    local audio=(
        "audacity"
    )

    local video=(
        "vlc"
        "stremio"
        "obs-studio"
    )

    local multimedia_libraries=(
        "ffmpeg"
        "gstreamer"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "imagemagick"
        "lmms"
        "libdvdcss"
        "libmad"
        "libdvdread"
        "libdvdnav"
        "libbluray"
        "libaacs"
        "webp-pixbuf-loader"
    )

    local communication=(
        "discord"
    )

    local printing=(
        "cups"
        "system-config-printer"
        "hplip"
    )

    local development=(
        "bash-completion"
        "python-pillow"
        "python-pyqt5"
    )

    local graphics=(
        "gimp"
        "inkscape"
    )

    # Array containing all category arrays
    local categories=(
        "base_system"
        "desktop_environment"
        "web_browsers"
        "productivity"
        "fonts"
        "audio"
        "video"
        "multimedia_libraries"
        "communication"
        "printing"
        "development"
        "graphics"
    )

    # Loop through categories and install packages
    for category in "${categories[@]}" ; do
        local packages
        eval "packages=(\"\${${category}[@]}\")"
        install_packages_from_array "$category" "${packages[@]}"
    done

    # Enable CUPS service
    systemctl enable cups.service

    # Install XFCE extensions if XFCE is installed
    if pacman -Qi xfce4-panel >/dev/null 2>&1 ; then
        echo "Installing XFCE exts and locker"
        sudo pacman -Rsnc --noconfirm xfce4-screensaver
        sudo pacman -S --noconfirm light-locker mugshot
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
    for user_home in /home/* ; do
        echo -e "\n\npfetch" >> "$user_home/.bashrc"
    done
}

cleanup() {
    log "Cleaning up..."
    sudo pacman -Rns --noconfirm $(pacman -Qtdq)  # Remove all orphaned packages and their configuration files
    sudo pacman -Scc --noconfirm  # Clean package cache
}


# Prompt user to reboot
prompt_reboot() {
    echo
    read -rp "Do you want to reboot now? [Y/n] " choice
    case "$choice" in
        [yY]|[yY][eE][sS]|"")
            log "Rebooting system"
            systemctl reboot
            ;;
        *)
            log "Post-installation tasks completed. You can manually reboot later."
            ;;
    esac
}

# Main function
main() {
    setup_chaotic_aur
    update_packages
    configure_plymouth
    install_packages
    install_pfetch_rs
    append_to_bashrc

    cleanup
    prompt_reboot
}

main
