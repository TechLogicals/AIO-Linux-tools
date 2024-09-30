#!/bin/bash

# ============================================================================
# Streaming and Video Production Software Installation Script by Tech Logicals
# ============================================================================
# This script installs popular streaming and video production software,
# along with prerequisites and drivers, on various Linux distributions.
# It also includes GIMP for image editing.

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ----------------------------------------------------------------------------
# Function to detect the Linux distribution
# ----------------------------------------------------------------------------
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

# ----------------------------------------------------------------------------
# Function to install packages based on the detected distribution
# ----------------------------------------------------------------------------
install_package() {
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt-get update
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

# ----------------------------------------------------------------------------
# Function to install OBS Studio
# subscribe to Tech Logicals https://www.youtube.com/@TechLogicals------------
install_obs_studio() {
    echo -e "${YELLOW}Installing OBS Studio...${NC}"
    case "$DISTRO" in
        ubuntu|debian)
            sudo add-apt-repository ppa:obsproject/obs-studio
            sudo apt-get update
            install_package obs-studio
            ;;
        fedora)
            sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            install_package obs-studio
            ;;
        centos|rhel)
            sudo yum install epel-release
            sudo yum config-manager --set-enabled PowerTools
            sudo yum install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
            sudo yum install https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
            install_package obs-studio
            ;;
        arch)
            install_package obs-studio
            ;;
    esac
}

# ----------------------------------------------------------------------------
# Function to install Streamlabs OBS
# ----------------------------------------------------------------------------
install_streamlabs_obs() {
    echo -e "${YELLOW}Installing Streamlabs OBS...${NC}"
    # Streamlabs OBS is not available in most distro repositories
    # We'll use the AppImage version for cross-distribution compatibility
    wget https://cdn.streamlabs.com/slobs/Streamlabs+OBS-25.0.8-x86_64.AppImage
    chmod +x Streamlabs+OBS-25.0.8-x86_64.AppImage
    sudo mv Streamlabs+OBS-25.0.8-x86_64.AppImage /usr/local/bin/streamlabs-obs
    echo -e "${GREEN}Streamlabs OBS installed. Run it with 'streamlabs-obs' command.${NC}"
}
#subscribe to Tech Logicals https://www.youtube.com/@TechLogicals
# ----------------------------------------------------------------------------
# Function to install FFmpeg
# ----------------------------------------------------------------------------
install_ffmpeg() {
    echo -e "${YELLOW}Installing FFmpeg...${NC}"
    install_package ffmpeg
}

# ----------------------------------------------------------------------------
# Function to install video drivers
# ----------------------------------------------------------------------------
install_video_drivers() {
    echo -e "${YELLOW}Installing video drivers...${NC}"
    case "$DISTRO" in
        ubuntu|debian)
            install_package mesa-utils
            ;;
        fedora|centos|rhel)
            install_package mesa-dri-drivers
            ;;
        arch)
            install_package mesa
            ;;
    esac
}

# ----------------------------------------------------------------------------
# Function to install GIMP
# ----------------------------------------------------------------------------
install_gimp() {
    echo -e "${YELLOW}Installing GIMP...${NC}"
    install_package gimp
}

# ============================================================================
# Main installation process
# ============================================================================
echo -e "${GREEN}Starting installation of streaming and video production software...${NC}"

# Install components
install_video_drivers
install_ffmpeg
install_obs_studio
install_streamlabs_obs
install_gimp
#subscribe to Tech Logicals https://www.youtube.com/@TechLogicals
  
# Install additional useful tools
echo -e "${YELLOW}Installing additional useful tools...${NC}"
install_package v4l-utils  # Video4Linux utilities for webcam configuration
install_package audacity   # Audio editor for post-production
install_package kdenlive   # Video editor for content creation

echo -e "${GREEN}Installation complete!, Thank you for using Tech Logicals tools.${NC}"
echo -e "${YELLOW}Please reboot your system to ensure all changes take effect.${NC}"
echo -e "${YELLOW}Subscribe to Tech Logicals...${NC}"
echo -e "${GREEN}https://www.youtube.com/@TechLogicals${NC}"  

