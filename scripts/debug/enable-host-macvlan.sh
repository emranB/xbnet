#!/bin/bash

# enable_host_macvlan.sh
# 
# This script enables IP forwarding, deletes any existing `macvlan0` interface, and creates a new `macvlan0` interface
# on the dynamically detected Wi-Fi interface. It allows the Docker container to have its own IP address on the local subnet.
#
# Usage:
#   ./enable_host_macvlan.sh
#
# The script will automatically determine the Wi-Fi interface name and assign an IP address to the `macvlan0` interface.
# Modify the assigned IP address if your network setup differs.

# Source the get_connected_wifi_info.sh script to use its functions
source ./get_connected_wifi_info.sh

# Get the Wi-Fi interface name dynamically
WIFI_DEVICE=$(get_connected_wifi_device)

# Check if a Wi-Fi device was found
if [ -z "$WIFI_DEVICE" ]; then
    echo "Error: No connected Wi-Fi device found. Exiting..."
    exit 1
fi

# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1

# Delete the existing macvlan0 interface if it exists
if ip link show macvlan0 &> /dev/null; then
    echo "Deleting existing macvlan0 interface..."
    sudo ip link delete macvlan0
fi

# Create a new macvlan0 interface linked to the detected Wi-Fi interface
echo "Creating macvlan0 interface on $WIFI_DEVICE..."
sudo ip link add link $WIFI_DEVICE macvlan0 type macvlan mode bridge

# Assign an IP address to the macvlan0 interface (ensure it’s unique within your network)
sudo ip addr add 192.168.1.100/24 dev macvlan0

# Bring the macvlan0 interface up
sudo ip link set macvlan0 up

echo "macvlan0 interface created and set up successfully on $WIFI_DEVICE."
