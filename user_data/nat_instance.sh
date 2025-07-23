#!/bin/bash

exec > >(tee /var/log/nat-instance-setup.log)
exec 2>&1

echo "Starting NAT instance configuration..."

yum update -y

yum install -y iptables-services

systemctl enable iptables
systemctl start iptables

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/custom-ip-forwarding.conf

sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

INTERFACE=$(ip route get 8.8.8.8 | head -1 | awk '{print $5}')
echo "Primary network interface: $INTERFACE"

iptables -F
iptables -t nat -F

iptables -P FORWARD DROP

iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -s 10.0.0.0/8 -j ACCEPT
iptables -A FORWARD -s 172.16.0.0/12 -j ACCEPT  
iptables -A FORWARD -s 192.168.0.0/16 -j ACCEPT

iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

service iptables save

echo "IP forwarding status:"
sysctl net.ipv4.ip_forward

echo "NAT rules:"
iptables -t nat -L -n -v

echo "Filter rules:"
iptables -L -n -v

echo "NAT instance configuration completed successfully!"

echo "NAT instance configured on $(date)" > /var/log/nat-instance-status.txt 