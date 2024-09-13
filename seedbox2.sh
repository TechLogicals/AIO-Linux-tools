#!/bin/bash

# Function to install and configure Nextcloud



# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        DISTRO=debian
    else
        DISTRO=$(uname -s)
    fi

    DISTRO=$(echo $DISTRO | tr '[:upper:]' '[:lower:]')
}

# Function to install packages based on the distribution
install_package() {
    package_name=$1
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y $package_name
            ;;
        fedora|centos|rhel)
            sudo dnf install -y $package_name
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm $package_name
            ;;
        *)
            echo -e "${RED}Unsupported distribution. Please install $package_name manually.${NC}"
            return 1
            ;;
    esac
}

# Function to install and configure MariaDB
install_mariadb() {
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}Installing MariaDB...${NC}"
        install_package mariadb-server
        sudo systemctl start mariadb
        sudo systemctl enable mariadb
        echo -e "${GREEN}MariaDB installed and started.${NC}"
    else
        echo -e "${GREEN}MariaDB is already installed.${NC}"
    fi
}

# Function to create a database and user
create_database() {
    db_name=$1
    db_user=$2
    db_pass=$(openssl rand -base64 12)

    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    echo -e "${YELLOW}Database information:${NC}"
    echo -e "${BLUE}Database Name: $db_name${NC}"
    echo -e "${BLUE}Database User: $db_user${NC}"
    echo -e "${BLUE}Database Password: $db_pass${NC}"
}

# Function to install and configure an application
install_and_configure_app() {
    app_name=$1
    install_command=$2
    config_command=$3
    db_required=$4

    echo -e "${YELLOW}Installing $app_name...${NC}"
    eval $install_command
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$app_name installed successfully.${NC}"
        echo -e "${YELLOW}Configuring $app_name...${NC}"
        eval $config_command
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$app_name configured successfully.${NC}"
            if [ "$db_required" = true ]; then
                install_mariadb
                create_database "${app_name,,}_db" "${app_name,,}_user"
            fi
        else
            echo -e "${RED}Failed to configure $app_name.${NC}"
        fi
    else
        echo -e "${RED}Failed to install $app_name.${NC}"
    fi
}

# Function to install and configure web server
install_web_server() {
    echo -e "${YELLOW}Which web server would you like to install?${NC}"
    echo "1) Nginx"
    echo "2) Apache"
    read -p "Enter your choice (1-2): " web_server_choice

    case $web_server_choice in
        1)
            install_and_configure_app "Nginx" "install_package nginx" "sudo systemctl start nginx && sudo systemctl enable nginx" false
            ;;
        2)
            case $DISTRO in
                ubuntu|debian)
                    install_and_configure_app "Apache" "install_package apache2" "sudo systemctl start apache2 && sudo systemctl enable apache2" false
                    ;;
                fedora|centos|rhel|arch|manjaro)
                    install_and_configure_app "Apache" "install_package httpd" "sudo systemctl start httpd && sudo systemctl enable httpd" false
                    ;;
                *)
                    echo -e "${RED}Unsupported distribution for Apache installation.${NC}"
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}Invalid choice. Defaulting to Nginx.${NC}"
            install_and_configure_app "Nginx" "install_package nginx" "sudo systemctl start nginx && sudo systemctl enable nginx" false
            ;;
    esac
}

# Function to display cool menu and get user choice
show_menu() {
    # Install dialog if not already installed
    if ! command -v dialog &> /dev/null; then
        echo "Installing dialog package..."
        install_package dialog
    fi

    # Create temporary file for dialog output
    tempfile=$(mktemp)

    # Display menu using dialog
    dialog --clear --title "Seedbox Application Installation Menu" \
           --menu "Choose applications to install (use arrow keys and space to select, Enter to confirm):" 22 60 19 \
           "rTorrent with ruTorrent" "" off \
           "Deluge" "" off \
           "Transmission" "" off \
           "qBittorrent" "" off \
           "Sonarr" "" off \
           "Radarr" "" off \
           "Lidarr" "" off \
           "Jackett" "" off \
           "Plex Media Server" "" off \
           "Emby" "" off \
           "Jellyfin" "" off \
           "FileZilla" "" off \
           "OpenVPN" "" off \
           "Nextcloud" "" off \
           "Syncthing" "" off \
           "Overseerr" "" off \
           "Tautulli" "" off \
           "Install Selected" "" on \
           "Quit" "" off 2> $tempfile

    # Get user's choices
    choices=$(cat $tempfile)
    rm -f $tempfile

    # Clear screen after dialog closes
    clear

    echo $choices
}

