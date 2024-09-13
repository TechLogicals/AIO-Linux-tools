#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to install packages
install_package() {
    sudo apt-get install -y $1
}

# Function to ask yes/no questions
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Add user to sudo group
echo -e "${YELLOW}Adding current user to sudo group...${NC}"
sudo usermod -aG sudo $USER

# Install neofetch
echo -e "${YELLOW}Installing neofetch...${NC}"
install_package neofetch

# Configure neofetch to run at login
echo -e "${YELLOW}Configuring neofetch to run at every login...${NC}"
echo "neofetch" >> ~/.bashrc

# Ask which MesloLGS NF font to install
echo -e "${YELLOW}Which MesloLGS NF font would you like to install?${NC}"
echo "1) MesloLGS NF Regular"
echo "2) MesloLGS NF Bold"
echo "3) MesloLGS NF Italic"
echo "4) MesloLGS NF Bold Italic"
echo "5) All of the above"
read -p "Enter your choice (1-5): " font_choice

fonts_dir="$HOME/.local/share/fonts"
mkdir -p "$fonts_dir"

case $font_choice in
    1) fonts=("MesloLGS NF Regular.ttf"); selected_font="MesloLGS NF Regular";;
    2) fonts=("MesloLGS NF Bold.ttf"); selected_font="MesloLGS NF Bold";;
    3) fonts=("MesloLGS NF Italic.ttf"); selected_font="MesloLGS NF Italic";;
    4) fonts=("MesloLGS NF Bold Italic.ttf"); selected_font="MesloLGS NF Bold Italic";;
    5) fonts=("MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"); selected_font="MesloLGS NF Regular";;
    *) echo -e "${RED}Invalid choice. Installing MesloLGS NF Regular.${NC}"
       fonts=("MesloLGS NF Regular.ttf"); selected_font="MesloLGS NF Regular";;
esac

echo -e "${YELLOW}Installing selected MesloLGS NF font(s)...${NC}"
for font in "${fonts[@]}"; do
    wget -O "$fonts_dir/$font" "https://github.com/romkatv/powerlevel10k-media/raw/master/$font"
done
fc-cache -f -v

# Configure the selected font for the terminal
echo -e "${YELLOW}Configuring the selected font for the terminal...${NC}"
if command -v gnome-terminal &> /dev/null; then
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}')
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/ font "$selected_font 12"
    echo -e "${GREEN}Font configured for GNOME Terminal.${NC}"
elif command -v konsole &> /dev/null; then
    sed -i "s/^Font=.*/Font=$selected_font,12,-1,5,50,0,0,0,0,0/" ~/.config/konsolerc
    echo -e "${GREEN}Font configured for Konsole.${NC}"
elif command -v xfce4-terminal &> /dev/null; then
    sed -i "s/^FontName=.*/FontName=$selected_font 12/" ~/.config/xfce4/terminal/terminalrc
    echo -e "${GREEN}Font configured for XFCE4 Terminal.${NC}"
else
    echo -e "${YELLOW}Couldn't automatically configure the font for your terminal. Please set it manually.${NC}"
fi

# Ask about system update
if ask_yes_no "Do you want to update the system?"; then
    echo -e "${YELLOW}Updating system...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
fi

# Ask about web server installation
echo -e "${YELLOW}Web server installation:${NC}"
if ask_yes_no "Do you want to install Nginx?"; then
    echo -e "${GREEN}Installing Nginx...${NC}"
    install_package nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

if ask_yes_no "Do you want to install Apache?"; then
    echo -e "${GREEN}Installing Apache...${NC}"
    install_package apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
fi

# Function to install SDDM
install_sddm() {
    echo -e "${GREEN}Installing SDDM...${NC}"
    install_package sddm
    sudo systemctl enable sddm
}

# Ask about desktop environment
if ask_yes_no "Do you want to install additional desktop environments?"; then
    echo -e "${YELLOW}Choose additional desktop environments:${NC}"
    echo "1) GNOME"
    echo "2) KDE Plasma"
    echo "3) Xfce"
    echo "4) MATE"
    echo "5) Budgie"
    echo "6) DWM"
    echo "7) None"
    read -p "Enter your choice (1-7): " de_choice

    case $de_choice in
        1)
            echo -e "${GREEN}Installing GNOME...${NC}"
            install_package gnome-core
            install_package gnome-shell gnome-session gdm3
            install_sddm
            ;;
        2)
            echo -e "${GREEN}Installing KDE Plasma...${NC}"
            install_package kde-plasma-desktop
            install_package plasma-desktop sddm kde-config-sddm
            install_sddm
            ;;
        3)
            echo -e "${GREEN}Installing Xfce...${NC}"
            install_package xfce4
            install_package xfce4-goodies lightdm
            install_sddm
            ;;
        4)
            echo -e "${GREEN}Installing MATE...${NC}"
            install_package mate-desktop-environment
            install_package mate-desktop-environment-extras
            install_sddm
            ;;
        5)
            echo -e "${GREEN}Installing Budgie...${NC}"
            install_package budgie-desktop
            install_package budgie-core budgie-indicator-applet budgie-standard-assets
            install_sddm
            ;;
        6)
            echo -e "${GREEN}Installing DWM and its dependencies...${NC}"
            install_package xorg libx11-dev libxft-dev libxinerama-dev build-essential make gcc
            install_package xserver-xorg xinit
            git clone https://git.suckless.org/dwm
            cd dwm
            sudo make clean install
            cd ..
            rm -rf dwm
            echo "exec dwm" > ~/.xinitrc
            install_sddm
            ;;
        7)
            echo -e "${YELLOW}No additional desktop environment will be installed.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. No additional desktop environment installed.${NC}"
            ;;
    esac
fi

echo -e "${GREEN}Post-installation script completed!${NC}"
echo -e "${YELLOW}Please log out and log back in for some changes to take effect.${NC}"
if [ "$de_choice" != "7" ]; then
    echo -e "${YELLOW}SDDM has been installed as the display manager.${NC}"
    echo -e "${YELLOW}You can select your preferred desktop environment at the login screen.${NC}"
fi
if [ "$de_choice" == "6" ]; then
    echo -e "${YELLOW}To use DWM, select it from the SDDM session menu at login.${NC}"
fi
echo -e "${YELLOW}Selected MesloLGS NF font(s) have been installed and configured for your terminal.${NC}"
echo -e "${YELLOW}If the font change doesn't appear, you may need to restart your terminal or configure it manually.${NC}"









