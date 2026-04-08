#!/bin/bash

# --- 1. Validate Parameters ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <NODE_IP>"
    echo "Example: $0 192.168.133.1"
    exit 1
fi

MY_COMPUTE_IP=$1

# --- 2. Define Service Passwords ---
# Ensure these match the values defined in Chapter 1 
RABBIT_PASS="<RABBIT_PASS>"
NOVA_PASS="<NOVA_PASS>"
PLACEMENT_PASS="<PLACEMENT_PASS>"
NEUTRON_PASS="<NEUTRON_PASS>"

# --- 3. Chrony Configuration ---
echo "Configuring Chrony..."
# Appends the server line to the end of the file using sed 
sudo sed -i '$a server controller iburst' /etc/chrony/chrony.conf
sudo systemctl restart chrony

# --- 4. Nova Configuration ---
echo "Configuring /etc/nova/nova.conf..."
NOVA_CONF="/etc/nova/nova.conf"

# [DEFAULT] section 
sudo sed -i "/^\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@controller\nmy_ip = $MY_COMPUTE_IP" $NOVA_CONF

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
server_proxyclient_address = \$MY_COMPUTE_IP\n\
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

sudo ovs-vsctl add-br br-provider 
sudo ovs-vsctl add-port br-provider <interface de datos 
sudo systemctl restart nova-compute 
sudo systemctl restart neutron-openvswitch-agent

echo "Configuration for $MY_COMPUTE_IP is complete."
