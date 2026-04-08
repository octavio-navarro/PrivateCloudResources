#!/bin/bash

# --- 1. Configuration Variables ---
# Ensure these match your Chapter 1 & 2 settings
CONTROLLER_IP="<ip_controlador>"
ADMIN_PASS="<ADMIN_PASS>"
KEYSTONE_DBPASS="<KEYSTONE_DBPASS>"
GLANCE_PASS="<GLANCE_PASS>"
PLACEMENT_PASS="<PLACEMENT_PASS>"
NOVA_PASS="<NOVA_PASS>"
NEUTRON_PASS="<NEUTRON_PASS>"

# --- 2. Configure Keystone --- 
echo "Configuring keystone.conf and Apache..."
sudo sed -i "s|^#connection =.*|connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@controller/keystone|" /etc/keystone/keystone.conf
sudo sed -i "s|^#provider =.*|provider = fernet|" /etc/keystone/keystone.conf

# Add ServerName to Apache
if ! grep -q "ServerName controller" /etc/apache2/apache2.conf; then
    echo "ServerName controller" | sudo tee -a /etc/apache2/apache2.conf
fi

# --- 3. Initialize Database and Services --- 
echo "Initializing Keystone database and bootstrapping..."
sudo keystone-manage db_sync
sudo systemctl restart apache2
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

sudo keystone-manage bootstrap --bootstrap-password "$ADMIN_PASS" \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# --- 4. Export Environment Variables --- 
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD="$ADMIN_PASS"
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

# --- 5. Create Service Project and Users --- 
echo "Creating service project and users..."
openstack project create --domain default --description "Service Project" service

# Create Users
openstack user create --domain default --password "$GLANCE_PASS" glance
openstack user create --domain default --password "$PLACEMENT_PASS" placement
openstack user create --domain default --password "$NOVA_PASS" nova
openstack user create --domain default --password "$NEUTRON_PASS" neutron

# Add Admin Roles
openstack role add --project service --user glance admin
openstack role add --user glance --user-domain Default --system all reader
openstack role add --project service --user placement admin
openstack role add --project service --user nova admin
openstack role add --project service --user neutron admin

# --- 6. Create Services and Endpoints --- 
echo "Registering services and creating endpoints..."


# Image Service (Glance)
openstack service create --name glance --description "OpenStack Image" image
GLANCE_ENDPOINT_ID=$(openstack endpoint create --region RegionOne image public http://controller:9292 -f value -c id)
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# Placement Service
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

# Compute Service (Nova)
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

# Network Service (Neutron)
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

echo "Keystone initialization and service registry complete."

echo "------------------------------------------------------------"
echo "Keystone initialization and service registry complete."
echo "CRITICAL NOTE: As per your instructions, save this ID:"
echo "GLANCE_ENDPOINT_ID: $GLANCE_ENDPOINT_ID"
echo "You will need this value for the Glance configuration in Chapter 4."
echo "------------------------------------------------------------"
