#!/bin/bash
#little util by gjm of techlogicals
# Function to get FTP details from user
get_ftp_details() {
    read -p "Enter FTP server address: " ftp_server
    read -p "Enter FTP username: " ftp_username
    read -s -p "Enter FTP password: " ftp_password
    echo
    read -p "Enter FTP remote directory: " ftp_remote_dir
}

# Function to detect if a file is text or binary
is_text_file() {
    local file="$1"
    if file "$file" | grep -q "text"; then
        return 0
    else
        return 1
    fi
}

# Function to upload file to FTP server
upload_to_ftp() {
    local file="$1"
    local file_type="$2"
    
    if [ "$file_type" = "text" ]; then
        ftp_command="put"
    else
        ftp_command="binary
put"
    fi

    ftp -n <<EOF
open $ftp_server
user $ftp_username $ftp_password
cd $ftp_remote_dir
$ftp_command "$file"
bye
EOF
    echo "Uploaded $file to FTP server (type: $file_type)"
}

# Get FTP details
get_ftp_details

# Ask for directory to watch
read -p "Enter the directory to watch: " watch_dir

# Ensure the watch directory exists
if [ ! -d "$watch_dir" ]; then
    echo "Error: Directory $watch_dir does not exist."
    exit 1
fi

# Create a log file
log_file="/tmp/ftp_upload_watch.log"
touch "$log_file"

# Start the watching process in the background
(
    echo "Watching directory $watch_dir for new files..." >> "$log_file"
    inotifywait -m -e create -e moved_to "$watch_dir" |
        while read -r directory events filename; do
            if [ -f "$watch_dir/$filename" ]; then
                echo "$(date): New file detected: $filename" >> "$log_file"
                if is_text_file "$watch_dir/$filename"; then
                    file_type="text"
                else
                    file_type="binary"
                fi
                echo "File type: $file_type" >> "$log_file"
                upload_to_ftp "$watch_dir/$filename" "$file_type" >> "$log_file" 2>&1
            fi
        done
) &

# Save the PID of the background process
echo $! > /tmp/ftp_upload_watch.pid

echo "Watching process started in the background. PID: $(cat /tmp/ftp_upload_watch.pid)"
echo "Log file: $log_file"
echo "To stop the watching process, run: kill $(cat /tmp/ftp_upload_watch.pid)"


