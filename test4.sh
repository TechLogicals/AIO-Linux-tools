#!/bin/bash

# Install Nginx
sudo apt update
sudo apt install -y nginx

# Install required packages
sudo apt install -y sysstat lm-sensors fcgiwrap

# Create a script to gather system information
cat << 'EOF' > /tmp/system_info.sh
#!/bin/bash

get_disk_usage() {
    df -h | awk '$NF=="/" {print $5}'
}

get_system_load() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1 $2 $3}'
}

get_cpu_info() {
    lscpu | awk -F: '/Model name/ {print $2}' | xargs
}

get_ram_info() {
    free -h | awk '/^Mem:/ {print $2}'
}

get_gpu_info() {
    lspci | grep -i vga | awk -F: '{print $3}'
}

cat << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Information</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .info-box {
            background-color: #fff;
            border-radius: 5px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .info-item {
            margin-bottom: 10px;
        }
        .info-label {
            font-weight: bold;
            color: #555;
        }
    </style>
</head>
<body>
    <h1>System Information</h1>
    <div class="info-box">
        <div class="info-item">
            <span class="info-label">Disk Usage:</span> $(get_disk_usage)
        </div>
        <div class="info-item">
            <span class="info-label">System Load:</span> $(get_system_load)
        </div>
        <div class="info-item">
            <span class="info-label">CPU:</span> $(get_cpu_info)
        </div>
        <div class="info-item">
            <span class="info-label">RAM:</span> $(get_ram_info)
        </div>
        <div class="info-item">
            <span class="info-label">GPU:</span> $(get_gpu_info)
        </div>
    </div>
</body>
</html>
HTML
EOF

# Make the script executable
sudo chmod +x /tmp/system_info.sh

# Create a Nginx server block configuration
sudo tee /etc/nginx/sites-available/system_info << EOF
server {
    listen 80;
    server_name localhost;

    root /var/www/html;
    index index.html;

    location / {
        fastcgi_pass unix:/var/run/fcgiwrap.sock;
        fastcgi_param SCRIPT_FILENAME /tmp/system_info.sh;
        include fastcgi_params;
    }
}
EOF

# Enable the Nginx server block
sudo ln -s /etc/nginx/sites-available/system_info /etc/nginx/sites-enabled/

# Remove the default Nginx configuration
sudo rm /etc/nginx/sites-enabled/default

# Ensure fcgiwrap is running and socket is created
sudo systemctl start fcgiwrap
sudo systemctl enable fcgiwrap

# Set correct permissions for the fcgiwrap socket
sudo chown www-data:www-data /var/run/fcgiwrap.sock

# Set correct permissions for the system_info.sh script
sudo chown www-data:www-data /tmp/system_info.sh
sudo chmod 755 /tmp/system_info.sh

# Test Nginx configuration
sudo nginx -t

# Restart Nginx and fcgiwrap
sudo systemctl restart nginx
sudo systemctl restart fcgiwrap

echo "Installation complete. Access the system information page at http://localhost"
echo "If you encounter issues, check Nginx error logs: sudo tail -f /var/log/nginx/error.log"
echo "Also check fcgiwrap logs: sudo journalctl -u fcgiwrap"
