#!/bin/bash

# --- 1. Configuration Variables ---
# Ensure these match your Chapter 1 & 2 settings
CONTROLLER_IP="<ip_controlador>"
RABBIT_PASS="<RABBIT_PASS>"
METADATA_SECRET="<METADATA_SECRET>"
GLANCE_ENDPOINT_ID="<glance_endpoint_id>" # Captured from the Keystone script

# Database Passwords
GLANCE_DBPASS="<GLANCE_DBPASS>"
PLACEMENT_DBPASS="<PLACEMENT_DBPASS>"
NOVA_DBPASS="<NOVA_DBPASS>"
NEUTRON_DBPASS="<NEUTRON_DBPASS>"

# Service User Passwords
GLANCE_PASS="<GLANCE_PASS>"
PLACEMENT_PASS="<PLACEMENT_PASS>"
NOVA_PASS="<NOVA_PASS>"
NEUTRON_PASS="<NEUTRON_PASS>"

# --- 2. Glance (Image Service) Configuration --- 
echo "Configuring Glance..."
GLANCE_CONF="/etc/glance/glance-api.conf"
sudo sed -i "/^\[DEFAULT\]/a enabled_backends=fs:file" $GLANCE_CONF 
sudo sed -i "s|^#connection =.*|connection = mysql+pymysql://glance:$GLANCE_DBPASS@controller/glance|" $GLANCE_CONF 

# Keystone Authentication 
sudo sed -i "/^\[keystone_authtoken\]/a \
www_authenticate_uri = http://controller:5000\n\
auth_url = http://controller:5000\n\
memcached_servers = controller:11211\n\
auth_type = password\n\
project_domain_name = Default\n\
user_domain_name = Default\n\
project_name = service\n\
username = glance\n\
password = $GLANCE_PASS" $GLANCE_CONF

sudo sed -i "s|^#flavor =.*|flavor = keystone|" $GLANCE_CONF 

# Backend Store 
sudo sed -i "/^\[glance_store\]/a default_backend = fs" $GLANCE_CONF
sudo sed -i "/^\[fs\]/a filesystem_store_datadir = /var/lib/glance/images/" $GLANCE_CONF

# Oslo Limit 
sudo sed -i "/^\[oslo_limit\]/a \
auth_url = http://controller:5000\n\
auth_type = password\n\
user_domain_id = default\n\
username = glance\n\
system_scope = all\n\
password = $GLANCE_PASS\n\
endpoint_id = $GLANCE_ENDPOINT_ID\n\
region_name = RegionOne" $GLANCE_CONF

# --- 3. Placement Configuration --- 
echo "Configuring Placement..."
PLACE_CONF="/etc/placement/placement.conf"
sudo sed -i "s|^#connection =.*|connection = mysql+pymysql://placement:$PLACEMENT_DBPASS@controller/placement|" $PLACE_CONF 
sudo sed -i "/^\[api\]/a auth_strategy = keystone" $PLACE_CONF 
sudo sed -i "/^\[keystone_authtoken\]/a \
auth_url = http://controller:5000/v3\n\
memcached_servers = controller:11211\n\
auth_type = password\n\
project_domain_name = Default\n\
user_domain_name = Default\n\
project_name = service\n\
username = placement\n\
password = $PLACEMENT_PASS" $PLACE_CONF 

# --- 4. Nova (Compute) Configuration --- 
echo "Configuring Nova..."
NOVA_CONF="/etc/nova/nova.conf"
sudo sed -i "/^log_dir =/d" $NOVA_CONF 
sudo sed -i "/^\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@controller:5672/\nmy_ip = $CONTROLLER_IP" $NOVA_CONF 

# Databases 
sudo sed -i "s|^connection = sqlite.*|connection = mysql+pymysql://nova:$NOVA_DBPASS@controller/nova_api|" $NOVA_CONF # For api_database
sudo sed -i "/^\[database\]/,/^\[/ s|^connection =.*|connection = mysql+pymysql://nova:$NOVA_DBPASS@controller/nova|" $NOVA_CONF

