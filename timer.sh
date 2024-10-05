#!/bin/bash
#by Tech Logicals
# Function to display the ASCII art numbers
display_number() {
    local n=$1
    case $n in
        0) echo "  ████████  "
           echo "██        ██"
           echo "██        ██"
           echo "██        ██"
           echo "██        ██"
           echo "██        ██"
           echo "  ████████  ";;
        1) echo "     ██     "
           echo "   ████     "
           echo "     ██     "
           echo "     ██     "
           echo "     ██     "
           echo "     ██     "
           echo "   ██████   ";;
        2) echo " ██████████ "
           echo "         ██ "
           echo "         ██ "
           echo " ██████████ "
           echo "██          "
           echo "██          "
           echo " ██████████ ";;
        3) echo " ██████████ "
           echo "         ██ "
           echo "         ██ "
           echo "   ██████   "
           echo "         ██ "
           echo "         ██ "
           echo " ██████████ ";;
        4) echo "██      ██  "
           echo "██      ██  "
           echo "██      ██  "
           echo " ██████████ "
           echo "        ██  "
           echo "        ██  "
           echo "        ██  ";;
        5) echo " ██████████ "
           echo "██          "
           echo "██          "
           echo " ██████████ "
           echo "         ██ "
           echo "         ██ "
           echo " ██████████ ";;
        6) echo " ██████████ "
           echo "██          "
           echo "██          "
           echo " ██████████ "
           echo "██        ██"
           echo "██        ██"
           echo " ██████████ ";;
        7) echo " ██████████ "
           echo "         ██ "
           echo "        ██  "
           echo "       ██   "
           echo "      ██    "
           echo "     ██     "
           echo "    ██      ";;
        8) echo " ██████████ "
           echo "██        ██"
           echo "██        ██"
           echo " ██████████ "
           echo "██        ██"
           echo "██        ██"
           echo " ██████████ ";;
        9) echo " ██████████ "
           echo "██        ██"
           echo "██        ██"
           echo " ██████████ "
           echo "         ██ "
           echo "         ██ "
           echo " ██████████ ";;
    esac
}

# Function to display the timer
display_timer() {
    local minutes=$1
    local seconds=$2

    clear
    echo "Time remaining:"
    echo
    display_number $((minutes/10))
    echo
    display_number $((minutes%10))
    echo
    echo "     ██     "
    echo "     ██     "
    echo "            "
    echo "     ██     "
    echo "     ██     "
    echo
    display_number $((seconds/10))
    echo
    display_number $((seconds%10))
}

# Main script
echo "Enter the timer duration in seconds:"
read duration

total_seconds=$duration

while [ $total_seconds -ge 0 ]; do
    minutes=$((total_seconds / 60))
    seconds=$((total_seconds % 60))
    
    display_timer $minutes $seconds
    
    sleep 1
    ((total_seconds--))
done

echo "Time's up!"

