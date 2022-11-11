#!/bin/bash

echo 1 > /proc/sys/net/ipv4/ip_forward


iptables -t nat -A POSTROUTING -s 2.2.0.0/24 -o ens192 -j SNAT --to-source 192.168.3.253
iptables -t nat -A PREROUTING -i ens33 -d 192.168.42.3 -p tcp --dport 2200 -j DNAT --to 2.2.0.2:22
iptables -t nat -A PREROUTING -i ens33 -d 192.168.42.3 -p tcp --dport 2201 -j DNAT --to 2.2.0.3:22
