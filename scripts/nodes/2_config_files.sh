#!/bin/bash

# --- 1. Validate Parameters ---
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <NODE_IP> <RABBIT_PASS> <NOVA_PASS> <PLACEMENT_PASS> <NEUTRON_PASS>"
    echo "Example: sudo $0 192.168.133.1 rabbit123 nova123 place123 neut123"
    exit 1
fi

# Assigning parameters to variables
MY_COMPUTE_IP=$1
RABBIT_PASS=$2
NOVA_PASS=$3
PLACEMENT_PASS=$4
NEUTRON_PASS=$5

# --- 2. Request Data Interface ---
read -p "Enter the name of the Data Interface (interfaz de datos): " DATA_INT

if [ -z "$DATA_INT" ]; then
    echo "------------------------------------------------------------"
    echo "HINT: You can find your network interfaces by running:"
    echo "      ip link show"
    echo "Look for a secondary interface (e.g., eth1, ens4) that DOES NOT"
    echo "have your management IP ($MY_COMPUTE_IP) assigned to it."
    echo "------------------------------------------------------------"
    read -p "Please enter the interface name now: " DATA_INT
fi

# Exit if still empty
if [ -z "$DATA_INT" ]; then echo "Error: Data interface is required. Exiting."; exit 1; fi

echo "Creating backups of configuration files..."
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak 
sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.bak 
sudo cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak 
sudo cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak 

echo "Updating Netplan for $DATA_INT..."
# This sed command finds 'ethernets:' and appends the new interface with 4 spaces of indentation
sudo sed -i "/  ethernets:/a \    $DATA_INT: {}" /etc/netplan/50-cloud-init.yaml

# Apply the netplan changes immediately
sudo netplan apply

# --- 3. Chrony Configuration ---
echo "Configuring Chrony..."
# Appends the server line to the end of the file using sed 
sudo sed -i '$a server controller iburst' /etc/chrony/chrony.conf
sudo systemctl restart chrony

# --- 4. Nova Configuration ---
echo "Configuring /etc/nova/nova.conf..."
NOVA_CONF="/etc/nova/nova.conf"

# [DEFAULT] section 
sudo sed -i "/^\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@controller:5672\nmy_ip = $MY_COMPUTE_IP" $NOVA_CONF

# [service_user] section 
sudo sed -i "/^\[service_user\]/a \
send_service_user_token = true\n\
auth_url = http://controller:5000/identity\n\
auth_type = password\n\
project_domain_name = Default\n\
project_name = service\n\
user_domain_name = Default\n\
username = nova\n\
password = $NOVA_PASS" $NOVA_CONF

# [vnc] section 
sudo sed -i "/^\[vnc\]/a \
enabled = true\n\
server_listen = 0.0.0.0\n\
server_proxyclient_address = $MY_COMPUTE_IP\n\
novncproxy_base_url = http://controller:6080/vnc_auto.html" $NOVA_CONF

# [oslo_concurrency] section 
sudo sed -i "/^\[oslo_concurrency\]/a lock_path = /var/lib/nova/tmp" $NOVA_CONF

# [placement] section 
sudo sed -i "/^\[placement\]/a \
region_name = RegionOne\n\
project_domain_name = Default\n\
project_name = service\n\
auth_type = password\n\
user_domain_name = Default\n\
auth_url = http://controller:5000/v3\n\
username = placement\n\
password = $PLACEMENT_PASS" $NOVA_CONF

# [neutron] section 
sudo sed -i "/^\[neutron\]/a \
auth_url = http://controller:5000\n\
auth_type = password\n\
project_domain_name = Default\n\
user_domain_name = Default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $NEUTRON_PASS" $NOVA_CONF

# --- 5. Neutron Configuration ---
echo "Configuring /etc/neutron/neutron.conf..."
NEUT_CONF="/etc/neutron/neutron.conf"
sudo sed -i "/^\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@controller" $NEUT_CONF 
# Commenting out the local sqlite connection as per instructions 
sudo sed -i "s|^connection = sqlite.*|# connection = sqlite:////var/lib/neutron/neutron.sqlite|" $NEUT_CONF
sudo sed -i "/^\[oslo_concurrency\]/a lock_path = /var/lib/neutron/tmp" $NEUT_CONF 

# --- 6. Open vSwitch Agent Configuration ---
echo "Configuring Open vSwitch Agent..."
OVS_AGENT_CONF="/etc/neutron/plugins/ml2/openvswitch_agent.ini"
sudo sed -i "/^\[ovs\]/a bridge_mappings = provider:br-provider\nlocal_ip = $MY_COMPUTE_IP" $OVS_AGENT_CONF 
sudo sed -i "/^\[agent\]/a tunnel_types = vxlan\nl2_population = true" $OVS_AGENT_CONF 
sudo sed -i "/^\[securitygroup\]/a enable_security_group = true\nfirewall_driver = openvswitch" $OVS_AGENT_CONF 

echo "Executing services..."

# --- Open vSwitch Initialization  ---
echo "Setting up OVS bridge 'br-provider' on $DATA_INT..."
sudo ovs-vsctl add-br br-provider
sudo ovs-vsctl add-port br-provider "$DATA_INT"

# --- 3. Restart Services  ---
echo "Restarting Compute and Networking services..."
sudo systemctl restart nova-compute 
sudo systemctl restart neutron-openvswitch-agent

echo "Configuration for $MY_COMPUTE_IP is complete."
