#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to install Docker
install_docker() {
    echo -e "${BLUE}Installing Docker...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif command -v yum &> /dev/null; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    elif command -v dnf &> /dev/null; then
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
    else
        echo -e "${RED}Unsupported package manager. Please install Docker manually.${NC}"
        exit 1
    fi

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker installed successfully.${NC}"
}

# Function to install Docker Compose
install_docker_compose() {
    echo -e "${BLUE}Installing Docker Compose...${NC}"
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully.${NC}"
}

# Function to install Portainer
install_portainer() {
    echo -e "${BLUE}Installing Portainer...${NC}"
    sudo docker volume create portainer_data
    sudo docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    echo -e "${GREEN}Portainer installed successfully. Access it at http://your-ip:9000${NC}"
}

# Function to create media directory
create_media_directory() {
    echo -e "${BLUE}Creating media directory...${NC}"
    sudo mkdir -p /opt/seedbox/media/{movies,tv,downloads,music}
    sudo chown -R $USER:$USER /opt/seedbox/media
    echo -e "${GREEN}Media directory created successfully.${NC}"
}

# Function to create docker-compose.yml
create_docker_compose() {
    echo -e "${BLUE}Creating docker-compose.yml...${NC}"
    cat << EOF > docker-compose.yml
version: '3'
services:
EOF

    if [[ ${selected[0]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  rutorrent:
    image: crazymax/rtorrent-rutorrent
    container_name: rutorrent
    ports:
      - "8080:8080"
    volumes:
      - ./rutorrent-data:/data
      - /opt/seedbox/media/downloads:/downloads
    restart: always
EOF
    fi

    if [[ ${selected[1]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  deluge:
    image: linuxserver/deluge
    container_name: deluge
    ports:
      - "8112:8112"
    volumes:
      - ./deluge-data:/config
      - /opt/seedbox/media/downloads:/downloads
    restart: always
EOF
    fi

    if [[ ${selected[2]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  transmission:
    image: linuxserver/transmission
    container_name: transmission
    ports:
      - "9091:9091"
    volumes:
      - ./transmission-data:/config
      - /opt/seedbox/media/downloads:/downloads
    restart: always
EOF
    fi

    if [[ ${selected[3]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  radarr:
    image: linuxserver/radarr
    container_name: radarr
    ports:
      - "7878:7878"
    volumes:
      - ./radarr-data:/config
      - /opt/seedbox/media/downloads:/downloads
      - /opt/seedbox/media/movies:/movies
    restart: always
EOF
    fi

    if [[ ${selected[4]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    ports:
      - "8989:8989"
    volumes:
      - ./sonarr-data:/config
      - /opt/seedbox/media/downloads:/downloads
      - /opt/seedbox/media/tv:/tv
    restart: always
EOF
    fi

    if [[ ${selected[5]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  jackett:
    image: linuxserver/jackett
    container_name: jackett
    ports:
      - "9117:9117"
    volumes:
      - ./jackett-data:/config
      - /opt/seedbox/media/downloads:/downloads
    restart: always
EOF
    fi

    if [[ ${selected[6]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  overseerr:
    image: linuxserver/overseerr
    container_name: overseerr
    ports:
      - "5055:5055"
    volumes:
      - ./overseerr-data:/config
    restart: always
EOF
    fi

    if [[ ${selected[7]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  syncthing:
    image: linuxserver/syncthing
    container_name: syncthing
    ports:
      - "8384:8384"
      - "22000:22000"
      - "21027:21027/udp"
    volumes:
      - ./syncthing-data:/config
      - /opt/seedbox/media:/data
    restart: always
EOF
    fi

    if [[ ${selected[8]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  plex:
    image: linuxserver/plex
    container_name: plex
    ports:
      - "32400:32400"
    volumes:
      - ./plex-data:/config
      - /opt/seedbox/media/movies:/movies
      - /opt/seedbox/media/tv:/tv
      - /opt/seedbox/media/music:/music
    restart: always
EOF
    fi

    if [[ ${selected[9]} -eq 1 ]]; then
        cat << EOF >> docker-compose.yml
  jellyfin:
    image: linuxserver/jellyfin
    container_name: jellyfin
    ports:
      - "8096:8096"
    volumes:
      - ./jellyfin-data:/config
      - /opt/seedbox/media/movies:/movies
      - /opt/seedbox/media/tv:/tv
      - /opt/seedbox/media/music:/music
    restart: always
EOF
    fi

    echo -e "${GREEN}docker-compose.yml created successfully.${NC}"
}

# Main script
install_docker
install_docker_compose
install_portainer
create_media_directory
create_docker_compose

echo -e "${BLUE}Starting Docker containers...${NC}"
docker-compose up -d

echo -e "${GREEN}Installation complete! Access Portainer at http://your-ip:9000 to manage your containers.${NC}"
echo -e "${YELLOW}Your media files are stored in /opt/seedbox/media${NC}"
echo -e "Thanks for using this script by Tech Logicals"
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
