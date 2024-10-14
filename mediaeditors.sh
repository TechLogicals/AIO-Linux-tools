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
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif [ -f /etc/centos-release ]; then
        echo "centos"
    else
        echo "unknown"
    fi
}

# Function to install packages based on the distribution
install_package() {
    local distro=$1
    local package=$2
    
    case $distro in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y $package
            ;;
        fedora)
            sudo dnf install -y $package
            ;;
        centos|rhel)
            sudo yum install -y epel-release
            sudo yum install -y $package
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm $package
            ;;
        opensuse|suse)
            sudo zypper install -y $package
            ;;
        *)
            echo "Unsupported distribution. Please install $package manually."
            ;;
    esac
}

# Function to install Flatpak
install_flatpak() {
    local distro=$1
    
    case $distro in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y flatpak
            ;;
        fedora)
            sudo dnf install -y flatpak
            ;;
        centos|rhel)
            sudo yum install -y flatpak
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm flatpak
            ;;
        opensuse|suse)
            sudo zypper install -y flatpak
            ;;
        *)
            echo "Unsupported distribution. Please install Flatpak manually."
            ;;
    esac
    
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Main script
DISTRO=$(detect_distro)
echo "Media Application Installer by Tech Logicals"
echo "Detected distribution: $DISTRO"

# Install Flatpak
install_flatpak $DISTRO

# List of media applications with their installation methods
declare -A apps
apps=(
    ["kdenlive"]="package"
    ["openshot"]="package"
    ["shotcut"]="package"
    ["flowblade"]="package"
    ["olive"]="build"
    ["pitivi"]="package"
    ["blender"]="package"
    ["natron"]="build"
    ["lightworks"]="manual"
    ["davinci-resolve"]="manual"
    ["obs-studio"]="package"
)

# Install each application
for app in "${!apps[@]}"; do
    echo "Installing $app..."
    case ${apps[$app]} in
        package)
            install_package $DISTRO $app
            ;;
        flatpak)
            flatpak install -y flathub $app
            ;;
        build)
            case $app in
                olive)
                    sudo apt-get update
                    sudo apt-get install -y git cmake build-essential libavformat-dev libavcodec-dev libswscale-dev libavfilter-dev libswresample-dev
                    git clone https://github.com/olive-editor/olive.git
                    cd olive
                    mkdir build && cd build
                    cmake ..
                    make -j$(nproc)
                    sudo make install
                    cd ../..
                    ;;
                natron)
                    # Note: Building Natron from source is complex and may vary based on the system.
                    # This is a simplified version and may not work on all systems.
                    sudo apt-get update
                    sudo apt-get install -y git cmake build-essential libboost-all-dev libgl1-mesa-dev libglu1-mesa-dev
                    git clone https://github.com/NatronGitHub/Natron.git
                    cd Natron
                    mkdir build && cd build
                    cmake ..
                    make -j$(nproc)
                    sudo make install
                    cd ../..
                    ;;
            esac
            ;;
        manual)
            echo "Please visit the official website to download and install $app manually."
            ;;
    esac
done

echo "Installation complete. Some applications might require additional setup."
echo "For Lightworks and DaVinci Resolve, please visit their official websites for installation instructions specific to your distribution."


