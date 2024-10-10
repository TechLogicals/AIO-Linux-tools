#!/bin/bash

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo $DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Function to install office suites and dependencies based on the distribution and user choice
install_office_suite() {
    local distro=$1
    local choice=$2
    case $distro in
        ubuntu|debian)
            sudo apt update
            case $choice in
                1) sudo apt install -y libreoffice libreoffice-gtk3 libreoffice-gnome ;;
                2) sudo apt install -y calligra ;;
                3) sudo apt install -y apache-openoffice ;;
                4) 
                    wget -O wps-office.deb https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/11664/wps-office_11.1.0.11664.XA_amd64.deb
                    sudo dpkg -i wps-office.deb
                    sudo apt install -f -y
                    rm wps-office.deb
                    ;;
            esac
            sudo apt install -y fonts-opensymbol hyphen-*
            ;;
        fedora|centos|rhel)
            case $choice in
                1) sudo dnf install -y libreoffice ;;
                2) sudo dnf install -y calligra ;;
                3) sudo dnf install -y openoffice.org ;;
                4) echo "Please download and install WPS Office manually from the official website." ;;
            esac
            sudo dnf install -y langpacks-en hunspell-* hyphen-*
            ;;
        arch|manjaro)
            case $choice in
                1) sudo pacman -Syu --noconfirm libreoffice-fresh ;;
                2) sudo pacman -Syu --noconfirm calligra ;;
                3) sudo pacman -Syu --noconfirm openoffice-bin ;;
                4) yay -S --noconfirm wps-office ;;
            esac
            sudo pacman -S --noconfirm hunspell hyphen libmythes
            ;;
        opensuse|suse)
            case $choice in
                1) sudo zypper install -y libreoffice ;;
                2) sudo zypper install -y calligra ;;
                3) sudo zypper install -y apache-openoffice ;;
                4) echo "Please download and install WPS Office manually from the official website." ;;
            esac
            sudo zypper install -y hyphen* hunspell*
            ;;
        *)
            echo "Unsupported distribution. Please install office suites manually."
            exit 1
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "Office Suite Installer"
echo "Detected distribution: $DISTRO"

echo "Please choose an office suite to install:"
echo "1) LibreOffice"
echo "2) Calligra"
echo "3) Apache OpenOffice"
echo "4) WPS Office"
read -p "Enter your choice (1-4): " choice

case $choice in
    1) echo "Installing LibreOffice and dependencies..." ;;
    2) echo "Installing Calligra and dependencies..." ;;
    3) echo "Installing Apache OpenOffice and dependencies..." ;;
    4) echo "Installing WPS Office and dependencies..." ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

install_office_suite $DISTRO $choice

echo "Installation complete. You may need to log out and log back in for all changes to take effect."


