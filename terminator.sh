#!/bin/bash
# Script to install Terminator terminal emulator on any Linux distribution

# Function to install Terminator on Debian-based distros
install_terminator_debian() {
    sudo apt update
    sudo apt install -y terminator
}

# Function to install Terminator on Red Hat-based distros
install_terminator_redhat() {
    sudo dnf install -y terminator
}

# Function to install Terminator on Arch-based distros
install_terminator_arch() {
    sudo pacman -Syu --needed terminator
}

# Detect the Linux distribution and call the appropriate function
if [ -f /etc/debian_version ]; then
    install_terminator_debian
elif [ -f /etc/redhat-release ]; then
    install_terminator_redhat
elif [ -f /etc/arch-release ]; then
    install_terminator_arch
else
    echo "Unsupported Linux distribution"
    exit 1
fi

echo "Terminator terminal emulator has been installed successfully."
