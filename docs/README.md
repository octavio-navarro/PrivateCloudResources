# OpenStack Private Cloud Deployment Guide

1. Environment Preparation & Global Settings

- Variable Definitions: A reference table for all IPs, passwords, and secrets used throughout the guide .
- Network Configuration: Configuring /etc/hosts for the controller and the extensive list of compute nodes (1 through 30) .
- Base Package Installation: Installing the initial stack of services (MariaDB, RabbitMQ, Memcached, etc.) .

2. Infrastructure Services (The Foundation)

- MariaDB Database: Configuration of the SQL engine and creation of service-specific databases .
- Message Queue & Caching: Setting up RabbitMQ permissions, Memcached, and ETCD .
- Time Synchronization: Configuring Chrony for cluster-wide clock consistency .

3. Keystone (Identity Service)

- Configuration: Setting up the Fernet token provider and database connection .
- Initialization: Bootstrapping the service and defining the administration region .
- Service Entities: Creating the environment variables (admin-openrc), projects, users, and roles for all other services .
- Endpoint Registry: Registering the public, internal, and admin URLs for the service catalog .

4. Core Controller Services

- Glance (Image Service): Configuring the file system backend and image registry .
- Placement (Resource Tracking): Configuring API access and database connectivity .
- Nova (Compute Management): Configuring the controller-side compute components, including VNC and cell mapping .
- Neutron (Networking): Setting up the ML2 plugin, Open vSwitch (OVS) agent, and metadata proxy .

5. Horizon (The Dashboard)

- Web Interface Setup: Configuring the Django-based dashboard, session engines, and Keystone multi-domain support .

6. Service Initialization & Verification

- Database Syncing: Executing the final db_sync commands for all services.
- Service Startup: Restarting and enabling the systemd services .
- Testing: Uploading the initial CirrOS test image.

7. Compute Node Deployment

- Node Preparation: Host mapping and Chrony synchronization for compute nodes .
- Compute & Networking Agents: Installing and configuring nova-compute and neutron-openvswitch-agent on the nodes .
- OVS Bridge Configuration: Linking the physical data interface to the provider bridge.

8. Cloud Resource Provisioning

- Project & Network Setup: Creating tenant projects, VLAN-typed provider networks, and subnets.
- Flavor Management: Defining VM sizes (CPU, RAM, Disk).
- Image Management: Adding official OS images (e.g., Debian 12 Bookworm) to the cloud.