# Keystone & Service User 
sudo sed -i "/^\[keystone_authtoken\]/a \
www_authenticate_uri = http://controller:5000/\n\
auth_url = http://controller:5000/\n\
memcached_servers = controller:11211\n\
auth_type = password\n\
project_domain_name = Default\n\
user_domain_name = Default\n\
project_name = service\n\
username = nova\n\
password = $NOVA_PASS" $NOVA_CONF

# VNC & Placement & Neutron Integration 
sudo sed -i "/^\[vnc\]/a enabled = true\nserver_listen = \$my_ip\nserver_proxyclient_address = \$my_ip" $NOVA_CONF
sudo sed -i "/^\[glance\]/a api_servers = http://controller:9292" $NOVA_CONF
sudo sed -i "/^\[oslo_concurrency\]/a lock_path = /var/lib/nova/tmp" $NOVA_CONF
sudo sed -i "/^\[placement\]/a region_name = RegionOne\nproject_domain_name = Default\nproject_name = service\nauth_type = password\nuser_domain_name = Default\nauth_url = http://controller:5000/v3\nusername = placement\npassword = $PLACEMENT_PASS" $NOVA_CONF
sudo sed -i "/^\[neutron\]/a \
auth_url = http://controller:5000\n\
auth_type = password\n\
project_domain_name = Default\n\
user_domain_name = Default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $NEUTRON_PASS\n\
service_metadata_proxy = true\n\
metadata_proxy_shared_secret = $METADATA_SECRET" $NOVA_CONF

# --- 5. Neutron (Networking) Configuration --- 
echo "Configuring Neutron..."
NEUT_CONF="/etc/neutron/neutron.conf"
sudo sed -i "/^\[DEFAULT\]/a \
core_plugin = ml2\n\
service_plugins = router\n\
transport_url = rabbit://openstack:$RABBIT_PASS@controller\n\
auth_strategy = keystone\n\
notify_nova_on_port_status_changes = true\n\
notify_nova_on_port_data_changes = true\n\
dhcp_agents_per_network = 2" $NEUT_CONF 

sudo sed -i "s|^connection = sqlite.*|connection = mysql+pymysql://neutron:$NEUTRON_DBPASS@controller/neutron|" $NEUT_CONF 

# ML2 Plugin 
ML2_CONF="/etc/neutron/plugins/ml2/ml2_conf.ini"
sudo sed -i "/^\[ml2\]/a type_drivers = flat,vlan,vxlan\ntenant_network_types = vxlan\nmechanism_drivers = openvswitch,l2population\nextension_drivers = port_security" $ML2_CONF
sudo sed -i "/^\[ml2_type_flat\]/a flat_networks = provider" $ML2_CONF
sudo sed -i "/^\[ml2_type_vlan\]/a network_vlan_ranges = provider" $ML2_CONF
sudo sed -i "/^\[ml2_type_vxlan\]/a vni_ranges = 1:1000" $ML2_CONF

# Agents 
echo "Configuring Neutron Agents..."
sudo sed -i "/^\[ovs\]/a bridge_mappings = provider:br-provider\nlocal_ip = $CONTROLLER_IP" /etc/neutron/plugins/ml2/openvswitch_agent.ini
sudo sed -i "/^\[agent\]/a tunnel_types = vxlan\nl2_population = true" /etc/neutron/plugins/ml2/openvswitch_agent.ini
sudo sed -i "/^\[securitygroup\]/a enable_security_group = true\nfirewall_driver = openvswitch" $OVS_AGENT_CONF
sudo sed -i "/^\[DEFAULT\]/a interface_driver = openvswitch\ndhcp_driver = neutron.agent.linux.dhcp.Dnsmasq\nenable_isolated_metadata = true" /etc/neutron/dhcp_agent.ini
sudo sed -i "/^\[DEFAULT\]/a nova_metadata_host = controller\nmetadata_proxy_shared_secret = $METADATA_SECRET" /etc/neutron/metadata_agent.ini

echo "Core services configuration complete."
