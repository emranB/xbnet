#!/bin/sh -e
# IP forwarding and NAT rules

iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o wlp0s20f3 -j MASQUERADE
iptables -A FORWARD -i wlp0s20f3 -o docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -o wlp0s20f3 -j ACCEPT

exit 0