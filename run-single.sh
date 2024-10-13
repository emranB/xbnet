#!/bin/bash

# run-single.sh
#
# This script sets up the environment for running a Docker Compose configuration with XBee networks.
# It accepts optional --index=<int>, --subnet=<subnet>, --serial-speed=<speed>, --port=<port>, and --interface-type=<type> arguments
# to specify the XBEE_INDEX, XBNET_BASE_SUBNET, XBEE_BAUDRATE, XBEE_PORT, and XBNET_INTERFACE_TYPE values. 
# If no index is provided, it defaults to 1. If no subnet is provided, it defaults to 10.10.10.
# If no serial-speed is provided, it defaults to 230400. If no port is provided, it defaults to /dev/ttyUSB0.
# If no interface-type is provided, it defaults to "router".
#
# Usage:
#   ./run-single.sh                                             # Runs with default index (1), default subnet (10.10.10), default speed (230400), and default port (/dev/ttyUSB0)
#   ./run-single.sh --index=2                                   # Runs with index 2 and default values for other options
#   ./run-single.sh --subnet=192.168.50                         # Runs with default index (1), specified subnet, and default values for other options
#   ./run-single.sh --index=3 --subnet=192.168.50               # Runs with specified index, specified subnet, and default values for speed and port
#   ./run-single.sh --serial-speed=115200 --port=/dev/ttyUSB1   # Runs with specified serial-speed and port with default values for other options
#   ./run-single.sh --interface-type=gateway                    # Runs with specified interface type as gateway

# Default values
XBEE_INDEX=1
XBNET_BASE_SUBNET="10.10.10"
XBEE_BAUDRATE=230400
XBEE_PORT="/dev/ttyUSB0"
XBNET_INTERFACE_TYPE="router"    # Options: ["gateway", "router"]

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --index=*)
        XBEE_INDEX="${arg#*=}"
        shift 
        ;;
        --subnet=*)
        XBNET_BASE_SUBNET="${arg#*=}"
        shift 
        ;;
        --serial-speed=*)
        XBEE_BAUDRATE="${arg#*=}"
        shift 
        ;;
        --port=*)
        XBEE_PORT="${arg#*=}"
        shift 
        ;;
        --interface-type=*)
        XBNET_INTERFACE_TYPE="${arg#*=}"
        shift 
        ;;
        *)
        ;;
    esac
done

# Determine the source IP based on interface type
if [ "$XBNET_INTERFACE_TYPE" = "gateway" ]; then
    XBNET_IP="${XBNET_BASE_SUBNET}.1"
    XBNET_INTERFACE_NAME="xbnet_gateway"
else
    XBNET_IP="${XBNET_BASE_SUBNET}.20${XBEE_INDEX}"
    XBNET_INTERFACE_NAME="xbnet_router_${XBEE_INDEX}"
fi

# Create a .env file with the specified parameters
cat <<EOF > .env
# Base params
XBNET_BASE_SUBNET=${XBNET_BASE_SUBNET}
XBEE_INDEX=${XBEE_INDEX}

# Default params
XBNET_DEFAULT_GATEWAY=${XBNET_BASE_SUBNET}.1
XBNET_DEFAULT_IPVLAN_IP=${XBNET_BASE_SUBNET}.20    # Required only when running ipvlan net (look in docker compose)
XBNET_DEFAULT_MACVLAN_IP=${XBNET_BASE_SUBNET}.30   # Required only when running macvlan net (look in docker compose)

# Configuration for xbnet
XBEE_PORT=${XBEE_PORT}
XBEE_BAUDRATE=${XBEE_BAUDRATE}
XBNET_IP=${XBNET_IP}              # Set based on interface type
XBNET_INTERFACE_NAME=${XBNET_INTERFACE_NAME}      # Set based on interface type
EOF

# Restart Docker Compose services
docker compose -f docker-compose-run-single.yml down
docker compose -f docker-compose-run-single.yml up --build
