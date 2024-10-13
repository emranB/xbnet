#!/bin/sh -e
# IP forwarding and NAT rules

# Default host IP
HOST_IP=""

# Parse command line argument for --host-ip
for arg in "$@"; do
    case $arg in
        --host-ip=*)
        HOST_IP="${arg#*=}"
        shift
        ;;
        *)
        echo "Unknown argument: $arg"
        exit 1
        ;;
    esac
done

# If HOST_IP is not set, fetch the IP address of the eth0 interface
if [ -z "$HOST_IP" ]; then
    HOST_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -z "$HOST_IP" ]; then
        echo "Error: Could not retrieve IP from eth0"
        exit 1
    fi
    echo "No --host-ip provided. Using eth0 IP: $HOST_IP"
else
    echo "Using provided --host-ip: $HOST_IP"
fi

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set iptables rules for NAT and forwarding
iptables -t nat -A POSTROUTING -s 2.2.2.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -i xbnet_router_1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o xbnet_router_1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Ensure the xbnet_router_1 interface has a default route through eth0
ip route add default via $(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') dev xbnet_router_1

exit 0
