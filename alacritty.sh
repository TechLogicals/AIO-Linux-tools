#!/bin/bash
#by TechLogicals
# Function to install Alacritty on Debian-based distros
install_alacritty_debian() {
    sudo apt update
    sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
    git clone https://github.com/alacritty/alacritty.git
    cd alacritty
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
}

# Function to install Alacritty on Red Hat-based distros
install_alacritty_redhat() {
    sudo dnf install -y cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++
    git clone https://github.com/alacritty/alacritty.git
    cd alacritty
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
}

# Function to install Alacritty on Arch-based distros
install_alacritty_arch() {
    sudo pacman -Syu --needed cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python
    git clone https://github.com/alacritty/alacritty.git
    cd alacritty
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
}

# Detect the Linux distribution and call the appropriate function
if [ -f /etc/debian_version ]; then
    install_alacritty_debian
elif [ -f /etc/redhat-release ]; then
    install_alacritty_redhat
elif [ -f /etc/arch-release ]; then
    install_alacritty_arch
else
    echo "Unsupported Linux distribution"
    exit 1
fi

echo "Alacritty installation complete."
