#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display menu and get selections
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    # Debug output
    echo -e "${CYAN}Debug: Entering display_menu function${NC}" >&2
    echo -e "${CYAN}Debug: Title: $title${NC}" >&2
    echo -e "${CYAN}Debug: Number of options: ${#options[@]}${NC}" >&2
    echo -e "${CYAN}Debug: Options: ${options[*]}${NC}" >&2
    
    # Display menu title and options
    echo -e "${YELLOW}$title${NC}" >&2
    echo -e "${YELLOW}------------------------${NC}" >&2
    for i in "${!options[@]}"; do
        echo -e "${GREEN}$((i+1)). ${options[$i]}${NC}" >&2
    done
    echo -e "${YELLOW}------------------------${NC}" >&2
    echo -e "${MAGENTA}Enter the numbers of your choices separated by spaces, then press Enter:${NC}" >&2
    read -r choices
    
    echo -e "${CYAN}Debug: User input: $choices${NC}" >&2
    
    # Process user selections
    local selected=()
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected+=("${options[$((choice-1))]}")
        fi
    done
    
    echo -e "${CYAN}Debug: Selected options: ${selected[*]}${NC}" >&2
    printf '%s\n' "${selected[@]}"
}

# Function to create Docker network
create_docker_network() {
    local network_name="media_network"
    # Check if network already exists
    if ! docker network inspect $network_name >/dev/null 2>&1; then
        echo -e "${GREEN}Creating Docker network: $network_name${NC}"
        docker network create $network_name
    else
        echo -e "${YELLOW}Docker network $network_name already exists${NC}"
    fi
}

# Function to create Docker Compose file
create_docker_compose() {
    local name=$1
    local port=$2
    local config_dir="$appdata_dir/$name"
    mkdir -p "$config_dir"
    
    echo -e "${CYAN}Debug: Creating Docker Compose file for $name${NC}"
    
    # Generate Docker Compose file based on application type
    case $name in
        plex)
            # Plex requires a claim code for initial setup
            read -p "Enter your Plex claim code (https://www.plex.tv/claim): " plex_claim
            cat > "$config_dir/docker-compose.yml" <<EOL
# ... Plex Docker Compose configuration ...
EOL
            ;;
        emby|jellyfin)
            cat > "$config_dir/docker-compose.yml" <<EOL
# ... Emby/Jellyfin Docker Compose configuration ...
EOL
            ;;
        sonarr|radarr|lidarr|jackett|ombi|overseerr)
            cat > "$config_dir/docker-compose.yml" <<EOL
# ... Sonarr/Radarr/Lidarr/Jackett/Ombi/Overseerr Docker Compose configuration ...
EOL
            ;;
        transmission|deluge|qbittorrent)
            cat > "$config_dir/docker-compose.yml" <<EOL
# ... Transmission/Deluge/qBittorrent Docker Compose configuration ...
EOL
            ;;
        rtorrent-rutorrent)
            cat > "$config_dir/docker-compose.yml" <<EOL
# ... rTorrent-ruTorrent Docker Compose configuration ...
EOL
            ;;
        flood)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: jesec/flood
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir/downloads:/downloads
    ports:
      - $port:3000
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        prowlarr)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/prowlarr:develop
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
    ports:
      - $port:9696
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        bazarr)
            cat > "$config_dir/docker-compose.yml" <<EOL
version: '3'
services:
  $name:
    image: linuxserver/bazarr
    container_name: $name
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $config_dir:/config
      - $shared_media_dir:/data
    ports:
      - $port:6767
    restart: unless-stopped
    networks:
      - media_network

networks:
  media_network:
    external: true
EOL
            ;;
        *)
            echo -e "${RED}Unknown application: $name${NC}"
            return 1
            ;;
    esac

    echo -e "${GREEN}Created Docker Compose file for $name${NC}"
}

# Main script starts here
echo -e "${BLUE}Debug: Script started${NC}"

# Get shared media directory from user input
read -p "Enter the path for the shared media directory: " shared_media_dir
echo -e "${CYAN}Debug: Shared media directory: $shared_media_dir${NC}"

# Create appdata directory in user's home folder
appdata_dir="$HOME/appdata"
echo -e "${CYAN}Debug: Appdata directory: $appdata_dir${NC}"

# Select media applications
echo -e "${YELLOW}Selecting media applications...${NC}"
media_names=(plex emby jellyfin sonarr radarr lidarr jackett ombi overseerr prowlarr bazarr)
echo -e "${CYAN}Debug: Media names: ${media_names[*]}${NC}"
mapfile -t selected_media < <(display_menu "Select Media Applications" "${media_names[@]}")

echo -e "${CYAN}Debug: Selected media applications:${NC}"
printf '%s\n' "${selected_media[@]}"

# Select torrent downloaders
echo -e "${YELLOW}Selecting torrent downloaders...${NC}"
downloader_names=(transmission deluge qbittorrent rtorrent-rutorrent flood)
echo -e "${CYAN}Debug: Downloader names: ${downloader_names[*]}${NC}"
mapfile -t selected_downloaders < <(display_menu "Select Torrent Downloaders" "${downloader_names[@]}")

echo -e "${CYAN}Debug: Selected torrent downloaders:${NC}"
printf '%s\n' "${selected_downloaders[@]}"

# Create Docker network
create_docker_network

# Create Docker Compose files and start containers
echo -e "${YELLOW}Creating Docker Compose files and starting containers...${NC}"
for app in "${selected_media[@]}" "${selected_downloaders[@]}"; do
    # Assign default ports for each application
    case $app in
        plex) port=32400 ;;
        emby|jellyfin) port=8096 ;;
        sonarr) port=8989 ;;
        radarr) port=7878 ;;
        lidarr) port=8686 ;;
        jackett) port=9117 ;;
        ombi) port=3579 ;;
        overseerr) port=5055 ;;
        transmission) port=9091 ;;
        deluge) port=8112 ;;
        qbittorrent) port=8080 ;;
        rtorrent-rutorrent) port=80 ;;
        flood) port=3000 ;;
        prowlarr) port=9696 ;;
        bazarr) port=6767 ;;
        *) echo -e "${RED}Unknown application: $app${NC}"; continue ;;
    esac
    
    # Create Docker Compose file for the application
    create_docker_compose "$app" "$port"
    # Start the container using docker-compose
    (cd "$appdata_dir/$app" && docker-compose up -d)
done

echo -e "${GREEN}All selected containers have been configured and started.${NC}"
echo -e "${YELLOW}Please check individual container logs for any issues.${NC}"
echo -e "${BLUE}Debug: Script ended${NC}"