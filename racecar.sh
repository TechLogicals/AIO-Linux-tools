#!/bin/bash

clear

# Define the racetrack
track=(
    "  ┌────────────────┐  "
    "  │                │  "
    "  │                │  "
    "  │                │  "
    "  │                │  "
    "  └────────────────┘  "
)

# Define the car
car="🏎️ "

# Function to display the track and car
display() {
    clear
    for ((i=0; i<${#track[@]}; i++)); do
        if [ $i -eq $1 ]; then
            echo "${track[$i]:0:$2}$car${track[$i]:$2+1}"
        else
            echo "${track[$i]}"
        fi
    done
}

# Animation loop
while true; do
    for ((i=1; i<=18; i++)); do
        display 1 $i
        sleep 0.1
    done
    for ((i=2; i<=4; i++)); do
        display $i 18
        sleep 0.1
    done
    for ((i=17; i>=1; i--)); do
        display 4 $i
        sleep 0.1
    done
    for ((i=3; i>=2; i--)); do
        display $i 1
        sleep 0.1
    done
done