#!/bin/bash

call_get_connected_wifi_name() {
    # Source the get_connected_wifi_info.sh script
    source ./scripts/get_connected_wifi_info.sh

    # Call the function to get the Wi-Fi name and capture the returned Wi-Fi name
    wifi_name=$(get_connected_wifi_name)

    # Print the captured Wi-Fi name if it is not empty
    if [ -n "$wifi_name" ]; then
        echo "Connected Wi-Fi SSID: $wifi_name"
    else
        echo "No connected Wi-Fi devices found."
    fi
}

call_get_connected_wifi_device() {
    # Source the get_connected_wifi_info.sh script
    source ./scripts/get_connected_wifi_info.sh

    # Call the function to get the Wi-Fi device and capture the returned Wi-Fi device
    wifi_device=$(get_connected_wifi_device)

    # Print the captured Wi-Fi device if it is not empty
    if [ -n "$wifi_device" ]; then
        echo "Connected Wi-Fi Device: $wifi_device"
    else
        echo "No connected Wi-Fi devices found."
    fi
}

# Call the functions
call_get_connected_wifi_name
call_get_connected_wifi_device
