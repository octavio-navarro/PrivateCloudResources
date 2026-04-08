# Chapter 6: Service Initialization & Verification

Once configured, each service requires a database synchronization and a restart to apply changes.

## 6.1 Glance & Placement Initialization

- Glance: Run sudo glance-manage db_sync, restart glance-api, and verify by creating a test image using the CirrOS disk image.
- Placement: Run sudo placement-manage db sync and restart apache2.

## 6.2 Nova (Compute) Initialization

- Sync Databases: Execute sudo nova-manage api_db sync followed by sudo nova-manage db sync.
- Cell Mapping: * Map the cell0 database using sudo nova-manage cell_v2 map_cell0.
- Create the first cell with sudo nova-manage cell_v2 create_cell --name=cell1.
- Start Services: Restart nova-api, nova-scheduler, nova-conductor, and nova-novncproxy.

## 6.3 Neutron (Networking) Initialization

- Bridge Setup: Create the provider bridge using sudo ovs-vsctl add-br br-provider and map it to your physical data interface.
- Database Upgrade: Use neutron-db-manage with the ml2_conf.ini and neutron.conf files to upgrade the database head.
- Service Restart: * Restart neutron-server and the OVS, DHCP, Metadata, and L3 agents.
- Perform a final restart of nova-api and apache2.
