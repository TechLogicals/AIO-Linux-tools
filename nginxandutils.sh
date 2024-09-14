#!/bin/bash

# Colors for echo outputs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to install and configure Nginx
install_configure_nginx() {
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}Installing Nginx...${NC}"
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            apt-get update
            apt-get install -y nginx
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            yum install -y epel-release
            yum install -y nginx
        else
            echo -e "${RED}Unsupported OS. Please install Nginx manually.${NC}"
            exit 1
        fi
        systemctl start nginx
        systemctl enable nginx
        echo -e "${GREEN}Nginx installed and started.${NC}"
    else
        echo -e "${BLUE}Nginx is already installed.${NC}"
    fi
}

# Function to create Nginx configuration
create_nginx_config() {
    local domain=$1
    local web_root=$2
    local config_file="/etc/nginx/sites-available/$domain"

    cat << EOF > "$config_file"
server {
    listen 80;
    server_name $domain;
    root $web_root;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
EOF

    ln -s "$config_file" "/etc/nginx/sites-enabled/"
}

# Function to install Certbot
install_certbot() {
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Installing Certbot...${NC}"
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            yum install -y epel-release
            yum install -y certbot python3-certbot-nginx
        else
            echo -e "${RED}Unsupported OS. Please install Certbot manually.${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}Certbot is already installed.${NC}"
    fi
}

# Function to install and configure MariaDB
install_configure_mariadb() {
    if ! command -v mysql &> /dev/null; then
        echo -e "${YELLOW}Installing MariaDB...${NC}"
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            apt-get update
            apt-get install -y mariadb-server
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            yum install -y mariadb-server
        else
            echo -e "${RED}Unsupported OS. Please install MariaDB manually.${NC}"
            exit 1
        fi
        systemctl start mariadb
        systemctl enable mariadb
        echo -e "${GREEN}MariaDB installed and started.${NC}"
    else
        echo -e "${BLUE}MariaDB is already installed.${NC}"
    fi
}

# Function to create database and user
create_database() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3

    mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
    mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
}

