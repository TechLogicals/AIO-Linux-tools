#!/bin/bash

# Script for PC1

# Function to generate a random file
generate_random_file() {
    dd if=/dev/urandom of=testfile bs=1M count=100
}

# Function to start a netcat listener
start_listener() {
    nc -l -p 5000 > /dev/null
}

# Function to send file
send_file() {
    cat testfile | nc $1 5000
}

# Main execution
echo "PC1 Network Speed Test Script"

# Generate a random 100MB file
echo "Generating test file..."
generate_random_file

# Get PC2's IP address
read -p "Enter PC2's IP address: " pc2_ip

# Start timing
start_time=$(date +%s.%N)

# Send file to PC2
echo "Sending file to PC2..."
send_file $pc2_ip

# Wait for PC2 to finish receiving
echo "Waiting for PC2 to finish receiving..."
start_listener

# End timing
end_time=$(date +%s.%N)

# Calculate duration
duration=$(echo "$end_time - $start_time" | bc)

# Calculate speed
speed=$(echo "scale=2; 100 / $duration" | bc)

echo "Transfer completed in $duration seconds"
echo "Network speed: $speed MB/s"

# Clean up
rm testfile

#!/bin/bash

# Script for PC2

# Function to start a netcat listener and save the received file
receive_file() {
    nc -l -p 5000 > received_file
}

# Function to send confirmation
send_confirmation() {
    echo "done" | nc $1 5000
}

# Main execution
echo "PC2 Network Speed Test Script"

# Get PC1's IP address
read -p "Enter PC1's IP address: " pc1_ip

# Receive file from PC1
echo "Waiting to receive file from PC1..."
receive_file

# Send confirmation back to PC1
echo "Sending confirmation to PC1..."
send_confirmation $pc1_ip

echo "File received and confirmation sent"

# Clean up
rm received_file