# Main script
detect_distro
echo -e "${GREEN}Detected distribution: $DISTRO${NC}"

install_web_server

while true; do
    choices=$(show_menu)

    if [[ $choices == *"Quit"* ]]; then
        echo "Exiting..."
        exit 0
    elif [[ $choices == *"Install Selected"* ]]; then
        for choice in $choices; do
            case $choice in
                "rTorrent with ruTorrent")
                    install_and_configure_app "rTorrent with ruTorrent" "install_package rtorrent && install_package php && install_package git && git clone https://github.com/Novik/ruTorrent.git /var/www/html/rutorrent" "sudo chown -R www-data:www-data /var/www/html/rutorrent && sudo chmod -R 755 /var/www/html/rutorrent" false
                    ;;
                "Deluge")
                    install_and_configure_app "Deluge" "install_package deluged && install_package deluge-web" "sudo systemctl start deluged && sudo systemctl enable deluged && sudo systemctl start deluge-web && sudo systemctl enable deluge-web" false
                    ;;
                "Transmission")
                    install_and_configure_app "Transmission" "install_package transmission-daemon" "sudo systemctl start transmission-daemon && sudo systemctl enable transmission-daemon" false
                    ;;
                "qBittorrent")
                    install_and_configure_app "qBittorrent" "install_package qbittorrent-nox" "sudo systemctl start qbittorrent-nox && sudo systemctl enable qbittorrent-nox" false
                    ;;
                "Sonarr")
                    install_and_configure_app "Sonarr" "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 && echo 'deb https://apt.sonarr.tv/ubuntu focal main' | sudo tee /etc/apt/sources.list.d/sonarr.list && sudo apt-get update && sudo apt-get install -y sonarr" "sudo systemctl start sonarr && sudo systemctl enable sonarr" true
                    ;;
                "Radarr")
                    install_and_configure_app "Radarr" "wget https://github.com/Radarr/Radarr/releases/download/v3.2.2.5080/Radarr.master.3.2.2.5080.linux-core-x64.tar.gz && tar -xvzf Radarr.master.3.2.2.5080.linux-core-x64.tar.gz && sudo mv Radarr /opt/" "sudo useradd -r radarr && sudo chown -R radarr:radarr /opt/Radarr && sudo tee /etc/systemd/system/radarr.service > /dev/null <<EOL
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=radarr
Group=radarr
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload && sudo systemctl start radarr && sudo systemctl enable radarr" true
                    ;;
                "Lidarr")
                    install_and_configure_app "Lidarr" "wget https://github.com/lidarr/Lidarr/releases/download/v0.8.1.2135/Lidarr.master.0.8.1.2135.linux-x64.tar.gz && tar -xvzf Lidarr.master.0.8.1.2135.linux-x64.tar.gz && sudo mv Lidarr /opt/" "sudo useradd -r lidarr && sudo chown -R lidarr:lidarr /opt/Lidarr && sudo tee /etc/systemd/system/lidarr.service > /dev/null <<EOL
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target

