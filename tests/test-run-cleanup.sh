#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -p xbee_port"
    echo "  -p xbee_port          The serial port where the XBee is connected (e.g., /dev/ttyUSB0)"
    exit 1
}

# Parse command-line arguments
while getopts "p:" opt; do
    case "$opt" in
        p) xbee_port=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [ -z "$xbee_port" ]; then
    usage
fi

# Find the xbnet interface created by xbnet
xbnet_interface=$(ip link show | grep -o 'xbnet[0-9]*')

# Remove the IP address and bring down the network interface
if [ -n "$xbnet_interface" ]; then
    echo "Removing IP address from $xbnet_interface..."
    sudo ip addr flush dev $xbnet_interface

    echo "Bringing down the network interface $xbnet_interface..."
    sudo ip link set dev $xbnet_interface down

    echo "Removing the network interface $xbnet_interface..."
    sudo ip link delete $xbnet_interface
else
    echo "No xbnet interface found."
fi

# Remove the xbnet binary
if [ -f /usr/local/bin/xbnet ]; then
    echo "Removing xbnet binary..."
    sudo rm /usr/local/bin/xbnet
else
    echo "xbnet binary not found."
fi

# Remove the cloned xbnet repository
if [ -d /usr/src/xbnet ]; then
    echo "Removing the cloned xbnet repository..."
    sudo rm -rf /usr/src/xbnet
else
    echo "xbnet repository not found."
fi

echo "Cleanup complete."
