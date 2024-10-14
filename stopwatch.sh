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

# Function to display the stopwatch
display_stopwatch() {
    local minutes=$1
    local seconds=$2

    clear
    echo "Stopwatch:"
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
    echo
    echo "Press spacebar to stop"
}

# Main script
echo "Press Enter to start the stopwatch..."
read

total_seconds=0

# Set up non-blocking input
stty -echo
stty cbreak
stty -icanon

# Start the stopwatch
while true; do
    minutes=$((total_seconds / 60))
    seconds=$((total_seconds % 60))
    
    display_stopwatch $minutes $seconds
    
    if read -t 0.1 -N 1 input; then
        if [[ $input = " " ]]; then
            break
        fi
    fi
    
    ((total_seconds++))
    sleep 0.9
done

# Reset terminal settings
stty echo
stty icanon
stty -cbreak

clear
echo "Stopwatch stopped!"
echo "Total time: $minutes minutes and $seconds seconds"

