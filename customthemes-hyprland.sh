#!/bin/bash
# Script by gjm of Tech Logicals
install_custom_themes() {
    echo "This script will install custom themes for Hyprland from the Hypr-Dots repository."
    read -p "Do you want to proceed? (y/n): " proceed

    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    echo "Cloning Hypr-Dots repository..."
    git clone https://github.com/MrVivekRajan/Hypr-Dots.git
    cd Hypr-Dots

    echo "Available themes:"
    echo "1) Gruvminimal"
    echo "2) Dark-World"
    echo "3) Spring-City"
    echo "4) CuteCat"
    echo "5) Nordic"
    read -p "Choose a theme to install (1-5): " theme_choice

    case $theme_choice in
        1) theme_dir="Gruvminimal" ;;
        2) theme_dir="Dark-World" ;;
        3) theme_dir="Spring-City" ;;
        4) theme_dir="CuteCat" ;;
        5) theme_dir="Nordic" ;;
        *)
            echo "Invalid choice. Installation cancelled."
            cd ..
            rm -rf Hypr-Dots
            exit 1
            ;;
    esac

    echo "Installing $theme_dir theme..."
    mkdir -p ~/.config/hypr
    cp -r "$theme_dir"/* ~/.config/hypr/
    echo "Custom theme installed in ~/.config/hypr/"

    cd ..
    rm -rf Hypr-Dots

    echo "Theme installation complete!"
    echo "Please review and customize your configuration at ~/.config/hypr/hyprland.conf"
}

# Run the function
install_custom_themes