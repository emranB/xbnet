# XBNET

This project contains a Dockerized setup to create and manage an XBee network using the `xbnet` utility. The network interface is bridged with a host Wi-Fi interface, enabling internet access for connected devices.
##### Note: This project uses the `tap` xbnet protocol, which is a layer 2 protocol. This supports full ethernet pipeline. For a simple IP level protocol support, the `tun` xbnet protocol can be used. 

## File Structure
```bash
xbnet/
├── scripts/
│   ├── entrypoint.sh                   # Entrypoint script for Docker container
│   ├── get_connected_wifi_info.sh      # Script to fetch connected Wi-Fi device information
│   ├── health_check.sh                 # Script to perform health checks on the container
|   ├── debug/                          # Directory for testing-related scripts and files
│   |   ├── create_tap_device.sh        # Create a tap device directly on an OS 
│   |   ├── destroy_tap_device.sh       # Destroy a tap device directly on an OS 
│   |   ├── enable_host_macvlan.sh      # Destroy a tap device directly on an OS 
│   |   ├── host_setup.sh               # Script to set up Masquerade bridge docker0 network with active wifi 
│   |   ├── test.sh                     # Script to run tests
├── tests/                              # Directory for testing-related scripts and files
├── xbnet/                              # The xbnet source code directory
├── .env                                # Environment variables for the Docker setup
├── .gitignore                          # Git ignore file
├── docker-compose-run-multiple.yml     # Docker Compose file to run multiple instances
├── docker-compose.yml                  # Main Docker Compose file
├── Dockerfile                          # Dockerfile to build the Docker image
├── README.md                           # Project documentation
└── run-single.sh                       # Script to set up env vars and start a docker service with a single xbnet node
```

## Prerequisites

Ensure Docker and Docker Compose are installed on your machine.

## Getting Started

#### 1. Clone the Repository

```bash
git clone https://git.spirirobotics.com/Spiri/services-xbee_net
cd services-xbee_net
```

#### 2. To run the project in `PRODUCTION` mode, use the following cmd:

- `docker-compose -f docker-compose.yml up --build`

- Configure the project for user specs, modify the `docker-compose.yml` file for the following parameters:

    ```bash
    environment:
        - XBEE_INDEX=1
        - XBEE_BAUDRATE=230400
        - XBEE_PORT=/dev/ttyUSB0
        - XBNET_BASE_SUBNET=2.2.2
        - XBNET_INTERFACE_TYPE=router     # ["router" | "gateway"]
        - XBNET_PROTO=tap                 # ["tap" | "tun"]
    ```

- This can also be run using the `docker run` cmd shown below.

    ```bash
    docker run -d --name xbnet_node \
        --privileged \
        -e XBEE_INDEX=1 \
        -e XBEE_BAUDRATE=230400 \
        -e XBEE_PORT=/dev/ttyUSB0 \
        -e XBNET_BASE_SUBNET=2.2.2 \
        -e XBNET_INTERFACE_TYPE=router \
        -e XBNET_PROTO=tap \
        xbnet_node bash /entrypoint.sh
    ```

#### 3. To run a single xbnet node in `DEVELOPEMENT` mode, use the following cmd:

- Router mode:  `sh ./run-single.sh --subnet=7.7.7 --serial-speed=230400 --port=/dev/ttyUSB0 --interface-type=router`
- Gateway mode: `sh ./run-single.sh --subnet=7.7.7 --serial-speed=230400 --port=/dev/ttyUSB0 --interface-type=gateway`  

#### OR Manually build and Start the Docker Container
NOTE: This will require the config `.env` to be manually modified, based on user needs.

- Configure a single xbnet net service using:

    ```bash
    # Configuration for xbnet0
    XBEE_PORT=/dev/ttyUSB0
    XBEE_BAUDRATE=230400
    XBEE_NET_SRC_IP=192.168.1.100   # Ensure this IP matches the network range
    XBEE_NET_IFACE_NAME=xbnet0

    # Default Gateway
    DEFAULT_GATEWAY=192.168.1.1
    ```

#### 4. To run a multiple xbnet nodes in `DEVELOPEMENT` mode, use the following cmd:

- Router 1:  `sh ./run-multiple.sh --index=1 --subnet=7.7.7 --serial-speed=230400 --port=/dev/ttyUSB0 --interface-type=router`
- Router 2:  `sh ./run-multiple.sh --index=2 --subnet=7.7.7 --serial-speed=230400 --port=/dev/ttyUSB0 --interface-type=router`
- Gateway:   `sh ./run-multiple.sh --subnet=7.7.7 --serial-speed=230400 --port=/dev/ttyUSB0 --interface-type=gateway`  

NOTE: This will require the config `.env` to be manually modified, based on user needs.

- Configure multiple xbnet net services using:

    ```bash
    # Configuration for xbnet0 (REQUIRED: minimum config to run a single xbnet node)
    XBEE0_PORT=/dev/ttyUSB0               # The serial port for the XBee device
    XBEE0_BAUDRATE=230400                 # Baud rate for the XBee device
    XBEE0_NET_SRC_IP=192.168.1.100        # Source IP for the XBee network
    XBEE0_NET_IFACE_NAME=xbnet0           # Interface name for the XBee network

    # Configuration for xbnet1 (OPTIONAL: only required for multi node xbnets)
    XBEE1_PORT=/dev/ttyUSB1
    XBEE1_BAUDRATE=230400
    XBEE1_NET_SRC_IP=192.168.1.101
    XBEE1_NET_IFACE_NAME=xbnet1

    # Default Gateway (REQUIRED: part of minimum concifg to run a single xbnet node)
    DEFAULT_GATEWAY=192.168.1.1
    ```

This will build the Docker image and start the container with the XBee network and the required setup.

#### 5. Health Check and Container Management

The container includes a health check that pings the XBee network interface to ensure it is functioning properly. \
The container is configured to restart automatically if the health check fails.

#### 6. Troubleshooting

Ensure the XBee devices are connected to the correct serial ports.\
Verify the network interfaces using ip a inside the container.\
The container logs can be viewed using:

```bash
docker logs xbee_node
```