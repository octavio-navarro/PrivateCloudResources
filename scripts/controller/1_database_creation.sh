#!/bin/bash

# --- 1. Define Service Database Passwords ---
# Replace these with the actual passwords defined in your variables table
KEYSTONE_DBPASS="your_keystone_pass"
GLANCE_DBPASS="your_glance_pass"
PLACEMENT_DBPASS="your_placement_pass"
NOVA_DBPASS="your_nova_pass"
NEUTRON_DBPASS="your_neutron_pass"

# --- 2. Execute SQL Commands ---
# This script assumes you are running it on the controller node with root MySQL access.
sudo mysql -u root <<EOF

-- Keystone Database
DROP DATABASE IF EXISTS keystone;
CREATE DATABASE IF NOT EXISTS keystone;
CREATE USER IF NOT EXISTS 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
CREATE USER IF NOT EXISTS 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';

-- Glance Database 
DROP DATABASE IF EXISTS glance;
CREATE DATABASE IF NOT EXISTS glance;
CREATE USER IF NOT EXISTS 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
CREATE USER IF NOT EXISTS 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%';

-- Placement Database 
DROP DATABASE IF EXISTS placement;
CREATE DATABASE IF NOT EXISTS placement;
CREATE USER IF NOT EXISTS 'placement'@'localhost' IDENTIFIED BY '$PLACEMENT_DBPASS';
CREATE USER IF NOT EXISTS 'placement'@'%' IDENTIFIED BY '$PLACEMENT_DBPASS';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%';

-- Nova Databases (api, main, and cell0) 
DROP DATABASE IF EXISTS nova_api;
DROP DATABASE IF EXISTS nova;
DROP DATABASE IF EXISTS nova_cell0;
CREATE DATABASE IF NOT EXISTS nova_api;
CREATE DATABASE IF NOT EXISTS nova;
CREATE DATABASE IF NOT EXISTS nova_cell0;
CREATE USER IF NOT EXISTS 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
CREATE USER IF NOT EXISTS 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%';

-- Neutron Database 
DROP DATABASE IF EXISTS neutron;
CREATE DATABASE IF NOT EXISTS neutron;
CREATE USER IF NOT EXISTS 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';
CREATE USER IF NOT EXISTS 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%';

FLUSH PRIVILEGES;
EOF

echo "OpenStack databases and users created successfully."
