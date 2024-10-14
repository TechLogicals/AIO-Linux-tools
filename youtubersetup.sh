#!/bin/bash

# Script to set up a Linux system for YouTube creators
# Recommended distribution: Ubuntu (LTS version)
# By @techlogicals
# Function to install desktop environment
install_desktop() {
    case $1 in
        1)
            sudo apt install -y ubuntu-desktop
            ;;
        2)
            sudo apt install -y kde-plasma-desktop
            ;;
        3)
            sudo apt install -y xubuntu-desktop
            ;;
        4)
            sudo apt install -y lubuntu-desktop
            ;;
        5)
            sudo apt install -y ubuntu-mate-desktop
            ;;
        6)
            sudo apt install -y cinnamon-desktop-environment
            ;;
        *)
            echo "Invalid choice. Skipping desktop installation."
            ;;
    esac
}

# Function to detect and install GPU drivers
install_gpu_drivers() {
    if lspci | grep -i nvidia > /dev/null; then
        echo "NVIDIA GPU detected. Installing NVIDIA drivers..."
        sudo add-apt-repository ppa:graphics-drivers/ppa -y
        sudo apt update
        sudo apt install -y nvidia-driver-460
    elif lspci | grep -i amd > /dev/null; then
        echo "AMD GPU detected. Installing AMD drivers..."
        sudo add-apt-repository ppa:oibaf/graphics-drivers -y
        sudo apt update
        sudo apt install -y mesa-vulkan-drivers mesa-vdpau-drivers
    elif lspci | grep -i intel > /dev/null; then
        echo "Intel GPU detected. Installing Intel drivers..."
        sudo apt install -y intel-media-va-driver i965-va-driver
    else
        echo "No supported GPU detected. Skipping driver installation."
    fi
}

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y git curl wget software-properties-common apt-transport-https

# Prompt user to select desktop environment
echo "Select a desktop environment:"
echo "1) GNOME (Ubuntu default)"
echo "2) KDE Plasma"
echo "3) Xfce (Xubuntu)"
echo "4) LXQt (Lubuntu)"
echo "5) MATE"
echo "6) Cinnamon"
echo "7) None (stay with CLI)"
read -p "Enter your choice (1-7): " desktop_choice

if [ "$desktop_choice" != "7" ]; then
    install_desktop $desktop_choice
fi

# Install GPU drivers
install_gpu_drivers

# Install streaming software
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install -y obs-studio

# Install video editing software
sudo add-apt-repository ppa:kdenlive/kdenlive-stable -y
sudo apt update
sudo apt install -y kdenlive openshot

# Install audio editing software
sudo apt install -y audacity

# Install graphics software
sudo apt install -y gimp inkscape

# Install additional multimedia codecs
sudo apt install -y ubuntu-restricted-extras

# Install screen recording and screenshot software
sudo apt install -y kazam flameshot

# Install video conversion tools
sudo apt install -y ffmpeg handbrake

# Install productivity tools
sudo apt install -y libreoffice

# Install communication tools
sudo snap install discord
sudo snap install slack

# Install browser
sudo apt install -y chromium-browser

# Install system monitoring tools
sudo apt install -y htop neofetch

# Install gaming tools (optional, for game streamers)
sudo add-apt-repository ppa:lutris-team/lutris -y
sudo apt update
sudo apt install -y lutris steam

echo "Installation complete. Please reboot your system."
echo "After reboot, make sure to configure OBS Studio and other software as needed."
echo "Remember to install any additional software specific to your workflow."
echo "Enjoy your setup by creating amazing content! and subscribe to our channel! @techlogicals"



