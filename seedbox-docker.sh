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
    elif command -v pacman &> /dev/null; then
        # Arch Linux installation
        sudo pacman -Sy
        sudo pacman -S --noconfirm docker
    else
        echo -e "${RED}Unsupported package manager. Please install Docker manually.${NC}"
        exit 1
    fi

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker installed successfully.${NC}"
    echo -e "${YELLOW}Please log out and log back in for group changes to take effect.${NC}"
}

# Function to install Docker Compose
install_docker_compose() {
    echo -e "${BLUE}Installing Docker Compose...${NC}"
    if command -v pacman &> /dev/null; then
        # Arch Linux installation
        sudo pacman -S --noconfirm docker-compose
    else
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
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
    mkdir -p $HOME/media/{movies,tv,downloads,music}
    echo -e "${GREEN}Media directory created successfully.${NC}"
}

# Function to create appdata directory
create_appdata_directory() {
    echo -e "${BLUE}Creating appdata directory...${NC}"
    mkdir -p $HOME/appdata
    echo -e "${GREEN}Appdata directory created successfully.${NC}"
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
    image: diameter/rtorrent-rutorrent
    container_name: rutorrent
    ports:
      - "8080:80"
      - "5000:5000"
      - "51413:51413"
      - "6881:6881/udp"
    volumes:
      - $HOME/appdata/rutorrent:/config
      - $HOME/media:/downloads
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London  # Adjust this to your timezone
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
      - $HOME/appdata/deluge:/config
      - $HOME/media:/downloads
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
      - $HOME/appdata/transmission:/config
      - $HOME/media:/downloads
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
      - $HOME/appdata/radarr:/config
      - $HOME/media:/media
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
      - $HOME/appdata/sonarr:/config
      - $HOME/media:/media
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
      - $HOME/appdata/jackett:/config
      - $HOME/media:/media
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
      - $HOME/appdata/overseerr:/config
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
      - $HOME/appdata/syncthing:/config
      - $HOME/media:/media
    restart: always
EOF
    fi

    if [[ ${selected[8]} -eq 1 ]]; then
        echo -e "${YELLOW}Please enter your Plex claim code (get it from https://www.plex.tv/claim/):${NC}"
        read -r PLEX_CLAIM
        cat << EOF >> docker-compose.yml
  plex:
    image: linuxserver/plex
    container_name: plex
    network_mode: host
    ports:
      - "32400:32400"
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - PLEX_CLAIM=${PLEX_CLAIM}
    volumes:
      - $HOME/appdata/plex:/config
      - $HOME/media:/media
    restart: unless-stopped
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
      - $HOME/appdata/jellyfin:/config
      - $HOME/media:/media
    restart: always
EOF
    fi

    echo -e "${GREEN}docker-compose.yml created successfully.${NC}"
}

# Function to display menu
display_menu() {
    clear
    echo -e "${BLUE}Select the applications you want to install:${NC}"
    for i in "${!options[@]}"; do
        if [[ ${selected[i]} -eq 1 ]]; then
            echo -e "${GREEN}[$((i+1))] [X] ${options[i]}${NC}"
        else
            echo -e "[$((i+1))] [ ] ${options[i]}"
        fi
    done
    echo -e "\n${YELLOW}Enter the number of an option to toggle, or 'q' to finish selection:${NC}"
}

# Function to toggle selection
toggle_selection() {
    local index=$1
    if [[ ${selected[index]} -eq 1 ]]; then
        selected[index]=0
    else
        selected[index]=1
    fi
}

# Function to check if Docker is installed and running
check_docker() {
    if command -v docker &> /dev/null && sudo docker info &> /dev/null; then
        echo -e "${GREEN}Docker is already installed and running.${NC}"
        return 0
    else
        return 1
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose is already installed.${NC}"
        return 0
    else
        return 1
    fi
}

# Function to check if Portainer is running
check_portainer() {
    if sudo docker ps | grep -q portainer; then
        echo -e "${GREEN}Portainer is already running.${NC}"
        return 0
    else
        return 1
    fi
}

# Main menu loop
main_menu() {
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
    )

    # Initialize selected array
    selected=()
    for i in "${!options[@]}"; do
        selected[$i]=0
    done

    # Main menu loop
    while true; do
        display_menu

        read -r choice
        if [[ $choice == "q" ]]; then
            break
        elif [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#options[@]} ]; then
            toggle_selection $((choice-1))
        else
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -n 1 -s -r -p "Press any key to continue..."
        fi
    done
}

# Main script
main_menu

# Check if any option was selected
if [[ ! " ${selected[@]} " =~ 1 ]]; then
    echo -e "${RED}No options were selected. Exiting.${NC}"
    exit 1
fi

# Check and install Docker if necessary
if ! check_docker; then
    install_docker
fi

# Check and install Docker Compose if necessary
if ! check_docker_compose; then
    install_docker_compose
fi

# Check and install Portainer if necessary
if ! check_portainer; then
    install_portainer
fi

create_appdata_directory
create_media_directory
create_docker_compose

echo -e "${BLUE}Starting Docker containers...${NC}"
sudo docker-compose up -d

echo -e "${GREEN}Installation complete! Access Portainer at http://your-ip:9000 to manage your containers.${NC}"
echo -e "${YELLOW}Your media files are stored in $HOME/media${NC}"
echo -e "${YELLOW}Your application data files are stored in $HOME/appdata${NC}"
echo -e "Thanks for using this script by Tech Logicals"