# Function to install WordPress
install_wordpress() {
    local web_root=$1
    local db_name=$2
    local db_user=$3
    local db_pass=$4

    wget https://wordpress.org/latest.tar.gz
    tar -xzvf latest.tar.gz
    cp -r wordpress/* "$web_root"
    rm -rf wordpress latest.tar.gz

    cp "$web_root/wp-config-sample.php" "$web_root/wp-config.php"
    sed -i "s/database_name_here/$db_name/" "$web_root/wp-config.php"
    sed -i "s/username_here/$db_user/" "$web_root/wp-config.php"
    sed -i "s/password_here/$db_pass/" "$web_root/wp-config.php"

    chown -R www-data:www-data "$web_root"
}

# Function to install WordPress theme
install_wordpress_theme() {
    local web_root=$1
    local theme_name=$2
    local theme_url=$3

    wget "$theme_url" -O "$web_root/wp-content/themes/$theme_name.zip"
    unzip "$web_root/wp-content/themes/$theme_name.zip" -d "$web_root/wp-content/themes/"
    rm "$web_root/wp-content/themes/$theme_name.zip"

    chown -R www-data:www-data "$web_root/wp-content/themes"
}

# Function to install Joomla
install_joomla() {
    local web_root=$1
    local db_name=$2
    local db_user=$3
    local db_pass=$4

    wget https://downloads.joomla.org/cms/joomla4/4-2-7/Joomla_4-2-7-Stable-Full_Package.tar.gz
    tar -xzvf Joomla_4-2-7-Stable-Full_Package.tar.gz -C "$web_root"
    rm Joomla_4-2-7-Stable-Full_Package.tar.gz

    chown -R www-data:www-data "$web_root"
}

# Function to install PrestaShop
install_prestashop() {
    local web_root=$1
    local db_name=$2
    local db_user=$3
    local db_pass=$4

    wget https://download.prestashop.com/download/releases/prestashop_1.7.8.7.zip
    unzip prestashop_1.7.8.7.zip -d "$web_root"
    rm prestashop_1.7.8.7.zip

    chown -R www-data:www-data "$web_root"
}

# Main script
echo -e "${GREEN}Welcome to the Nginx domain configuration and CMS installation script!${NC}"

# Install and configure Nginx if not found
install_configure_nginx

# Ask for domain name
read -p "Enter the domain name: " domain

# Ask for web root directory
read -p "Enter the web root directory for $domain: " web_root

# Create web root directory if it doesn't exist
mkdir -p "$web_root"

# Create Nginx configuration
create_nginx_config "$domain" "$web_root"

# Reload Nginx
systemctl reload nginx

echo -e "${GREEN}Nginx configuration for $domain has been created.${NC}"

# Ask about SSL certificate
read -p "Do you want to set up an SSL certificate using Let's Encrypt? (y/n): " ssl_choice

if [[ $ssl_choice =~ ^[Yy]$ ]]; then
    # Install Certbot
    install_certbot

    # Run certbot
    certbot --nginx -d "$domain"

    echo -e "${GREEN}SSL certificate has been set up for $domain.${NC}"
else
    echo -e "${YELLOW}SSL certificate setup skipped.${NC}"
fi

# Ask about CMS installation
read -p "Do you want to install a CMS? (wordpress/joomla/prestashop/none): " cms_choice

if [[ $cms_choice != "none" ]]; then
    # Install and configure MariaDB
    install_configure_mariadb

    # Generate random database credentials
    db_name="${domain//./_}_db"
    db_user="${domain//./_}_user"
    db_pass=$(openssl rand -base64 12)

    # Create database and user
    create_database "$db_name" "$db_user" "$db_pass"

    case $cms_choice in
        wordpress)
            install_wordpress "$web_root" "$db_name" "$db_user" "$db_pass"
            echo -e "${GREEN}WordPress has been installed and configured.${NC}"
            echo -e "${BLUE}WordPress setup URL: http://$domain/wp-admin/install.php${NC}"

            # Ask about WordPress themes using whiptail
            theme_choice=$(whiptail --title "WordPress Themes" --menu "Choose a WordPress theme to install:" 20 78 6 \
                "1" "Twenty Twenty-One (Already included)" \
                "2" "Astra" \
                "3" "OceanWP" \
                "4" "GeneratePress" \
                "5" "Neve" \
                "6" "None" 3>&1 1>&2 2>&3)

            case $theme_choice in
                1)
                    whiptail --title "Theme Installation" --msgbox "Twenty Twenty-One theme is already included in WordPress." 8 78
                    ;;
                2)
                    install_wordpress_theme "$web_root" "astra" "https://downloads.wordpress.org/theme/astra.zip"
                    whiptail --title "Theme Installation" --msgbox "Astra theme has been installed." 8 78
                    ;;
                3)
                    install_wordpress_theme "$web_root" "oceanwp" "https://downloads.wordpress.org/theme/oceanwp.zip"
                    whiptail --title "Theme Installation" --msgbox "OceanWP theme has been installed." 8 78
                    ;;
                4)
                    install_wordpress_theme "$web_root" "generatepress" "https://downloads.wordpress.org/theme/generatepress.zip"
                    whiptail --title "Theme Installation" --msgbox "GeneratePress theme has been installed." 8 78
                    ;;
                5)
                    install_wordpress_theme "$web_root" "neve" "https://downloads.wordpress.org/theme/neve.zip"
                    whiptail --title "Theme Installation" --msgbox "Neve theme has been installed." 8 78
                    ;;
                6)
                    whiptail --title "Theme Installation" --msgbox "No additional theme installed." 8 78
                    ;;
                *)
                    whiptail --title "Error" --msgbox "Invalid choice. No additional theme installed." 8 78
                    ;;
            esac
            ;;
        joomla)
            install_joomla "$web_root" "$db_name" "$db_user" "$db_pass"
            echo -e "${GREEN}Joomla has been installed. Please complete the setup through the web interface.${NC}"
            echo -e "${BLUE}Joomla setup URL: http://$domain/installation/index.php${NC}"
            ;;
        prestashop)
            install_prestashop "$web_root" "$db_name" "$db_user" "$db_pass"
            echo -e "${GREEN}PrestaShop has been installed. Please complete the setup through the web interface.${NC}"
            echo -e "${BLUE}PrestaShop setup URL: http://$domain/install/${NC}"
            ;;
        *)
            echo -e "${RED}Invalid CMS choice. Skipping CMS installation.${NC}"
            ;;
    esac

    echo -e "${YELLOW}Database information:${NC}"
    echo -e "${BLUE}Database Name: $db_name${NC}"
    echo -e "${BLUE}Database User: $db_user${NC}"
    echo -e "${BLUE}Database Password: $db_pass${NC}"
else
    echo -e "${YELLOW}CMS installation skipped.${NC}"
fi

echo -e "${GREEN}Configuration complete!${NC}"







