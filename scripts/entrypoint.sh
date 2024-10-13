#!/bin/bash

# entrypoint.sh
#
# This script is responsible for setting up and maintaining an XBee network interface within a Docker container.
# It checks if a device is connected to the specified port, creates a TAP network interface, and monitors the connection.
# If the device is disconnected, it cleans up and retries the connection process.
#
# Usage:
# - This script is intended to be run as the entrypoint for a Docker container.
# - Ensure that the script has executable permissions (`chmod +x entrypoint.sh`) before running it.

echo "Starting entrypoint.sh"

# Set associated env vars
echo "Setting associated environment variables. Calling /set-env-vars.sh"
source /set-env-vars.sh

# Start SSH in the background
echo "Starting SSH service..."
/usr/sbin/sshd

# Main loop
loop() {
    echo "Starting loop"
    while true; do
        # Check if the XBee device is connected
        check_device_port
        if [ $? -ne 0 ]; then
            echo "No XBee device found at $XBEE_PORT. Waiting for device connection..."
            cleanup
            continue
        fi

        # Check if the network interface is up
        check_network_state
        if [ $? -ne 0 ]; then
            echo "Network interface $XBNET_INTERFACE_NAME not found. Creating TAP interface..."
            create_tap_interface
        fi

        # Log messages sent and received over xbnet
        log_xbnet_messages
        
        sleep 0.5
    done
}

# Check if the XBee device is connected
check_device_port() {
    if [ -e "$XBEE_PORT" ]; then
        return 0
    else
        return 1
    fi
}

# Check if the network interface is up
check_network_state() {
    if ip link show $XBNET_INTERFACE_NAME > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Create a TAP network interface
create_tap_interface() {
    # Start xbnet and run it in the background 
    #   - eg. xbnet -d --serial-speed 230400 /dev/ttyUSB0 tap --iface-name=xbnet_router_1
    xbnet -d --serial-speed ${XBEE_BAUDRATE} ${XBEE_PORT} ${XBNET_PROTO} --iface-name ${XBNET_INTERFACE_NAME} &

    # Wait until the interface is created
    while ! check_network_state; do
        sleep 1
    done

    # Create and bring up xbnet interface
    ip route add default via 172.18.0.1 dev $XBNET_INTERFACE_NAME
    ip addr add $XBNET_IP/24 dev $XBNET_INTERFACE_NAME
    ip link set $XBNET_INTERFACE_NAME up
    ip link show $XBNET_INTERFACE_NAME
    ip addr show $XBNET_INTERFACE_NAME

    echo "---------------------------------------------------------"
    echo "************ ${XBNET_PROTO} interface created ************"
    echo "---------------------------------------------------------"
    echo "XBEE_INDEX                : ${XBEE_INDEX}"                
    echo "XBEE_BAUDRATE             : ${XBEE_BAUDRATE}"             
    echo "XBEE_PORT                 : ${XBEE_PORT}"                 
    echo "XBNET_BASE_SUBNET         : ${XBNET_BASE_SUBNET}"         
    echo "XBNET_IP                  : ${XBNET_IP}"                  
    echo "XBNET_INTERFACE_NAME      : ${XBNET_INTERFACE_NAME}"      
    echo "XBNET_PROTO               : ${XBNET_PROTO}"     
    echo "XBNET_DEFAULT_GATEWAY     : ${XBNET_DEFAULT_GATEWAY}"     
    echo "XBNET_DEFAULT_IPVLAN_IP   : ${XBNET_DEFAULT_IPVLAN_IP}"   
    echo "XBNET_DEFAULT_MACVLAN_IP  : ${XBNET_DEFAULT_MACVLAN_IP}"  
    echo "---------------------------------------------------------"
    return 0
}

# Function to log messages sent and received over xbnet
log_xbnet_messages() {
    echo "Monitoring messages on $XBNET_INTERFACE_NAME..."

    if [ -z "$XBNET_INTERFACE_NAME" ]; then
        echo "Error: $XBNET_INTERFACE_NAME is not set."
        return 1
    fi

    # Ensure the interface exists before proceeding
    if [ ! -d "/sys/class/net/$XBNET_INTERFACE_NAME" ]; then
        echo "Error: Network interface $XBNET_INTERFACE_NAME does not exist."
        return 1
    fi

    # Continuously monitor the interface for packet statistics
    while true; do
        RX_PACKETS_BEFORE=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/statistics/rx_packets)
        TX_PACKETS_BEFORE=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/statistics/tx_packets)

        sleep 0.5

        RX_PACKETS_AFTER=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/statistics/rx_packets)
        TX_PACKETS_AFTER=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/statistics/tx_packets)

        RX_DIFF=$((RX_PACKETS_AFTER - RX_PACKETS_BEFORE))
        TX_DIFF=$((TX_PACKETS_AFTER - TX_PACKETS_BEFORE))

        if [[ $RX_DIFF -gt 0 ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') - $RX_DIFF packets received on $XBNET_INTERFACE_NAME"
            log_packet_info "received"
        fi

        if [[ $TX_DIFF -gt 0 ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') - $TX_DIFF packets sent on $XBNET_INTERFACE_NAME"
            log_packet_info "sent"
        fi
    done
}

# Function to log detailed packet information
log_packet_info() {
    local direction=$1
    local ip_info

    # Example: Check /proc/net/arp for the associated IP and MAC addresses
    ip_info=$(ip -br addr show $XBNET_INTERFACE_NAME)
    src_ip=$(echo "$ip_info" | awk '{print $3}' | cut -d '/' -f 1)
    src_mac=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/address)

    dst_info=$(ip neigh show dev $XBNET_INTERFACE_NAME | grep -v REACHABLE | head -n 1)
    dst_ip=$(echo "$dst_info" | awk '{print $1}')
    dst_mac=$(echo "$dst_info" | awk '{print $5}')

    echo "******************************************************************"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Packet $direction on $XBNET_INTERFACE_NAME"
    echo "Src: { IP: $src_ip, MAC: $src_mac }"
    echo "Dst: { IP: $dst_ip, MAC: $dst_mac }"

    # Log packet length and a placeholder for payload (real payload extraction requires deep packet inspection)
    length=$(cat /sys/class/net/$XBNET_INTERFACE_NAME/statistics/tx_bytes)
    echo "Length: ${length} bytes"

    # # Placeholder for payload (not feasible to extract without raw packet inspection)
    # echo "Payload: [Payload extraction requires raw packet inspection tools]"
    # echo "******************************************************************"
}


# Clean up resources and exit the script
cleanup() {
    echo "Cleaning up resources..."
    pkill -f "xbnet -d --serial-speed $XBEE_BAUDRATE $XBEE_PORT tap"

    if ip link show $XBNET_INTERFACE_NAME > /dev/null 2>&1; then
        ip link set $XBNET_INTERFACE_NAME down
        ip link delete $XBNET_INTERFACE_NAME
    fi
}

# Trap signals to clean up properly
trap cleanup EXIT

# Start the loop to monitor the network and device
loop
