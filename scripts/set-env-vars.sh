#!/bin/bash

# set-env-vars.sh
#
# This script sets up the environment for running a Docker Compose configuration with XBee networks.

# Export the values set in the Docker Compose environment
export XBEE_INDEX=${XBEE_INDEX}
export XBEE_BAUDRATE=${XBEE_BAUDRATE}
export XBEE_PORT=${XBEE_PORT}
export XBNET_BASE_SUBNET=${XBNET_BASE_SUBNET}
export XBNET_INTERFACE_TYPE=${XBNET_INTERFACE_TYPE}     # Options: ["gateway", "router"]
export XBNET_PROTO=tap                                  # Options: ["tap", "tun"]

# Determine the source IP based on interface type
if [ "$XBNET_INTERFACE_TYPE" = "gateway" ]; then
    XBNET_IP="${XBNET_BASE_SUBNET}.1"
    XBNET_INTERFACE_NAME="xbnet_gateway"
else
    XBNET_IP="${XBNET_BASE_SUBNET}.20${XBEE_INDEX}"
    XBNET_INTERFACE_NAME="xbnet_router_${XBEE_INDEX}"
fi

# Export the renamed variables
export XBNET_DEFAULT_GATEWAY="${XBNET_BASE_SUBNET}.1"
export XBNET_DEFAULT_IPVLAN_IP="${XBNET_BASE_SUBNET}.20"
export XBNET_DEFAULT_MACVLAN_IP="${XBNET_BASE_SUBNET}.30"
export XBNET_IP
export XBNET_INTERFACE_NAME

# Print out environment variables
print_env_vars() {
    echo "***********************************************************"
    echo "Environment variables set. "
    echo "XBEE_INDEX                : ${XBEE_INDEX}"
    echo "XBEE_BAUDRATE             : ${XBEE_BAUDRATE}"
    echo "XBEE_PORT                 : ${XBEE_PORT}"
    echo "XBNET_BASE_SUBNET         : ${XBNET_BASE_SUBNET}"
    echo "XBNET_IP                  : ${XBNET_IP}"
    echo "XBNET_INTERFACE_NAME      : ${XBNET_INTERFACE_NAME}"
    echo "XBNET_DEFAULT_IPVLAN_IP   : ${XBNET_DEFAULT_IPVLAN_IP}"
    echo "XBNET_DEFAULT_MACVLAN_IP  : ${XBNET_DEFAULT_MACVLAN_IP}"
    echo "***********************************************************"
}

# print_env_vars


