#!/bin/bash

# Perform the health check by pinging the xbnet interface
# - If the xbnet0 interface is successfully created, we should be able to ping the assigned IP 
ping -c 1 "$XBEE_NET_SRC_IP" > /dev/null 2>&1

# Return the appropriate status based on ping success
if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
