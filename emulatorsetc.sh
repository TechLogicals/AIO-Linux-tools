#!/bin/bash
#by Tech ~Logicals
# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo $DISTRIB_ID
    else
        echo "Unknown"
    fi
}

# Function to install packages based on the distribution
install_package() {
    local distro=$1
    shift
    case $distro in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        fedora)
            sudo dnf install -y "$@"
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm "$@"
            ;;
        opensuse|suse)
            sudo zypper install -y "$@"
            ;;
        *)
            echo "Unsupported distribution. Please install packages manually."
            return 1
            ;;
    esac
}

# Function to install gaming dependencies
install_gaming_dependencies() {
    local distro=$1
    echo "Installing gaming dependencies..."
    case $distro in
        ubuntu|debian|linuxmint)
            sudo apt-get update
            sudo apt-get install -y build-essential libgl1-mesa-dev libglu1-mesa-dev libsdl2-dev libfreetype6-dev libglew-dev libopenal-dev libsndfile1-dev libsfml-dev
            ;;
        fedora)
            sudo dnf install -y @development-tools mesa-libGL-devel mesa-libGLU-devel SDL2-devel freetype-devel glew-devel openal-soft-devel libsndfile-devel SFML-devel
            ;;
        arch|manjaro)
            sudo pacman -Syu --noconfirm base-devel mesa glu sdl2 freetype2 glew openal libsndfile sfml
            ;;
        opensuse|suse)
            sudo zypper install -y -t pattern devel_basis
            sudo zypper install -y Mesa-libGL-devel Mesa-libGLU-devel libSDL2-devel freetype-devel libglew-devel openal-soft-devel libsndfile-devel libSFML-devel
            ;;
        *)
            echo "Unsupported distribution. Please install gaming dependencies manually."
            ;;
    esac
}

# Function to install selected emulators and gaming tools
install_gaming_tools() {
    local distro=$1
    shift
    local selected_tools=("$@")
    
    for tool in "${selected_tools[@]}"; do
        echo "Installing $tool..."
        case $tool in
            retroarch)
                install_package $distro retroarch libretro-*
                ;;
            dolphin)
                install_package $distro dolphin-emu
                ;;
            pcsx2)
                install_package $distro pcsx2
                ;;
            ppsspp)
                install_package $distro ppsspp
                ;;
            mupen64plus)
                install_package $distro mupen64plus
                ;;
            mame)
                install_package $distro mame
                ;;
            dosbox)
                install_package $distro dosbox
                ;;
            cemu)
                echo "CEMU is not available in official repositories. Please install manually from https://cemu.info/"
                ;;
            rpcs3)
                echo "RPCS3 is not available in official repositories. Please install manually from https://rpcs3.net/"
                ;;
            lutris)
                case $distro in
                    ubuntu|debian|linuxmint)
                        sudo add-apt-repository ppa:lutris-team/lutris
                        sudo apt-get update
                        sudo apt-get install -y lutris
                        ;;
                    fedora)
                        sudo dnf install -y lutris
                        ;;
                    arch|manjaro)
                        sudo pacman -Syu --noconfirm lutris
                        ;;
                    opensuse|suse)
                        sudo zypper install -y lutris
                        ;;
                    *)
                        echo "Please install Lutris manually from https://lutris.net/"
                        ;;
                esac
                ;;
            wine)
                case $distro in
                    ubuntu|debian|linuxmint)
                        sudo dpkg --add-architecture i386
                        wget -nc https://dl.winehq.org/wine-builds/winehq.key
                        sudo apt-key add winehq.key
                        sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'
                        sudo apt-get update
                        sudo apt-get install -y --install-recommends winehq-stable
                        ;;
                    fedora)
                        sudo dnf install -y wine
                        ;;
                    arch|manjaro)
                        sudo pacman -Syu --noconfirm wine
                        ;;
                    opensuse|suse)
                        sudo zypper install -y wine
                        ;;
                    *)
                        echo "Please install Wine manually from https://www.winehq.org/"
                        ;;
                esac
                ;;
            proton)
                echo "Proton is typically managed through Steam. Please install Steam and enable Proton in Steam Play settings."
                ;;
            *)
                echo "Unknown tool: $tool"
                ;;
        esac
    done
}

# Function to install frontend
install_frontend() {
    local distro=$1
    echo "Installing EmulationStation frontend..."
    case $distro in
        ubuntu|debian|linuxmint)
            sudo add-apt-repository ppa:emulationstation/ppa
            sudo apt-get update
            sudo apt-get install -y emulationstation
            ;;
        fedora)
            sudo dnf copr enable -y emulationstation/emulationstation
            sudo dnf install -y emulationstation
            ;;
        arch|manjaro)
            yay -S --noconfirm emulationstation
            ;;
        opensuse|suse)
            echo "EmulationStation is not available in official repositories. Please install manually."
            ;;
        *)
            echo "Unsupported distribution. Please install EmulationStation manually."
            ;;
    esac
}

# Main script
DISTRO=$(detect_distro)
echo "Game Emulator, Gaming Tools, and Frontend Installer by Tech Logicals"
echo "Detected distribution: $DISTRO"

# Install gaming dependencies
install_gaming_dependencies $DISTRO

# List of available emulators and gaming tools
gaming_tools=("retroarch" "dolphin" "pcsx2" "ppsspp" "mupen64plus" "mame" "dosbox" "cemu" "rpcs3" "lutris" "wine" "proton")

# Ask user which tools to install
selected_tools=()
echo "Please select which emulators and gaming tools you want to install:"
for i in "${!gaming_tools[@]}"; do
    read -p "Install ${gaming_tools[$i]}? (y/n): " choice
    case "$choice" in
        y|Y) selected_tools+=("${gaming_tools[$i]}") ;;
        *) ;;
    esac
done

# Install selected tools
if [ ${#selected_tools[@]} -gt 0 ]; then
    echo "Installing selected emulators and gaming tools..."
    install_gaming_tools $DISTRO "${selected_tools[@]}"
else
    echo "No emulators or gaming tools selected for installation."
fi

# Ask if user wants to install frontend
read -p "Do you want to install EmulationStation frontend? (y/n): " install_frontend_choice
case "$install_frontend_choice" in
    y|Y)
        echo "Installing frontend..."
        install_frontend $DISTRO
        ;;
    *)
        echo "Skipping frontend installation."
        ;;
esac

echo "Installation complete. You may need to configure EmulationStation and add ROMs to appropriate directories."
echo "Please ensure you have the legal rights to any ROMs you use with these emulators."
echo "For Lutris, Wine, and Proton, additional configuration may be required for optimal performance."
echo "Gaming dependencies have been installed to support various games and emulators."



