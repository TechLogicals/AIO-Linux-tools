#!/bin/bash
# Script to install Kitty terminal emulator on any Linux distribution

# Function to install Kitty on Debian-based distros
install_kitty_debian() {
    sudo apt update
    sudo apt install -y kitty
}

# Function to install Kitty on Red Hat-based distros
install_kitty_redhat() {
    sudo dnf install -y kitty
}

# Function to install Kitty on Arch-based distros
install_kitty_arch() {
    sudo pacman -Syu --needed kitty
}

# Detect the Linux distribution and call the appropriate function
if [ -f /etc/debian_version ]; then
    install_kitty_debian
elif [ -f /etc/redhat-release ]; then
    install_kitty_redhat
elif [ -f /etc/arch-release ]; then
    install_kitty_arch
else
    echo "Unsupported Linux distribution"
    exit 1
fi

echo "Kitty terminal emulator has been installed successfully."