[Service]
User=lidarr
Group=lidarr
Type=simple
ExecStart=/usr/bin/mono /opt/Lidarr/Lidarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload && sudo systemctl start lidarr && sudo systemctl enable lidarr" true
                    ;;
                "Jackett")
                    install_and_configure_app "Jackett" "wget https://github.com/Jackett/Jackett/releases/download/v0.18.541/Jackett.Binaries.LinuxAMDx64.tar.gz && tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz && sudo mv Jackett /opt/" "sudo useradd -r jackett && sudo chown -R jackett:jackett /opt/Jackett && sudo tee /etc/systemd/system/jackett.service > /dev/null <<EOL
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
User=jackett
Group=jackett
Type=simple
ExecStart=/opt/Jackett/jackett --NoUpdates
Restart=on-failure
RestartSec=5
SyslogIdentifier=jackett

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload && sudo systemctl start jackett && sudo systemctl enable jackett" false
                    ;;
                "Plex Media Server")
                    plex_claim=$(dialog --title "Plex Claim Code" --inputbox "Please enter your Plex claim code (https://www.plex.tv/claim/):" 8 60 3>&1 1>&2 2>&3)
                    install_and_configure_app "Plex Media Server" "curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add - && echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list && sudo apt-get update && sudo apt-get install -y plexmediaserver" "sudo PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/var/lib/plexmediaserver/Library/Application\ Support PLEX_CLAIM=$plex_claim /usr/lib/plexmediaserver/Plex\ Media\ Server && sudo systemctl start plexmediaserver && sudo systemctl enable plexmediaserver" false
                    ;;
                "Emby")
                    install_and_configure_app "Emby" "wget https://github.com/MediaBrowser/Emby.Releases/releases/download/4.6.4.0/emby-server-deb_4.6.4.0_amd64.deb && sudo dpkg -i emby-server-deb_4.6.4.0_amd64.deb" "sudo systemctl start emby-server && sudo systemctl enable emby-server" false
                    ;;
                "Jellyfin")
                    install_and_configure_app "Jellyfin" "sudo apt-get update && sudo apt-get install -y apt-transport-https && wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | sudo apt-key add - && echo 'deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main' | sudo tee /etc/apt/sources.list.d/jellyfin.list && sudo apt-get update && sudo apt-get install -y jellyfin" "sudo systemctl start jellyfin && sudo systemctl enable jellyfin" false
                    ;;
                "FileZilla")
                    install_and_configure_app "FileZilla" "install_package filezilla" "echo 'FileZilla is a GUI application and does not require additional configuration.'" false
                    ;;
                "OpenVPN")
                    install_and_configure_app "OpenVPN" "install_package openvpn" "echo 'OpenVPN requires manual configuration. Please refer to the OpenVPN documentation for setup instructions.'" false
                    ;;
                "Nextcloud")install_nextcloud() {
    echo -e "${BLUE}Installing and configuring Nextcloud...${NC}"
    # Install dependencies
    install_package "apache2 mariadb-server libapache2-mod-php php-gd php-json php-mysql php-curl php-mbstring php-intl php-imagick php-xml php-zip"
    
    # Download and extract Nextcloud
    wget https://download.nextcloud.com/server/releases/latest.tar.bz2
    tar -xjf latest.tar.bz2 -C /var/www/html/
    
    # Set permissions
    sudo chown -R www-data:www-data /var/www/html/nextcloud
    
    # Configure Apache
    echo "<VirtualHost *:80>
    DocumentRoot /var/www/html/nextcloud/
    ServerName nextcloud.yourdomain.com
    
    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>
    </VirtualHost>" | sudo tee /etc/apache2/sites-available/nextcloud.conf
    
    sudo a2ensite nextcloud.conf
    sudo a2enmod rewrite
    sudo systemctl restart apache2
    
    echo -e "${GREEN}Nextcloud installed and configured. Access it at http://nextcloud.yourdomain.com${NC}"
}

# Function to install and configure Overseerr
install_overseerr() {
    echo -e "${BLUE}Installing and configuring Overseerr...${NC}"
    # Install Node.js and npm
    install_package "nodejs npm"
    
    # Install Overseerr
    npm install -g overseerr
    
    # Create a system user for Overseerr
    sudo useradd -r -s /bin/false overseerr
    
    # Create directory for Overseerr
    sudo mkdir -p /opt/overseerr
    sudo chown overseerr:overseerr /opt/overseerr
    
    # Create systemd service file
    echo "[Unit]
    Description=Overseerr Service
    After=network.target

    [Service]
    User=overseerr
    Group=overseerr
    WorkingDirectory=/opt/overseerr
    ExecStart=/usr/bin/npm start
    Restart=always

    [Install]
    WantedBy=multi-user.target" | sudo tee /etc/systemd/system/overseerr.service
    
    # Start and enable the service
    sudo systemctl daemon-reload
    sudo systemctl start overseerr
    sudo systemctl enable overseerr
    
    echo -e "${GREEN}Overseerr installed and configured. Access it at http://localhost:5055${NC}"
}

# Function to install and configure Tautulli
install_tautulli() {
    echo -e "${BLUE}Installing and configuring Tautulli...${NC}"
    # Install dependencies
    install_package "python3 python3-pip git"
    
    # Clone Tautulli repository
    git clone https://github.com/Tautulli/Tautulli.git /opt/Tautulli
    
    # Create a system user for Tautulli
    sudo useradd -r -s /bin/false tautulli
    
    # Set permissions
    sudo chown -R tautulli:tautulli /opt/Tautulli
    
    # Create systemd service file
    echo "[Unit]
    Description=Tautulli Service
    After=network.target

    [Service]
    User=tautulli
    Group=tautulli
    WorkingDirectory=/opt/Tautulli
    ExecStart=/usr/bin/python3 /opt/Tautulli/Tautulli.py
    Restart=always

    [Install]
    WantedBy=multi-user.target" | sudo tee /etc/systemd/system/tautulli.service
    
    # Start and enable the service
    sudo systemctl daemon-reload
    sudo systemctl start tautulli
    sudo systemctl enable tautulli
    
    echo -e "${GREEN}Tautulli installed and configured. Access it at http://localhost:8181${NC}"
}

