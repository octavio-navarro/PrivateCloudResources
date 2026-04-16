#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <HOSTNAME> <CONTROLLER_IP>"
    echo "Example: $0 computo1 192.168.133.100"
    exit 1
fi

NODE_HOSTNAME=$1
CONTROLLER_IP=$2

echo "Backing up /etc/hosts..."
sudo cp /etc/hosts /etc/hosts.bak 
sudo hostnamectl set-hostname "$NODE_HOSTNAME"

echo "Starting preparation for $NODE_HOSTNAME ..."

sudo hostnamectl set-hostname "$NODE_HOSTNAME"

# This adds the controller and the full range of compute nodes to ensure cluster resolution.
echo "Configuring /etc/hosts..."
sudo tee -a /etc/hosts <<EOF

# OpenStack Cluster Nodes
192.168.133.100 controller
192.168.133.1 computo1
192.168.133.2 computo2
192.168.133.3 computo3
192.168.133.4 computo4
192.168.133.5 computo5
192.168.133.6 computo6
192.168.133.7 computo7
192.168.133.8 computo8
192.168.133.9 computo9
192.168.133.10 computo10
192.168.133.11 computo11
192.168.133.12 computo13
192.168.133.13 computo13
192.168.133.14 computo14
192.168.133.15 computo15
192.168.133.16 computo16
192.168.133.17 computo17
192.168.133.18 computo18
192.168.133.19 computo19
192.168.133.20 computo20
192.168.133.21 computo21
192.168.133.22 computo22
192.168.133.23 computo23
192.168.133.24 computo24
192.168.133.25 computo25
192.168.133.26 computo26
192.168.133.27 computo27
192.168.133.28 computo28
192.168.133.29 computo29
192.168.133.30 computo30
EOF

echo "Updating system repositories..."
sudo apt update && sudo apt upgrade -y

echo "Installing Nova and Neutron agents..."
sudo apt install -y chrony nova-compute neutron-openvswitch-agent

echo "Verifying and configuring UFW..."

# Check if UFW is enabled
UFW_STATUS=$(sudo ufw status | grep "Status: active")

if [ -z "$UFW_STATUS" ]; then
    echo "UFW is not active. Enabling it now..."
    sudo ufw --force enable
fi

echo "Applying OpenStack service rules to UFW..."
# Apply specific requested rules
sudo ufw allow 65032
sudo ufw deny 22
sudo ufw allow from $CONTROLLER_IP to any port 5672 proto tcp

echo "Environment preparation for $NODE_HOSTNAME is complete."
