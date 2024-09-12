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

# Function to ensure Nginx directories exist
ensure_nginx_dirs() {
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
}

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

# After menu selection, before installing anything:
ensure_nginx_dirs

# Prompt for domain name
read -p "Enter your domain name (e.g., example.com): " domain
echo -e "${GREEN}Domain set to: $domain${NC}"

# Install selected options
for i in "${!options[@]}"; do
    if [[ ${selected[i]} -eq 1 ]]; then
        case "${options[i]}" in
            "rTorrent + ruTorrent")
                echo -e "${BLUE}Building rTorrent from source and installing ruTorrent...${NC}"
                
                # Install build dependencies
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update
                    sudo apt-get install -y build-essential automake libtool libcurl4-openssl-dev libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev
                elif command -v dnf &> /dev/null; then
                    sudo dnf groupinstall -y "Development Tools"
                    sudo dnf install -y automake libtool openssl-devel zlib-devel ncurses-devel
                elif command -v yum &> /dev/null; then
                    sudo yum groupinstall -y "Development Tools"
                    sudo yum install -y automake libtool openssl-devel zlib-devel ncurses-devel
                elif command -v pacman &> /dev/null; then
                    sudo pacman -Sy
                    sudo pacman -S --noconfirm base-devel automake libtool openssl zlib ncurses
                else
                    echo -e "${RED}Unable to install build dependencies. Please install them manually.${NC}"
                    continue
                fi

                # Build and install libtorrent
                echo -e "${BLUE}Building libtorrent...${NC}"
                git clone https://github.com/rakshasa/libtorrent.git
                cd libtorrent
                ./autogen.sh
                ./configure
                make -j$(nproc)
                sudo make install
                cd ..
                rm -rf libtorrent

                # Build and install rtorrent
                echo -e "${BLUE}Building rtorrent...${NC}"
                git clone https://github.com/rakshasa/rtorrent.git
                cd rtorrent
                ./autogen.sh
                ./configure --with-xmlrpc-c
                make -j$(nproc)
                sudo make install
                cd ..
                rm -rf rtorrent

                # Update shared library cache
                sudo ldconfig

                # Install PHP and its extensions
                install_package php php-fpm php-cli php-curl php-geoip php-xml php-zip unzip

                # Detect PHP version
                php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
                echo -e "${BLUE}Detected PHP version: $php_version${NC}"

                # Install both generic and version-specific php-fpm
                install_package php-fpm php$php_version-fpm

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
                echo -e "${GREEN}rTorrent built and installed. ruTorrent accessible on port 8080${NC}"
                
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
                echo -e "${BLUE}Installing Deluge...${NC}"
                
                # Function to install Deluge
                install_deluge() {
                    if command -v apt-get &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y deluged deluge-web
                    elif command -v dnf &> /dev/null; then
                        sudo dnf install -y deluge-daemon deluge-web
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y epel-release
                        sudo yum install -y deluge-daemon deluge-web
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -Sy
                        sudo pacman -S --noconfirm deluge
                    else
                        echo -e "${RED}Unable to install Deluge. Please install it manually.${NC}"
                        return 1
                    fi
                }

                # Install Deluge
                if ! install_deluge; then
                    echo -e "${RED}Failed to install Deluge. Skipping...${NC}"
                    continue
                fi

                # Start and enable Deluge services
                sudo systemctl start deluged deluge-web
                sudo systemctl enable deluged deluge-web

                # Setup Nginx config for Deluge
                setup_nginx_config "deluge" "8112"
                echo -e "${GREEN}Deluge installed. Web interface accessible on port 8112${NC}"
                echo -e "${YELLOW}Please use the default credentials to log in.${NC}"
                echo -e "${YELLOW}You can change the password after your first login.${NC}"
                ;;
            "Transmission")
                echo -e "${BLUE}Installing Transmission...${NC}"
                if command -v apt-get &> /dev/null; then
                    sudo apt-get install -y transmission-daemon
                elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    sudo yum install -y transmission-daemon
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S --noconfirm transmission-cli
                else
                    echo -e "${RED}Unable to install Transmission. Please install it manually.${NC}"
                    continue
                fi
                sudo systemctl start transmission-daemon
                sudo systemctl enable transmission-daemon
                setup_nginx_config "transmission" "9091"
                echo -e "${GREEN}Transmission installed. Web interface accessible on port 9091${NC}"
                ;;
            "Radarr")
                echo -e "${BLUE}Installing Radarr...${NC}"
                
                if command -v apt-get &> /dev/null; then
                    # For Debian/Ubuntu systems
                    sudo apt-get install -y curl
                    sudo curl -o /etc/apt/trusted.gpg.d/radarr.asc https://radarr.servarr.com/radarr.asc
                    echo "deb https://radarr.servarr.com/apt/debian bullseye main" | sudo tee /etc/apt/sources.list.d/radarr.list
                    sudo apt-get update
                    sudo apt-get install -y radarr
                elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    # For CentOS/RHEL/Fedora systems
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://radarr.servarr.com/yum/radarr.repo
                    sudo yum install -y radarr
                elif command -v pacman &> /dev/null; then
                    # For Arch Linux
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S radarr --noconfirm
                else
                    echo -e "${RED}Unable to install Radarr. Please install it manually.${NC}"
                    continue
                fi

                sudo systemctl start radarr
                sudo systemctl enable radarr
                setup_nginx_config "radarr" "7878"
                echo -e "${GREEN}Radarr installed. Web interface accessible on port 7878${NC}"
                ;;
            "Sonarr")
                echo -e "${BLUE}Installing Sonarr...${NC}"
                
                if command -v apt-get &> /dev/null; then
                    # For Debian/Ubuntu systems
                    sudo apt-get install -y curl
                    sudo curl -o /etc/apt/trusted.gpg.d/sonarr.asc https://apt.sonarr.tv/sonarr.asc
                    echo "deb https://apt.sonarr.tv/debian bullseye main" | sudo tee /etc/apt/sources.list.d/sonarr.list
                    sudo apt-get update
                    sudo apt-get install -y sonarr
                elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    # For CentOS/RHEL/Fedora systems
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://download.sonarr.tv/yum/sonarr.repo
                    sudo yum install -y sonarr
                elif command -v pacman &> /dev/null; then
                    # For Arch Linux
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S sonarr --noconfirm
                else
                    echo -e "${RED}Unable to install Sonarr. Please install it manually.${NC}"
                    continue
                fi

                sudo systemctl start sonarr
                sudo systemctl enable sonarr
                setup_nginx_config "sonarr" "8989"
                echo -e "${GREEN}Sonarr installed. Web interface accessible on port 8989${NC}"
                ;;
            "Jackett")
                echo -e "${BLUE}Installing Jackett...${NC}"
                if command -v apt-get &> /dev/null; then
                    # For Debian/Ubuntu systems
                    sudo apt-get install -y curl
                    curl -sL https://jackett.servarr.com/install_latest.sh | sudo bash
                elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    # For CentOS/RHEL/Fedora systems
                    sudo yum install -y curl
                    curl -sL https://jackett.servarr.com/install_latest.sh | sudo bash
                elif command -v pacman &> /dev/null; then
                    # For Arch Linux
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S jackett --noconfirm
                else
                    echo -e "${RED}Unable to install Jackett. Please install it manually.${NC}"
                    continue
                fi
                sudo systemctl start jackett
                sudo systemctl enable jackett
                setup_nginx_config "jackett" "9117"
                echo -e "${GREEN}Jackett installed. Web interface accessible on port 9117${NC}"
                ;;
            "Overseerr")
                echo -e "${BLUE}Installing Overseerr...${NC}"
                if command -v apt-get &> /dev/null || command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    # For Debian/Ubuntu and CentOS/RHEL/Fedora systems
                    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
                    sudo apt-get install -y nodejs || sudo yum install -y nodejs
                    sudo npm install -g overseerr
                elif command -v pacman &> /dev/null; then
                    # For Arch Linux
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S overseerr --noconfirm
                else
                    echo -e "${RED}Unable to install Overseerr. Please install it manually.${NC}"
                    continue
                fi
                sudo systemctl start overseerr
                sudo systemctl enable overseerr
                setup_nginx_config "overseerr" "5055"
                echo -e "${GREEN}Overseerr installed. Web interface accessible on port 5055${NC}"
                ;;
            "Syncthing")
                echo -e "${BLUE}Installing Syncthing...${NC}"
                if command -v apt-get &> /dev/null; then
                    # For Debian/Ubuntu systems
                    sudo curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
                    echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
                    sudo apt-get update
                    sudo apt-get install -y syncthing
                elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
                    # For CentOS/RHEL/Fedora systems
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://download.syncthing.net/syncthing-rpm.repo
                    sudo yum install -y syncthing
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S --noconfirm syncthing
                else
                    echo -e "${RED}Unable to install Syncthing. Please install it manually.${NC}"
                    continue
                fi
                sudo systemctl start syncthing@$USER
                sudo systemctl enable syncthing@$USER
                setup_nginx_config "syncthing" "8384"
                echo -e "${GREEN}Syncthing installed. Web interface accessible on port 8384${NC}"
                ;;
            "Plex")
                echo -e "${BLUE}Installing Plex Media Server...${NC}"
                
                # Check if the system uses apt (Debian/Ubuntu)
                if command -v apt-get &> /dev/null; then
                    # Add Plex repository
                    echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
                    curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
                    sudo apt-get update
                    
                    # Install Plex
                    sudo apt-get install -y plexmediaserver
                
                # Check if the system uses yum (CentOS/RHEL)
                elif command -v yum &> /dev/null; then
                    sudo yum install -y https://downloads.plex.tv/plex-media-server-new/1.32.5.7349-8f4248874/redhat/plexmediaserver-1.32.5.7349-8f4248874.x86_64.rpm
                
                # Check if the system uses dnf (Fedora)
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y https://downloads.plex.tv/plex-media-server-new/1.32.5.7349-8f4248874/redhat/plexmediaserver-1.32.5.7349-8f4248874.x86_64.rpm
                
                # Check if the system uses pacman (Arch Linux)
                elif command -v pacman &> /dev/null; then
                    # Enable multilib repository if not already enabled
                    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
                    sudo pacman -Sy

                    # Install Plex from AUR
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S plex-media-server --noconfirm
                
                else
                    echo -e "${RED}Unable to install Plex Media Server. Please install it manually.${NC}"
                    return 1
                fi

                # Start and enable Plex service
                sudo systemctl start plexmediaserver
                sudo systemctl enable plexmediaserver

                # Setup Nginx config for Plex
                setup_nginx_config "plex" "32400"
                echo -e "${GREEN}Plex Media Server installed. Web interface accessible on port 32400${NC}"
                
                read -p "Do you have a Plex claim token? (y/n) " answer
                if [[ $answer =~ ^[Yy]$ ]]; then
                    read -p "Enter your Plex claim token: " claim_token
                    if [ -f "/etc/default/plexmediaserver" ]; then
                        sudo sed -i "s/PLEX_CLAIM=/PLEX_CLAIM=$claim_token/" /etc/default/plexmediaserver
                    else
                        echo "PLEX_CLAIM=$claim_token" | sudo tee -a /etc/default/plexmediaserver
                    fi
                    sudo systemctl restart plexmediaserver
                    echo -e "${GREEN}Plex claim token added. Please complete setup at http://localhost:32400/web${NC}"
                fi
                ;;
            "Jellyfin")
                echo -e "${BLUE}Installing Jellyfin...${NC}"
                
                if command -v apt-get &> /dev/null; then
                    # For Debian/Ubuntu systems
                    sudo apt install -y apt-transport-https
                    wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add -
                    echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list
                    sudo apt update
                    sudo apt install -y jellyfin
                elif command -v dnf &> /dev/null; then
                    # For Fedora systems
                    sudo dnf install -y https://repo.jellyfin.org/releases/server/fedora/jellyfin-fedora.repo
                    sudo dnf install -y jellyfin
                elif command -v yum &> /dev/null; then
                    # For CentOS/RHEL systems
                    sudo yum install -y https://repo.jellyfin.org/releases/server/centos/jellyfin-centos.repo
                    sudo yum install -y jellyfin
                elif command -v pacman &> /dev/null; then
                    # For Arch Linux
                    if ! command -v yay &> /dev/null; then
                        echo -e "${YELLOW}yay AUR helper not found. Installing yay...${NC}"
                        sudo pacman -S --needed git base-devel
                        git clone https://aur.archlinux.org/yay.git
                        cd yay
                        makepkg -si --noconfirm
                        cd ..
                        rm -rf yay
                    fi
                    yay -S jellyfin --noconfirm
                else
                    echo -e "${RED}Unable to install Jellyfin. Please install it manually.${NC}"
                    continue
                fi

                sudo systemctl start jellyfin
                sudo systemctl enable jellyfin
                setup_nginx_config "jellyfin" "8096"
                echo -e "${GREEN}Jellyfin installed. Web interface accessible on port 8096${NC}"
                ;;
            "Install SSL Certificate")
                install_package certbot python3-certbot-nginx
                sudo certbot --nginx -d $domain
                ;;
        esac
    fi
done

# Restart Nginx to apply all changes
sudo systemctl restart nginx

echo -e "${GREEN}Installation complete! You will need to set up authentication on first run for most items${NC}"
echo -e "Thanks for using this script by Tech Logicals"
