#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
HIGHLIGHT='\033[7m' # Highlight (reverse video)

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
        if [[ $i -eq $selected_index ]]; then
            if [[ ${selected[i]} -eq 1 ]]; then
                echo -e "${HIGHLIGHT}${GREEN}[X] ${options[i]}${NC}"
            else
                echo -e "${HIGHLIGHT}[ ] ${options[i]}${NC}"
            fi
        else
            if [[ ${selected[i]} -eq 1 ]]; then
                echo -e "${GREEN}[X] ${options[i]}${NC}"
            else
                echo -e "[ ] ${options[i]}"
            fi
        fi
    done
    echo -e "\nUse arrow keys to navigate, Enter to select/deselect, and Q to quit."
}

# Function to toggle selection
toggle_selection() {
    if [[ ${selected[$1]} -eq 0 ]]; then
        selected[$1]=1
    else
        selected[$1]=0
    fi
}

# Define options
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

# Initialize selected array and selected_index
selected=()
for i in "${!options[@]}"; do
    selected[$i]=0
done
selected_index=0

# Main menu loop
while true; do
    clear
    display_menu

    # Read user input
    read -rsn1 key

    case "$key" in
        A) # Up arrow
            ((selected_index > 0)) && ((selected_index--)) || selected_index=$((${#options[@]}-1))
            ;;
        B) # Down arrow
            ((selected_index < ${#options[@]}-1)) && ((selected_index++)) || selected_index=0
            ;;
        '') # Enter key
            if [[ "${options[selected_index]}" == "Quit" ]]; then
                break
            else
                toggle_selection $selected_index
            fi
            ;;
        q|Q) # Quit
            break
            ;;
    esac
done

# Function to ensure www-data user exists
ensure_www_data_user() {
    if ! id "www-data" &>/dev/null; then
        echo -e "${BLUE}Creating www-data user...${NC}"
        sudo useradd -r -s /usr/sbin/nologin www-data
        echo -e "${GREEN}www-data user created.${NC}"
    else
        echo -e "${GREEN}www-data user already exists.${NC}"
    fi
}

ensure_www_data_user

# Install Nginx, wget, and unzip
echo -e "${BLUE}Installing Nginx, wget, and unzip...${NC}"
install_package nginx wget unzip

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check and create Nginx configuration directories if they don't exist
if [ ! -d "/etc/nginx/sites-available" ]; then
    sudo mkdir -p /etc/nginx/sites-available
    echo -e "${BLUE}Created /etc/nginx/sites-available directory${NC}"
fi

if [ ! -d "/etc/nginx/sites-enabled" ]; then
    sudo mkdir -p /etc/nginx/sites-enabled
    echo -e "${BLUE}Created /etc/nginx/sites-enabled directory${NC}"
fi

# Check if the main Nginx configuration includes our sites-enabled directory
if ! grep -q "include /etc/nginx/sites-enabled/\*" /etc/nginx/nginx.conf; then
    sudo sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    echo -e "${BLUE}Updated Nginx configuration to include sites-enabled directory${NC}"
fi

# Function to setup Nginx config
setup_nginx_config() {
    local app_name=$1
    local port=$2
    
    # Check if domain variable is set, if not, use a placeholder
    if [ -z "$domain" ]; then
        domain="your_domain.com"
        echo -e "${YELLOW}Warning: Domain not set. Using placeholder: $domain${NC}"
    fi
    
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

    # Create symlink only if it doesn't already exist
    if [ ! -f "/etc/nginx/sites-enabled/$app_name" ]; then
        if [ -f "/etc/nginx/sites-available/$app_name" ]; then
            sudo ln -s /etc/nginx/sites-available/$app_name /etc/nginx/sites-enabled/
            echo -e "${GREEN}Nginx configuration for $app_name enabled.${NC}"
        else
            echo -e "${RED}Error: Nginx configuration file for $app_name not found in sites-available.${NC}"
        fi
    else
        echo -e "${YELLOW}Nginx configuration for $app_name already enabled.${NC}"
    fi
}

# Prompt for domain name
read -p "Enter your domain name (e.g., example.com): " domain
echo -e "${GREEN}Domain set to: $domain${NC}"

# Install selected options
for i in "${!options[@]}"; do
    if [[ ${selected[i]} -eq 1 ]]; then
        case "${options[i]}" in
            "rTorrent + ruTorrent")
                # Install rTorrent
                install_package rtorrent
                
                # Install PHP and its extensions
                install_package php php-fpm php-cli php-curl php-geoip php-xml php-zip unzip

                # Detect PHP version
                php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
                echo -e "${BLUE}Detected PHP version: $php_version${NC}"

                # Try to install version-specific php-fpm, fall back to generic if not available
                if ! install_package php$php_version-fpm; then
                    echo -e "${YELLOW}Specific PHP-FPM version not found. Using generic PHP-FPM.${NC}"
                fi

                # Download and install ruTorrent
                echo -e "${BLUE}Installing ruTorrent...${NC}"
                sudo mkdir -p /var/www/rutorrent
                sudo wget https://github.com/Novik/ruTorrent/archive/master.zip -O /tmp/rutorrent.zip
                sudo unzip /tmp/rutorrent.zip -d /tmp
                sudo cp -r /tmp/ruTorrent-master/* /var/www/rutorrent/
                sudo rm -rf /tmp/ruTorrent-master /tmp/rutorrent.zip
                sudo chown -R www-data:www-data /var/www/rutorrent

                # Configure Nginx for ruTorrent
                cat << EOF | sudo tee /etc/nginx/sites-available/rutorrent
server {
    listen 8080;
    root /var/www/rutorrent;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
EOF

                # Ensure php-fpm service is enabled and started
                if systemctl list-unit-files | grep -q php$php_version-fpm; then
                    sudo systemctl enable php$php_version-fpm
                    sudo systemctl start php$php_version-fpm
                    sudo systemctl restart php$php_version-fpm
                else
                    sudo systemctl enable php-fpm
                    sudo systemctl start php-fpm
                    sudo systemctl restart php-fpm
                fi

                setup_nginx_config "rutorrent_proxy" "8080"
                echo -e "${GREEN}rTorrent + ruTorrent installed. ruTorrent accessible on port 8080${NC}"
                
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
                install_package certbot python3-certbot-nginx
                sudo certbot --nginx -d $domain
                ;;
        esac
    fi
done

# Create symlinks for all installed applications
for app in /etc/nginx/sites-available/*; do
    app_name=$(basename "$app")
    if [ ! -f "/etc/nginx/sites-enabled/$app_name" ]; then
        sudo ln -s "$app" "/etc/nginx/sites-enabled/"
    fi
done

# Restart Nginx to apply all changes
sudo systemctl restart nginx

echo -e "${GREEN}Installation complete! You will need to set up authentication on first run for most items${NC}"
echo -e "Thanks for using this script by Tech Logicals"
