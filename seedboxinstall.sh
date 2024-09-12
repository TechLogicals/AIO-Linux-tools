#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to install packages based on distribution
install_package() {
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get install -y "$@"
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y "$@"
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y "$@"
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -S --noconfirm "$@"
    else
        echo "Unsupported package manager. Please install $@ manually."
        exit 1
    fi
}

# Function to display menu
display_menu() {
    echo -e "${BLUE}Select options to install:${NC}"
    for i in "${!options[@]}"; do
        if [[ ${selected[i]} -eq 1 ]]; then
            echo -e "${GREEN}[X] ${options[i]}${NC}"
        else
            echo -e "[ ] ${options[i]}"
        fi
    done
}

# Function to toggle selection
toggle_selection() {
    if [[ ${selected[$1]} -eq 0 ]]; then
        selected[$1]=1
    else
        selected[$1]=0
    fi
}

# Define the list of installation options
options=(
    "rTorrent + ruTorrent"
    "Deluge"
    "Transmission"
    "Radarr"
    "Sonarr"
    "Jackett"
    "Overseerr"
    "Syncthing"
    "Plex"
    "Jellyfin"
    "Install SSL Certificate"
    "Quit"
)

# Initialize the selected array to track user choices
selected=()
for i in "${!options[@]}"; do
    selected[$i]=0
done

# Main menu loop for user interaction
while true; do
    clear
    display_menu

    # Read user input (arrow keys and Enter)
    read -rsn1 key

    case "$key" in
        A) # Up arrow
            ((selected_index > 0)) && ((selected_index--))
            ;;
        B) # Down arrow
            ((selected_index < ${#options[@]}-1)) && ((selected_index++))
            ;;
        '') # Enter key
            if [[ "${options[selected_index]}" == "Quit" ]]; then
                break
            else
                toggle_selection $selected_index
            fi
            ;;
    esac
done

# Install Nginx web server
install_package nginx

# Function to setup Nginx configuration for each application
setup_nginx_config() {
    local app_name=$1
    local port=$2
    
    # Create Nginx configuration file for the application
    cat << EOF | sudo tee /etc/nginx/sites-available/$app_name
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable the Nginx configuration by creating a symbolic link
    sudo ln -s /etc/nginx/sites-available/$app_name /etc/nginx/sites-enabled/
}

# Install selected options
for i in "${!options[@]}"; do
    if [[ ${selected[i]} -eq 1 ]]; then
        case "${options[i]}" in
            "rTorrent + ruTorrent")
                # Install rTorrent and ruTorrent
                install_package rtorrent
                install_package rutorrent
                setup_nginx_config "rutorrent" "8080"
                echo -e "${GREEN}rTorrent + ruTorrent installed. Port: 8080${NC}"
                
                # Optionally set up password protection for ruTorrent
                read -p "Do you want to password protect ruTorrent? (y/n) " answer
                if [[ $answer =~ ^[Yy]$ ]]; then
                    read -p "Enter username for ruTorrent: " rutorrent_user
                    read -s -p "Enter password for ruTorrent: " rutorrent_pass
                    echo
                    echo "$rutorrent_user:$(openssl passwd -apr1 $rutorrent_pass)" | sudo tee /etc/nginx/.htpasswd > /dev/null
                    sudo sed -i '/location \/ {/a\        auth_basic "Restricted";\n        auth_basic_user_file /etc/nginx/.htpasswd;' /etc/nginx/sites-available/rutorrent
                fi
                ;;
            "Deluge")
                install_package deluged deluge-web
                setup_nginx_config "deluge" "8112"
                echo -e "${GREEN}Deluge installed. Port: 8112${NC}"
                
                read -p "Do you want to password protect Deluge? (y/n) " answer
                if [[ $answer =~ ^[Yy]$ ]]; then
                    read -s -p "Enter password for Deluge: " deluge_pass
                    echo
                    echo "deluge:$deluge_pass:10" >> ~/.config/deluge/auth
                fi
                ;;
            "Transmission")
                install_package transmission-daemon
                setup_nginx_config "transmission" "9091"
                echo -e "${GREEN}Transmission installed. Port: 9091${NC}"
                ;;
            "Radarr")
                # Install Radarr (assuming it's available in the package manager)
                install_package radarr
                setup_nginx_config "radarr" "7878"
                echo -e "${GREEN}Radarr installed. Port: 7878${NC}"
                ;;
            "Sonarr")
                # Install Sonarr (assuming it's available in the package manager)
                install_package sonarr
                setup_nginx_config "sonarr" "8989"
                echo -e "${GREEN}Sonarr installed. Port: 8989${NC}"
                ;;
            "Jackett")
                # Install Jackett (assuming it's available in the package manager)
                install_package jackett
                setup_nginx_config "jackett" "9117"
                echo -e "${GREEN}Jackett installed. Port: 9117${NC}"
                ;;
            "Overseerr")
                # Install Overseerr (assuming it's available in the package manager)
                install_package overseerr
                setup_nginx_config "overseerr" "5055"
                echo -e "${GREEN}Overseerr installed. Port: 5055${NC}"
                ;;
            "Syncthing")
                install_package syncthing
                setup_nginx_config "syncthing" "8384"
                echo -e "${GREEN}Syncthing installed. Port: 8384${NC}"
                ;;
            "Plex")
                # Install Plex (assuming it's available in the package manager)
                install_package plexmediaserver
                setup_nginx_config "plex" "32400"
                echo -e "${GREEN}Plex installed. Port: 32400${NC}"
                
                read -p "Do you have a Plex claim code? (y/n) " answer
                if [[ $answer =~ ^[Yy]$ ]]; then
                    read -p "Enter your Plex claim code: " claim_code
                    sudo PLEX_CLAIM="$claim_code" dpkg-reconfigure plexmediaserver
                fi
                ;;
            "Jellyfin")
                # Install Jellyfin (assuming it's available in the package manager)
                install_package jellyfin
                setup_nginx_config "jellyfin" "8096"
                echo -e "${GREEN}Jellyfin installed. Port: 8096${NC}"
                ;;
            "Install SSL Certificate")
                read -p "Enter your domain name: " domain
                install_package certbot python3-certbot-nginx
                sudo certbot --nginx -d $domain
                ;;
        esac
    fi
done

# Restart Nginx to apply changes
sudo systemctl restart nginx

echo -e "${GREEN}Installation complete!, you will need to setup authentication on first run of most items${NC}"
echo -e "Thanks for using this script by Tech Logicals







