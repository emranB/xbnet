#!/bin/bash

# kill_tap_device.sh
#
# This script stops and cleans up resources for an XBee network interface (xbnet) in tap mode.
# It terminates the xbnet process, removes the virtual Ethernet interface, and releases associated resources.
#
# Usage:
#   ./kill_tap_device.sh --index=<int>
#
# Example:
#   ./kill_tap_device.sh --index=1  # Terminates and cleans up resources for xbnet1

# Default value
INDEX=1

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --index=*)
        INDEX="${arg#*=}"
        shift # Remove --index=<int> from processing
        ;;
        *)
        echo "Invalid argument: $arg"
        exit 1
        ;;
    esac
done

# Define interface name
IFACE_NAME="xbnet${INDEX}"

# Terminate xbnet process associated with the interface
echo "Stopping xbnet on interface ${IFACE_NAME}..."
pkill -f "xbnet .* --iface-name ${IFACE_NAME}"

# Wait for the interface to go down
echo "Waiting for interface ${IFACE_NAME} to go down..."
while ip link show ${IFACE_NAME} > /dev/null 2>&1; do
    sleep 1
done

# Clean up the interface
echo "Cleaning up interface ${IFACE_NAME}..."
sudo ip link delete ${IFACE_NAME}

echo "Interface ${IFACE_NAME} and associated resources cleaned up successfully."
