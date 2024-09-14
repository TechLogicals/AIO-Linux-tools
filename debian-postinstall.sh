#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Detect the Linux distribution
DISTRO=$(detect_distro)

# Function to install packages
install_package() {
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt-get install -y "$@"
            ;;
        fedora)
            sudo dnf install -y "$@"
            ;;
        centos|rhel)
            sudo yum install -y "$@"
            ;;
        arch)
            sudo pacman -Syu --noconfirm "$@"
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            exit 1
            ;;
    esac
}

# Function to install SDDM
install_sddm() {
    install_package sddm
    sudo systemctl enable sddm
}

# Function to install and configure fastfetch
install_fastfetch() {
    echo -e "${GREEN}Installing fastfetch...${NC}"
    install_package cmake pkg-config libbsd-dev libcurl4-openssl-dev libdbus-1-dev libdrm-dev libgcrypt20-dev libglib2.0-dev libpci-dev libpng-dev libvulkan-dev libwayland-dev libxcb1-dev libxfixes-dev libxrandr-dev
    git clone https://github.com/LinusDierheimer/fastfetch.git
    cd fastfetch
    mkdir -p build
    cd build
    cmake ..
    cmake --build . --target fastfetch --target flashfetch
    sudo cp fastfetch flashfetch /usr/local/bin/
    cd ../..
    rm -rf fastfetch
    echo "fastfetch" >> ~/.bashrc
    echo -e "${GREEN}Fastfetch installed and configured to run at login.${NC}"
}

# Function to install Meslo Nerd Font and configure terminal
install_and_configure_meslo_nerd_font() {
    echo -e "${GREEN}Installing Meslo Nerd Font...${NC}"
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    curl -fLo "MesloLGS NF Regular.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    curl -fLo "MesloLGS NF Bold.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    curl -fLo "MesloLGS NF Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    curl -fLo "MesloLGS NF Bold Italic.ttf" https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
    fc-cache -f -v

    # Configure terminal font
    if [ -f ~/.config/xfce4/terminal/terminalrc ]; then
        sed -i 's/FontName=.*/FontName=MesloLGS NF Regular 14/' ~/.config/xfce4/terminal/terminalrc
    elif [ -f ~/.config/gnome-terminal/profiles:/:/default ]; then
        dconf write /org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')'/font' "'MesloLGS NF Regular 14'"
    elif [ -f ~/.config/konsole/konsolerc ]; then
        sed -i 's/Font=.*/Font=MesloLGS NF Regular,14,-1,5,50,0,0,0,0,0/' ~/.config/konsole/konsolerc
    else
        echo -e "${YELLOW}Unable to automatically configure terminal font. Please set it manually to MesloLGS NF Regular, size 14.${NC}"
    fi

    echo -e "${GREEN}Meslo Nerd Font installed and terminal configured with font size 14.${NC}"
}

echo -e "${GREEN}Linux Post-Installation Script${NC}"
echo -e "${GREEN}Detected distribution: $DISTRO${NC}"

# Ask if user wants to add a user to sudo
read -p "Do you want to add a user to sudo? (y/n): " add_sudo_user

if [[ $add_sudo_user =~ ^[Yy]$ ]]; then
    read -p "Enter the username to add to sudo: " sudo_username
    if id "$sudo_username" &>/dev/null; then
        sudo usermod -aG sudo "$sudo_username"
        echo -e "${GREEN}User $sudo_username has been added to the sudo group.${NC}"
    else
        echo -e "${RED}User $sudo_username does not exist. Please create the user first.${NC}"
    fi
fi

echo -e "${YELLOW}This script will help you install various desktop environments.${NC}"

# Ask user which desktop environment they want to install
echo -e "\nWhich desktop environment would you like to install?"
echo "1) GNOME"
echo "2) KDE Plasma"
echo "3) Xfce"
echo "4) MATE"
echo "5) Budgie"
echo "6) DWM (Dynamic Window Manager)"
echo "7) None (Skip desktop environment installation)"
read -p "Enter your choice (1-7): " de_choice

case $de_choice in
    1)
        echo -e "${GREEN}Installing GNOME and its dependencies...${NC}"
        install_package gnome gnome-shell gnome-session gnome-terminal nautilus gnome-tweaks gnome-software gnome-control-center gdm3
        ;;
    2)
        echo -e "${GREEN}Installing KDE Plasma and its dependencies...${NC}"
        install_package kde-plasma-desktop plasma-nm plasma-workspace-wayland kde-config-sddm kwin-x11 kwin-wayland dolphin konsole kate systemsettings kscreen
        ;;
    3)
        echo -e "${GREEN}Installing Xfce and its dependencies...${NC}"
        install_package xfce4 xfce4-goodies xfce4-terminal thunar xfce4-settings xfce4-session xfwm4 xfdesktop4 xfce4-panel
        ;;
    4)
        echo -e "${GREEN}Installing MATE and its dependencies...${NC}"
        install_package mate-desktop-environment mate-desktop-environment-extras mate-terminal caja mate-control-center mate-session-manager marco mate-panel
        ;;
    5)
        echo -e "${GREEN}Installing Budgie and its dependencies...${NC}"
        install_package budgie-desktop budgie-core budgie-indicator-applet budgie-standard-assets gnome-terminal nautilus gnome-control-center
        ;;
    6)
        echo -e "${GREEN}Installing DWM and its dependencies...${NC}"
        install_package xorg libx11-dev libxft-dev libxinerama-dev build-essential make gcc xserver-xorg xinit st dmenu
        git clone https://git.suckless.org/dwm
        cd dwm
        sudo make clean install
        cd ..
        rm -rf dwm
        echo "exec dwm" > ~/.xinitrc
        ;;
    7)
        echo -e "${YELLOW}Skipping desktop environment installation.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Skipping desktop environment installation.${NC}"
        ;;
esac

# Install SDDM for all desktop environments except DWM
if [ "$de_choice" != "6" ] && [ "$de_choice" != "7" ]; then
    install_sddm
fi

# Ask if user wants to install fastfetch
read -p "Do you want to display fastfetch on login? (y/n): " install_fastfetch_choice

if [[ $install_fastfetch_choice =~ ^[Yy]$ ]]; then
    install_fastfetch
fi

# Install Meslo Nerd Font and configure terminal
install_and_configure_meslo_nerd_font

echo -e "${GREEN}Post-installation script completed!${NC}"
echo -e "${YELLOW}Please reboot your system for changes to take effect.${NC}"
if [ "$de_choice" != "6" ] && [ "$de_choice" != "7" ]; then
    echo -e "${YELLOW}SDDM has been installed as the display manager.${NC}"
    echo -e "${YELLOW}You can select your preferred desktop environment at the login screen.${NC}"
fi
if [ "$de_choice" == "6" ]; then
    echo -e "${YELLOW}To use DWM, run 'startx' after logging in to your terminal.${NC}"
fi
if [[ $install_fastfetch_choice =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Fastfetch has been configured to run at login.${NC}"
fi
echo -e "${YELLOW}Meslo Nerd Font has been installed and your terminal has been configured to use it with font size 14.${NC}"
echo -e "${YELLOW}If the font change doesn't appear, you may need to restart your terminal or configure it manually.${NC}"
