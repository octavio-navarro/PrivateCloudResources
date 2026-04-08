# Chapter 4: Core Controller Services

This chapter covers the configuration of the primary OpenStack services on the controller node. These services manage images, resource placement, compute orchestration, and networking.

## 4.1 Glance (Image Service)

The Image Service allows users to discover, register, and retrieve virtual machine images.

- **Configuration File:** `/etc/glance/glance-api.conf` 
- **Backend Storage:** Enable the file system backend by setting `enabled_backends=fs:file` in the `[DEFAULT]` section.
- **Database Connection:** Configure the SQL connection using the `mysql+pymysql` driver and the `<GLANCE_DBPASS>`.
- **Authentication:** Set up the `[keystone_authtoken]` section with the controller's identity URI, memcached servers, and service credentials (glance user) .
- **Deployment Flavor:** Set the flavor to keystone under `[paste_deploy]` .
- **Store Configuration:** Define the default_backend as fs and specify the local directory for image storage: `/var/lib/glance/images/` .
- **Resource Limits:** Configure the `[oslo_limit]` section with administrative credentials and the specific `<glance_endpoint_id>` .

## 4.2 Placement (Resource Tracking)

Placement tracks the inventory and usage of resources like CPU, RAM, and IP addresses.

- **Configuration File**: `/etc/placement/placement.conf` 
- **Database:** Connect to the placement database using `<PLACEMENT_DBPASS>` 
- **API Strategy:** Ensure the auth_strategy is set to keystone.
- **Authentication:** Configure the `[keystone_authtoken]` section with the identity URL, memcached servers at controller:11211, and the placement user credentials.

## 4.3 Nova (Compute Orchestration)

Nova manages the lifecycle of virtual machine instances. This configuration focuses on the controller-side logic.

- Configuration File: `/etc/nova/nova.conf`
- Message Queue: Define the transport_url using the RabbitMQ openstack user and `<RABBIT_PASS>` .
- IP Configuration: Set my_ip to the `<ip_controlador>` 
- Databases: Configure both the `[api_database]` and the main `[database]` connections using the `<NOVA_DBPASS>` 
- Identity Access: Point to the Keystone identity service for authentication and service user tokens.
- VNC Console: Enable VNC support and set the server to listen on the controller’s IP.
- External Services: Link Nova to the Image (Glance), Placement (Placement), and Network (Neutron) services.
- Metadata Security: Set `service_metadata_proxy = true` and define the `<METADATA_SECRET>` for secure communication with Neutron.

## 4.4 Neutron (Networking)

Neutron provides "connectivity as a service" between interface devices managed by other services.

- Configuration File: `/etc/neutron/neutron.conf` 
    - Plugins: Set the core_plugin to `ml2` .
    - Communication: Configure the RabbitMQ transport URL and set the auth_strategy to keystone.
    - Nova Integration: Enable notifications to Nova regarding port status and data changes.
    - DHCP Configuration: Set `dhcp_agents_per_network = 2` for redundancy.
    - Database & Identity: Configure the SQL connection with `<NEUTRON_DBPASS>` and set up the Keystone authentication tokens for the neutron user.
    - Compute Interaction: Configure the `[nova]` section to allow Neutron to communicate back to the compute service using the nova user credentials.

- Layer 2 & Agent Configuration
    - ML2 Plugin (`/etc/neutron/plugins/ml2/ml2_conf.ini`): Enable flat, vlan, and vxlan drivers, set vxlan as the tenant network type, and use openvswitch as the mechanism driver .
    - OVS Agent (`/etc/neutron/plugins/ml2/openvswitch_agent.ini)`: Map the provider network to the br-provider bridge and define the local IP for VXLAN tunnels.
    - DHCP Agent (`/etc/neutron/dhcp_agent.ini`): Set the interface driver to openvswitch and enable isolated metadata.
    - Metadata Agent (`/etc/neutron/metadata_agent.ini`): Point to the controller as the metadata host and provide the <METADATA_SECRET>