install_overseerr() {
    echo -e "${BLUE}Installing and configuring Overseerr...${NC}"
    
    # Check for dependencies
    for dep in nodejs npm; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}$dep is not installed. Please install it and try again.${NC}"
            return 1
        fi
    done
    
    # Allow custom installation directory
    read -p "Enter installation directory for Overseerr (default: /opt/overseerr): " install_dir
    install_dir=${install_dir:-/opt/overseerr}
    
    # Backup existing installation
    if [ -d "$install_dir" ]; then
        backup_dir="${install_dir}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Backing up existing installation to $backup_dir${NC}"
        sudo mv "$install_dir" "$backup_dir"
    fi
    
    # Create installation directory
    sudo mkdir -p "$install_dir"
    
    # Install Overseerr
    if ! sudo npm install -g overseerr; then
        echo -e "${RED}Failed to install Overseerr${NC}"
        return 1
    fi
    
    # Create a system user for Overseerr
    sudo useradd -r -s /bin/false overseerr
    
    # Set permissions
    sudo chown -R overseerr:overseerr "$install_dir"
    
    # Create systemd service file
    service_file="/etc/systemd/system/overseerr.service"
    echo "[Unit]
Description=Overseerr Service
After=network.target

[Service]
User=overseerr
Group=overseerr
WorkingDirectory=$install_dir
ExecStart=$(which overseerr)
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee "$service_file"
    
    # Start and enable the service
    sudo systemctl daemon-reload
    if ! sudo systemctl start overseerr; then
        echo -e "${RED}Failed to start Overseerr service${NC}"
        return 1
    fi
    if ! sudo systemctl enable overseerr; then
        echo -e "${RED}Failed to enable Overseerr service${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Overseerr installed and configured. Access it at http://localhost:5055${NC}"
    echo -e "${YELLOW}Remember to secure your Overseerr installation by setting up authentication.${NC}"
}

install_tautulli() {
    echo -e "${BLUE}Installing and configuring Tautulli...${NC}"
    
    # Check for dependencies
    for dep in python3 pip git; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}$dep is not installed. Please install it and try again.${NC}"
            return 1
        fi
    done
    
    # Allow custom installation directory
    read -p "Enter installation directory for Tautulli (default: /opt/Tautulli): " install_dir
    install_dir=${install_dir:-/opt/Tautulli}
    
    # Backup existing installation
    if [ -d "$install_dir" ]; then
        backup_dir="${install_dir}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Backing up existing installation to $backup_dir${NC}"
        sudo mv "$install_dir" "$backup_dir"
    fi
    
    # Clone Tautulli repository
    if ! git clone https://github.com/Tautulli/Tautulli.git "$install_dir"; then
        echo -e "${RED}Failed to clone Tautulli repository${NC}"
        return 1
    fi
    
    # Create a system user for Tautulli
    sudo useradd -r -s /bin/false tautulli
    
    # Set permissions
    sudo chown -R tautulli:tautulli "$install_dir"
    
    # Create systemd service file
    service_file="/etc/systemd/system/tautulli.service"
    echo "[Unit]
Description=Tautulli Service
After=network.target

[Service]
User=tautulli
Group=tautulli
WorkingDirectory=$install_dir
ExecStart=/usr/bin/python3 $install_dir/Tautulli.py
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee "$service_file"
    
    # Start and enable the service
    sudo systemctl daemon-reload
    if ! sudo systemctl start tautulli; then
        echo -e "${RED}Failed to start Tautulli service${NC}"
        return 1
    fi
    if ! sudo systemctl enable tautulli; then
        echo -e "${RED}Failed to enable Tautulli service${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Tautulli installed and configured. Access it at http://localhost:8181${NC}"
    echo -e "${YELLOW}Remember to secure your Tautulli installation by setting up authentication.${NC}"
}

# These improvements include:
# 1. Dependency checks at the start of each function
# 2. Custom installation directories
# 3. Backing up existing installations
# 4. Better error handling
# 5. Reminders about security

# You can apply similar improvements to other installation functions in your script.











