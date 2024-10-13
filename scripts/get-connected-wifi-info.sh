# get_connected_wifi_info.sh
#
# Usage: eg. 
#   source ./get_connected_wifi_info.sh
#   wifi_device=$(get_connected_wifi_device)
#   wifi_name=$(get_connected_wifi_name)
#

#!/bin/bash

# get_connected_wifi_device()
# - Returns wifi device id, eg. wlp0s20f3
get_connected_wifi_device() {
    # Get the active Wi-Fi connections
    connections=$(nmcli -t -f DEVICE,TYPE,STATE device | grep -E '^.*:wifi:connected$' | cut -d: -f1)

    # Return the device name of the first connected Wi-Fi device, or an empty string if none are found
    if [ -z "$connections" ]; then
        echo ""
    else
        # Return the device name
        echo "$connections" | head -n 1
    fi
}

# get_connected_wifi_device()
# - Returns wifi device name, eg. spiri-field
get_connected_wifi_name() {
    # Get the device name of the first connected Wi-Fi device
    device=$(get_connected_wifi_device)

    # Return the SSID of the Wi-Fi device, or an empty string if none is found
    if [ -z "$device" ]; then
        echo ""
    else
        # Get the SSID (Wi-Fi name) for the connected device
        name=$(nmcli -t -f NAME,DEVICE connection show --active | grep -E "^.*:$device$" | cut -d: -f1)
        echo "$name"
    fi
}
