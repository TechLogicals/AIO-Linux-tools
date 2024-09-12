#!/bin/bash
#Created by gjm of Tech Logicals
# Function to detect the package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install packages based on the detected package manager
install_packages() {
    local package_manager=$1
    shift
    local packages=("$@")

    case $package_manager in
        apt)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
        *)
            echo "Unsupported package manager. Please install the required packages manually."
            exit 1
            ;;
    esac
}

# Detect the package manager
package_manager=$(detect_package_manager)
echo "Detected package manager: $package_manager"

# Install dependencies
echo "Installing dependencies..."
dependencies=(
    git meson ninja gcc cmake libxcb-dev libx11-dev libwayland-dev libxkbcommon-dev
    libcairo2-dev libpango1.0-dev libgdk-pixbuf2.0-dev libseat-dev libxcb-composite0-dev
    libevdev-dev libudev-dev libinput-dev libdbus-1-dev libsystemd-dev libpcre2-dev
    libxcb-present-dev libxcb-xfixes0-dev libxcb-render0-dev libxcb-randr0-dev
    libxcb-util-dev libxcb-res0-dev libxcb-icccm4-dev libxcb-ewmh-dev
)
install_packages "$package_manager" "${dependencies[@]}"

# Clone and build Hyprland
echo "Cloning and building Hyprland..."
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
meson build
ninja -C build
sudo ninja -C build install

# Install additional utilities
echo "Installing additional utilities..."
utilities=(
    kitty wofi waybar swaylock grim slurp wl-clipboard
)
install_packages "$package_manager" "${utilities[@]}"

# Function to install and configure display manager
install_display_manager() {
    echo "Which display manager would you like to use?"
    echo "1) LightDM"
    echo "2) SDDM"
    echo "3) GDM"
    echo "4) None (No display manager)"
    read -p "Enter your choice (1-4): " dm_choice

    case $dm_choice in
        1)
            dm_package="lightdm"
            ;;
        2)
            dm_package="sddm"
            ;;
        3)
            dm_package="gdm"
            ;;
        4)
            echo "No display manager will be installed."
            return
            ;;
        *)
            echo "Invalid choice. No display manager will be installed."
            return
            ;;
    esac

    echo "Installing $dm_package..."
    install_packages "$package_manager" "$dm_package"

    # Enable and start the display manager
    sudo systemctl enable "$dm_package"
    sudo systemctl start "$dm_package"

    # Configure the display manager to use Hyprland
    if [ "$dm_package" = "lightdm" ]; then
        sudo mkdir -p /usr/share/xsessions
        echo "[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application" | sudo tee /usr/share/xsessions/hyprland.desktop
    elif [ "$dm_package" = "sddm" ] || [ "$dm_package" = "gdm" ]; then
        echo "[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application" | sudo tee /usr/share/wayland-sessions/hyprland.desktop
    fi

    echo "$dm_package has been installed and configured to use Hyprland."
}

# Install and configure display manager
install_display_manager

# Function to install and configure Hyprland theme switcher
install_theme_switcher() {
    echo "Installing Hyprland theme switcher..."
    git clone https://github.com/hyprland-community/hyprtheme.git
    cd hyprtheme
    sudo make install
    
    # Configure theme switcher
    mkdir -p ~/.config/hypr
    echo "plugin = /usr/lib/libhy3.so" >> ~/.config/hypr/hyprland.conf
    echo "exec-once = hyprtheme" >> ~/.config/hypr/hyprland.conf
}

# Function to install popular Hyprland themes
install_popular_themes() {
    echo "Installing popular Hyprland themes..."
    mkdir -p ~/.config/hypr/themes
    
    # Clone and install some popular themes (you can add more)
    git clone https://github.com/hyprland-community/theme-repo.git
    cp -r theme-repo/themes/* ~/.config/hypr/themes/
    rm -rf theme-repo
    
    echo "Popular themes have been installed in ~/.config/hypr/themes"
}

# Ask user if they want to install themes
read -p "Do you want to install popular Hyprland themes and theme switcher? (y/n): " install_themes

if [[ $install_themes =~ ^[Yy]$ ]]; then
    install_theme_switcher
    install_popular_themes
    echo "Hyprland theme switcher and popular themes have been installed and configured."
else
    echo "Skipping theme installation."
fi

echo "Hyprland, utilities, and selected components have been installed successfully!"
if [ "$dm_choice" != "4" ]; then
    echo "You can now restart your system and select Hyprland from the login screen."
else
    echo "To start Hyprland, run 'Hyprland' from the command line."
fi

if [[ $install_themes =~ ^[Yy]$ ]]; then
    echo "To switch themes, use the 'hyprtheme' command."
fi






