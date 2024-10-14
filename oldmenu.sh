#!/bin/bash

# Function to display the menu
show_menu() {
    clear
    echo "=== LinuxToolbox ==="
    echo "1. System Update"
    echo "2. Clean System"
    echo "3. Install Common Apps"
    echo "4. Remove Bloatware"
    echo "5. System Info"
    echo "6. Network Tools"
    echo "7. Backup Home Directory"
    echo "8. Restore from Backup"
    echo "9. Install Media Editors"
    echo "10. Install Office Suite"
    echo "11. Install Cinnamon Desktop"
    echo "12. Run Stopwatch"
    echo "13. Exit"
}

# Function to update the system
update_system() {
    echo "Updating system..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt upgrade -y
    elif command -v dnf &> /dev/null; then
        sudo dnf upgrade -y
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm
    else
        echo "Unsupported package manager. Please update manually."
    fi
}

# Function to clean the system
clean_system() {
    echo "Cleaning system..."
    if command -v apt &> /dev/null; then
        sudo apt autoremove -y && sudo apt autoclean
    elif command -v dnf &> /dev/null; then
        sudo dnf autoremove -y && sudo dnf clean all
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sc --noconfirm
    else
        echo "Unsupported package manager. Please clean manually."
    fi
}

# Function to install common apps
install_apps() {
    echo "Installing common apps..."
    if command -v apt &> /dev/null; then
        sudo apt install -y vim git curl wget htop
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y vim git curl wget htop
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm vim git curl wget htop
    else
        echo "Unsupported package manager. Please install apps manually."
    fi
}

# Function to remove bloatware (customize as needed)
remove_bloatware() {
    echo "Removing bloatware..."
    # Add commands to remove unwanted software
    # Example: sudo apt remove package-name -y
}

# Function to display system info
system_info() {
    echo "System Information:"
    echo "-------------------"
    echo "OS: $(uname -o)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ":")"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2 " total, " $3 " used, " $4 " free"}')"
    echo "Disk Usage: $(df -h / | awk '/\// {print $3 " of " $2 " used (" $5 ")"}')"
}

# Function for network tools
network_tools() {
    echo "Network Tools:"
    echo "1. Check IP"
    echo "2. Ping Google"
    echo "3. Show open ports"
    read -p "Choose an option: " net_option
    case $net_option in
        1) curl ifconfig.me ;;
        2) ping -c 4 google.com ;;
        3) sudo netstat -tuln ;;
        *) echo "Invalid option" ;;
    esac
}

# Function to backup home directory
backup_home() {
    echo "Backing up home directory..."
    backup_file="home_backup_$(date +%Y%m%d).tar.gz"
    tar -czf "$backup_file" "$HOME"
    echo "Backup created: $backup_file"
}

# Function to restore from backup
restore_backup() {
    echo "Restoring from backup..."
    read -p "Enter the backup file name: " restore_file
    if [ -f "$restore_file" ]; then
        tar -xzf "$restore_file" -C /
        echo "Restore completed."
    else
        echo "Backup file not found."
    fi
}

# Function to install media editors
install_media_editors() {
    source mediaeditors.sh
}

# Function to install office suite
install_office_suite() {
    source installoffice.sh
}

# Function to install Cinnamon desktop
install_cinnamon_desktop() {
    source cinnamoninstall.sh
}

# Function to run stopwatch
run_stopwatch() {
    source stopwatch.sh
}

# Main loop
while true; do
    show_menu
    read -p "Choose an option: " choice
    case $choice in
        1) update_system ;;
        2) clean_system ;;
        3) install_apps ;;
        4) remove_bloatware ;;
        5) system_info ;;
        6) network_tools ;;
        7) backup_home ;;
        8) restore_backup ;;
        9) install_media_editors ;;
        10) install_office_suite ;;
        11) install_cinnamon_desktop ;;
        12) run_stopwatch ;;
        13) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    read -p "Press enter to continue..."
done

