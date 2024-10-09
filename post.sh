#!/bin/bash

set -euo pipefail  # Exit immediately if a command fails, with error if a variable is unset, and propagate exit code in pipes
readonly LOG_FILE="/var/log/post_install.log"

# Logging function
log() {
    local message="$1"
    local code="${2:-0}"  # Default to 0 if no code is provided
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message (exit code: $code)" >> "$LOG_FILE"
    echo "$message" ; sleep 1
}

# User confirmation function
confirm() {
    local prompt="$1"
    read -rp "$prompt [Y/n] " choice
    case "$choice" in
        [yY]|[yY][eE][sS]|"") return 0 ;;  # Yes
        *) return 1 ;;  # No
    esac
}

# Add repository keys and setup Chaotic AUR
setup_chaotic_aur() {
    log "Setting up Chaotic AUR repositories"
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        if confirm "This will modify your /etc/pacman.conf to add Chaotic AUR. Proceed?"; then
            pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
            pacman-key --lsign-key 3056513887B78AEB
            pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
            pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
            chaotic_config="[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n"
            echo -e "$chaotic_config" >> /etc/pacman.conf
        else
            log "Chaotic AUR setup canceled."
        fi
    else
        log "Chaotic AUR is already set up."
    fi
}

# Update packages
update_packages() {
    log "Updating repositories and packages"
    if confirm "This will update your system packages. Proceed?"; then
        if ! pacman -Syu --noconfirm; then
            log "Failed to update packages." 1
        fi
    else
        log "Package update canceled."
    fi
}

# Configure Plymouth
configure_plymouth() {
    log "Configuring Plymouth"

    if confirm "This will install and configure Plymouth. Proceed?"; then
        pacman -S --noconfirm plymouth

        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            sed -i '/^HOOKS=/ s/udev/& plymouth/' /etc/mkinitcpio.conf
        fi

        plymouth-set-default-theme -R spinner

        if pacman -Qi "grub" >/dev/null; then
            sudo sed -i.bak 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
            grub-mkconfig -o /boot/grub/grub.cfg
        else
            sed -i '/^options / s/rw/rw quiet splash/' /boot/loader/entries/*linu*.conf
        fi
    else
        log "Plymouth configuration canceled."
    fi
}

# Function to install packages from an array
install_packages_from_array() {
    local category="$1"
    shift
    local packages=("$@")

    log "Installing packages for $category..."
    for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            log "$pkg is already installed."
        else
            log "Installing $pkg..."
            if ! sudo pacman -S --noconfirm "$pkg"; then
                log "Failed to install $pkg for $category." 1
            fi
        fi
    done
    log "Done installing packages for $category."
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

    local video=(
        "vlc"
        "stremio"
        "mpv"
    )

    local libs=(
        "ffmpeg"
        "gstreamer"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "imagemagick"
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
        "video"
        "libs"
        "communication"
        "printing"
        "development"
        "graphics"
    )

    # Loop through categories and install packages
    for category in "${categories[@]}"; do
        local packages
        eval "packages=(\"\${${category}[@]}\")"
        install_packages_from_array "$category" "${packages[@]}"
    done

    # Enable CUPS service
    if confirm "This will enable the CUPS service. Proceed?"; then
        systemctl enable cups.service
    else
        log "CUPS service enabling canceled."
    fi

    # Install XFCE extensions if XFCE is installed
    if pacman -Qi xfce4-panel >/dev/null 2>&1; then
        log "Installing XFCE extensions and locker"
        if confirm "This will install XFCE extensions. Proceed?"; then
            sudo pacman -Rsnc --noconfirm xfce4-screensaver || log "Failed to remove xfce4-screensaver." 1
            sudo pacman -S --noconfirm light-locker mugshot || log "Failed to install XFCE extensions." 1
        else
            log "XFCE extensions installation canceled."
        fi
    fi
}

# Install pfetch-rs
install_pfetch_rs() {
    log "Installing pfetch-rs"
    if confirm "This will download and install pfetch-rs. Proceed?"; then
        if ! wget -qO- https://github.com/Gobidev/pfetch-rs/releases/download/v2.9.1/pfetch-linux-gnu-x86_64.tar.gz | tar -xzf -; then
            log "Failed to download pfetch-rs." 1
            return
        fi
        install -Dm755 pfetch /usr/bin/pfetch || log "Failed to install pfetch." 1
        rm -f pfetch
    else
        log "pfetch-rs installation canceled."
    fi
}

# Append line to all user's .bashrc
append_to_bashrc() {
    log "Appending pfetch to user's .bashrc"
    for user_home in /home/*; do
        if [ -f "$user_home/.bashrc" ]; then
            echo -e "\n\npfetch" >> "$user_home/.bashrc"
        fi
    done
}

cleanup() {
    log "Cleaning up..."
    if pacman -Qtdq | grep -q .; then
        if confirm "This will remove orphaned packages. Proceed?"; then
            sudo pacman -Rns --noconfirm $(pacman -Qtdq) || log "Failed to remove orphaned packages." 1
        else
            log "Orphaned package removal canceled."
        fi
    fi
    if confirm "This will clean the package cache. Proceed?"; then
        sudo pacman -Scc --noconfirm || log "Failed to clean package cache." 1
    else
        log "Package cache cleanup canceled."
    fi
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
    # Backup pacman.conf before modifying
    cp /etc/pacman.conf /etc/pacman.conf.bak

    sed -i '/^#Color/s/^#//; /^#ParallelDownloads/s/^#//' /etc/pacman.conf

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
