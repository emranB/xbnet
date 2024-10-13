#!/bin/bash

# create_tap_device.sh
#
# This script sets up an XBee network interface (xbnet) in tap mode. It creates a virtual Ethernet interface
# that runs over the XBee radio network, assigns it an IP address, and brings the interface up.
#
# Usage:
#   ./create_tap_device.sh --index=<int> --subnet=<value> --port=<device> --serial-speed=<baudrate>
#
# Examples:
#   ./create_tap_device.sh --index=1 --subnet=10.10.10 --port=/dev/ttyUSB0 --serial-speed=230400
#       - Creates a tap interface with IP 10.10.10.1 using /dev/ttyUSB0 at 230400 baudrate.
#
#   ./create_tap_device.sh --index=2 --subnet=192.168.2 --port=/dev/ttyUSB1 --serial-speed=115200
#       - Creates a tap interface with IP 192.168.2.2 using /dev/ttyUSB1 at 115200 baudrate.

# Default values
INDEX=1
SUBNET="10.10.10"
PORT="/dev/ttyUSB0"
SERIAL_SPEED=230400

export RUST_BACKTRACE=full

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --index=*)
        INDEX="${arg#*=}"
        shift # Remove --index=<int> from processing
        ;;
        --subnet=*)
        SUBNET="${arg#*=}"
        shift # Remove --subnet=<value> from processing
        ;;
        --port=*)
        PORT="${arg#*=}"
        shift # Remove --port=<value> from processing
        ;;
        --serial-speed=*)
        SERIAL_SPEED="${arg#*=}"
        shift # Remove --serial-speed=<value> from processing
        ;;
        *)
        echo "Invalid argument: $arg"
        exit 1
        ;;
    esac
done

# Assign IP and interface name
IP="${SUBNET}.${INDEX}"
IFACE_NAME="xbnet${INDEX}"

# Run xbnet command
echo "Starting xbnet on ${PORT} with IP ${IP} on interface ${IFACE_NAME}"
xbnet -d --serial-speed ${SERIAL_SPEED} ${PORT} tap --iface-name ${IFACE_NAME} &

# Wait until the interface is created and up
echo "Waiting for interface ${IFACE_NAME} to be up..."
while ! ip link show ${IFACE_NAME} > /dev/null 2>&1; do
    sleep 1
done

# Assign IP address to the interface
sudo ip addr add ${IP}/24 dev ${IFACE_NAME}
sudo ip link set ${IFACE_NAME} up

echo "Interface ${IFACE_NAME} created with IP ${IP}"
