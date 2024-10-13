#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -p xbee_port -s xbee_net_src_ip -d xbee_net_dst_ip"
    echo "  -p xbee_port          The serial port where the XBee is connected (e.g., /dev/ttyUSB0)"
    echo "  -s xbee_net_src_ip    The source IP address for the XBee network (e.g., 192.168.10.1)"
    echo "  -d xbee_net_dst_ip    The destination IP address to ping (e.g., 192.168.10.2)"
    exit 1
}

# Parse command-line arguments
while getopts "p:s:d:" opt; do
    case "$opt" in
        p) xbee_port=$OPTARG ;;
        s) xbee_net_src_ip=$OPTARG ;;
        d) xbee_net_dst_ip=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$xbee_port" ] || [ -z "$xbee_net_src_ip" ] || [ -z "$xbee_net_dst_ip" ]; then
    usage
fi

# Function to install dependencies, build xbnet, and configure the XBee network interface
run_as_root() {
    # Update package list and install necessary packages
    echo "Installing necessary packages..."
    apt-get update
    apt-get install -y git build-essential libudev-dev iproute2 iputils-ping cargo

    # Clone the xbnet repository
    echo "Cloning xbnet repository..."
    git clone https://github.com/jgoerzen/xbnet.git /usr/src/xbnet

    # Build xbnet
    echo "Building xbnet..."
    cd /usr/src/xbnet
    cargo build --release

    # Copy the built binary to /usr/local/bin
    echo "Installing xbnet..."
    cp target/release/xbnet /usr/local/bin/xbnet

    # Run xbnet in the background
    echo "Starting xbnet on $xbee_port..."
    xbnet $xbee_port tun &

    # Wait for the xbnet interface to be created
    echo "Waiting for xbnet0 interface to be created..."
    while ! ip link show xbnet0 > /dev/null 2>&1; do
        sleep 1
    done

    # Configure the XBee network interface
    echo "Configuring XBee network interface..."
    ip addr add $xbee_net_src_ip/24 dev xbnet0
    ip link set dev xbnet0 up

    # Ping the destination IP to verify connectivity
    echo "Pinging destination IP $xbee_net_dst_ip..."
    ping -c 4 $xbee_net_dst_ip

    echo "Setup complete. The XBee network interface is configured and tested."
}

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Re-running with sudo..."
    sudo bash -c "$(declare -f run_as_root); run_as_root" "$@"
    exit
else
    run_as_root
fi
