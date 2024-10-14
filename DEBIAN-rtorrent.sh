#!/bin/bash

# Combined rTorrent and ruTorrent installer and configuration script
# TechLogicals
# Licensed under GNU General Public License v3.0 GPL-3 (in short)

export DEBIAN_FRONTEND=noninteractive
export distribution=$(lsb_release -is)
export release=$(lsb_release -rs)
export codename=$(lsb_release -cs)

# Initialize log file
log="/var/log/rutorrent_install.log"

# Function to log messages
function log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $log
}

# Function to install packages
function apt_install() {
    for package in "$@"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo "Installing $package..."
            apt-get install -y "$package" >> $log 2>&1
            log_message "Installed $package"
        else
            echo "$package is already installed."
        fi
    done
}

# Function to generate a random string
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15; }

# Function to configure rTorrent
function _rconf() {
    cat > /home/${user}/.rtorrent.rc << EOF
# -- START HERE --
directory.default.set = /home/${user}/torrents/rtorrent
encoding.add = UTF-8
encryption = allow_incoming,try_outgoing,enable_retry
execute.nothrow = chmod,777,/home/${user}/.config/rpc.socket
execute.nothrow = chmod,777,/home/${user}/.sessions
network.port_random.set = yes
network.port.range.set = $port-$portend
network.scgi.open_local = /var/run/${user}/.rtorrent.sock
schedule2 = chmod_scgi_socket, 0, 0, "execute2=chmod,\"g+w,o=\",/var/run/${user}/.rtorrent.sock"
network.tos.set = throughput
pieces.hash.on_completion.set = no
pieces.preload.min_rate.set = 50000
protocol.pex.set = no
schedule = watch_directory,5,5,load.start=/home/${user}/rwatch/*.torrent
session.path.set = /home/${user}/.sessions/
throttle.global_down.max_rate.set = 0
throttle.global_up.max_rate.set = 0
throttle.max_peers.normal.set = 100
throttle.max_peers.seed.set = -1
throttle.max_uploads.global.set = 100
throttle.min_peers.normal.set = 1
throttle.min_peers.seed.set = -1
trackers.use_udp.set = yes
schedule2 = session_save, 1200, 3600, ((session.save))
method.set_key = event.download.inserted, 2_save_session, ((d.save_full_session))

execute = {sh,-c,/usr/bin/php /srv/rutorrent/php/initplugins.php ${user} &}

# -- END HERE --
EOF
    chown ${user}:${user} -R /home/${user}/.rtorrent.rc
}

# Function to create necessary directories
function _makedirs() {
    mkdir -p /home/${user}/torrents/rtorrent 2>> $log
    mkdir -p /home/${user}/.sessions
    mkdir -p /home/${user}/rwatch
    chown -R ${user}:${user} /home/${user}/{torrents,.sessions,rwatch} 2>> $log
    usermod -a -G www-data ${user} 2>> $log
    usermod -a -G ${user} www-data 2>> $log
}

# Function to set up systemd service for rTorrent
function _systemd() {
    cat > /etc/systemd/system/rtorrent@.service << EOF
[Unit]
Description=rTorrent
After=network.target

[Service]
Type=forking
KillMode=none
User=%i
ExecStartPre=-/bin/rm -f /home/%i/.sessions/rtorrent.lock
ExecStart=/usr/bin/screen -d -m -fa -S rtorrent /usr/bin/rtorrent
ExecStop=/usr/bin/screen -X -S rtorrent quit
WorkingDirectory=/home/%i/

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable -q --now rtorrent@${user} 2>> $log
}

# Function to build rTorrent from source
function build_rtorrent() {
    echo "Building rTorrent from source..."
    
    # Ensure the build directory is clean
    if [ -d "/tmp/rtorrent" ]; then
        rm -rf /tmp/rtorrent
    fi

    # Clone the rTorrent repository
    cd /tmp
    git clone https://github.com/rakshasa/rtorrent.git
    cd rtorrent

    # Checkout the specified version
    if ! git checkout $rtorrentver; then
        echo "Version $rtorrentver not found. Please check available versions."
        exit 1
    fi

    # Run the build process
    ./autogen.sh || { echo "autogen.sh failed"; exit 1; }
    ./configure --with-xmlrpc-c --with-curl || { echo "configure failed"; exit 1; }
    make || { echo "make failed"; exit 1; }
    sudo make install || { echo "make install failed"; exit 1; }

    echo "rTorrent build completed."
}

# Function to configure rTorrent version
function set_rtorrent_version() {
    case $1 in
        0.9.6 | '0.9.6')
            export rtorrentver='0.9.6'
            export libtorrentver='0.13.6'
            export libudns='false'
            export rtorrentpgo='false'
            ;;
        0.9.7 | '0.9.7')
            export rtorrentver='0.9.7'
            export libtorrentver='0.13.7'
            export libudns='false'
            export rtorrentpgo='false'
            ;;
        0.9.8 | '0.9.8')
            export rtorrentver='0.9.8'
            export libtorrentver='0.13.8'
            export libudns='false'
            export rtorrentpgo='false'
            ;;
        0.10.0 | '0.10.0')
            export rtorrentver='0.10.0'
            export libtorrentver='0.14.0'
            export libudns='false'
            export rtorrentpgo='false'
            ;;
        UDNS | 'UDNS')
            export rtorrentver='0.9.8'
            export libtorrentver='0.13.8'
            export libudns='true'
            export rtorrentpgo='false'
            ;;
        PGO | 'PGO')
            export rtorrentver='0.9.8'
            export libtorrentver='0.13.8'
            export libudns='true'
            export rtorrentpgo='true'
            ;;
        Repo | 'Repo')
            export rtorrentver='repo'
            export libtorrentver='repo'
            export libudns='false'
            export rtorrentpgo='false'
            ;;
        *)
            echo "Invalid rTorrent version specified."
            exit 1
            ;;
    esac
}

# Function to install dependencies for rTorrent
function depends_rtorrent() {
    if [[ ! $rtorrentver == repo ]]; then
        APT='subversion dos2unix bc screen zip unzip sysstat build-essential automake libtool libssl-dev pkg-config libcurl4-openssl-dev libsigc++-2.0-dev'
        apt_install $APT
    else
        APT='screen zip unzip bc mediainfo curl'
        apt_install $APT
    fi
}

# Function to install or configure Nginx
function install_nginx() {
    if command -v nginx > /dev/null; then
        echo "Nginx is already installed. Configuring..."
    else
        echo "Installing Nginx..."
        apt-get update
        apt-get install -y nginx
        systemctl enable nginx
        systemctl start nginx
    fi

    # Configure Nginx for ruTorrent
    cat > /etc/nginx/sites-available/rutorrent << EOF
server {
    listen 80;
    server_name ${nginx_domain};  # User-defined domain or IP

    root /var/www/html/rutorrent;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;  # Adjust PHP version if necessary
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    ln -s /etc/nginx/sites-available/rutorrent /etc/nginx/sites-enabled/
    nginx -t
    systemctl restart nginx
}

# Function to prompt user for rTorrent version selection and user account
function whiptail_rtorrent() {
    # Prompt for user selection
    user=$(whiptail --inputbox "Enter the username for rTorrent:" 10 60 "$USER" --title "User Selection" 3>&1 1>&2 2>&3) || {
        echo "User selection aborted"
        exit 1
    }

    # Prompt for domain or IP for Nginx
    nginx_domain=$(whiptail --inputbox "Enter your domain name or IP address for Nginx:" 10 60 "your_domain_or_ip" --title "Nginx Domain/IP" 3>&1 1>&2 2>&3) || {
        echo "Domain/IP selection aborted"
        exit 1
    }

    # Prompt for htpasswd username and password
    htpasswd_user=$(whiptail --inputbox "Enter the username for HTTP authentication:" 10 60 "rutorrent_user" --title "HTTP Auth Username" 3>&1 1>&2 2>&3) || {
        echo "HTTP username selection aborted"
        exit 1
    }

    htpasswd_pass=$(whiptail --passwordbox "Enter the password for HTTP authentication:" 10 60 "" --title "HTTP Auth Password" 3>&1 1>&2 2>&3) || {
        echo "HTTP password selection aborted"
        exit 1
    }

    # Create htpasswd file
    htpasswd_file="/etc/nginx/.htpasswd"
    if [[ ! -f $htpasswd_file ]]; then
        sudo touch $htpasswd_file
    fi
    echo "$htpasswd_user:$(openssl passwd -apr1 $htpasswd_pass)" | sudo tee -a $htpasswd_file > /dev/null

    if [[ -z $rtorrentver ]] && [[ -z $1 ]] && [[ -z $RTORRENT_VERSION ]]; then
        repov=$(get_candidate_version rtorrent)

        whiptail --title "rTorrent Install Advisory" --msgbox "We recommend rTorrent version selection instead of repo (distro) releases. They will compile additional performance and stability improvements in 90s. UDNS includes a stability patch for UDP trackers on rTorrent." 15 50

        function=$(whiptail --title "Choose an rTorrent version" --menu "All versions other than repo will be locally compiled from source" --ok-button "Continue" 14 50 5 \
            0.10.0 "" \
            0.9.8 "" \
            0.9.7 "" \
            0.9.6 "" \
            UDNS "(0.9.8)" \
            PGO "(0.9.8)" \
            Repo "(${repov})" 3>&1 1>&2 2>&3) || {
            echo "rTorrent version choice aborted"
            exit 1
        }

        set_rtorrent_version $function
    elif [[ -n $RTORRENT_VERSION ]]; then
        set_rtorrent_version $RTORRENT_VERSION
    fi
}

# Function to install ruTorrent
function install_rutorrent() {
    # Install ruTorrent dependencies
    APT='php php-cli php-curl php-mbstring php-xml php-zip php-gd'
    apt_install $APT

    # Check if the ruTorrent directory already exists
    if [ -d "/var/www/html/rutorrent" ]; then
        echo "ruTorrent directory already exists. Skipping clone."
    else
        # Download and install ruTorrent
        cd /var/www/html
        git clone https://github.com/Novik/ruTorrent.git rutorrent
        chown -R www-data:www-data rutorrent
        chmod -R 755 rutorrent
    fi

    # Set up ruTorrent configuration
    if [ -f "rutorrent/conf/config.php.default" ]; then
        cp -r rutorrent/conf/config.php.default rutorrent/conf/config.php
        sed -i "s/\$host = 'localhost';/\$host = '127.0.0.1';/" rutorrent/conf/config.php
        sed -i "s/\$port = 80;/\$port = 80;/" rutorrent/conf/config.php
    else
        echo "Configuration file not found. Please check the ruTorrent installation."
        exit 1
    fi
}

# Main script execution
port=$((RANDOM % 64025 + 1024))
portend=$((${port} + 1500))

if [[ -n $1 ]]; then
    user=$1
    _makedirs
    _rconf
    exit 0
fi

whiptail_rtorrent

depends_rtorrent

# Install or configure Nginx
install_nginx

# Build and install rTorrent based on the selected version
if [[ ! $rtorrentver == repo ]]; then
    echo "Building rTorrent from source..."
    build_rtorrent
else
    echo "Installing rTorrent with apt-get..."
    rtorrent_apt
    echo "rTorrent installation completed."
fi

echo "Making ${user} directory structure..."
_makedirs
echo "Directory structure created."

echo "Setting up rtorrent.rc..."
_rconf
_systemd
echo "rtorrent.rc setup completed."

# Install ruTorrent
echo "Installing ruTorrent..."
install_rutorrent
echo "ruTorrent installation completed."

# Ensure the /install directory exists before creating the lock file
install_dir="/install"
if [ ! -d "$install_dir" ]; then
    mkdir -p "$install_dir"
fi

touch "$install_dir/.rtorrent.lock"
echo "rTorrent and ruTorrent installed and configured successfully."