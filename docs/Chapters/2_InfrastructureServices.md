# Chapter 2: Infrastructure Services

This chapter details the configuration of the supporting services that provide the foundation for OpenStack, including the SQL database, message queue, distributed key-value store, and time synchronization.

## 2.1 MariaDB Database

OpenStack services use a SQL database to store information. MariaDB is the recommended choice for this deployment.

Modify the file /etc/mysql/mariadb.conf.d/99-openstack.cnf and add the following parameters under the [mysqld] section :

```Ini, TOML
[mysqld]
bind-address = <ip_controlador>
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```

- Bind Address: Ensure the database listens on the controller's management IP.
- Storage Engine: Set the default engine to InnoDB for reliability.
- Performance: Increased max_connections to 4096 to handle high service volume.

Restart the database service to apply changes:

```bash
sudo systemctl restart mysqld
```

## 2.2 Service Database Initialization

You must create individual databases and grant permissions for each OpenStack service . Use the passwords defined in your variable reference table.

| Service | Database Name(s) | User | 
| --- | --- | --- |
| Keystone | keystone | keystone | 
| Glance | glance | glance |
| placement | placement | placement |
| Nova | nova_api, nova, nova_cell0 | nova 
| Neutron | neutron | neutron |

** Note: Ensure you grant privileges for both localhost and the wildcard % for every service user.

You can run the script `database_creation.sh` to create the databases:

- Set Passwords: Edit the variables at the top (KEYSTONE_DBPASS, etc.) with your specific credentials .
- Make it executable: Run chmod +x setup_databases.sh.
- Run the script: Execute it with ./setup_databases.sh. It will prompt for your MariaDB root password if one is set.

** Warning: Running this script will permanently delete all existing data within the keystone, glance, placement, nova, and neutron databases. Only use this for a fresh deployment or a full environment reset.**

## 2.3 Message Queue & Distributed Coordination

### RabbitMQ (Message Queue)

OpenStack services use RabbitMQ to coordinate operations and status information between nodes.

- Add User: sudo rabbitmqctl add_user openstack <RABBIT_PASS>.
- Set Permissions: sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*".

### Memcached (Caching)

The Identity service (Keystone) uses Memcached to cache tokens and improve performance.

- Modify /etc/memcached.conf and update the -l (listen) parameter to <ip_controlador> .
- Restart the service: sudo service memcached restart.

### ETCD (Distributed Key-Value Store)

ETCD is used by OpenStack for distributed locking and coordination.

- Modify /etc/default/etcd with the following cluster settings :

    - ETCD_NAME="controller"
    - ETCD_INITIAL_CLUSTER="controller=http://<ip_controlador>:2380"
    - ETCD_LISTEN_CLIENT_URLS=http://<ip_controlador>:2379
    - Enable and restart: `sudo systemctl enable etcd sudo systemctl restart etcd`

## 2.4 Time Synchronization (Chrony)

Clock synchronization is critical for OpenStack. If the time drifts between the controller and compute nodes, service tokens and instance scheduling will fail.

- Configuration: Edit /etc/chrony/chrony.conf.
- Network Access: Add the line allow <red de management/mascara> to allow compute nodes to sync with the controller.
- Restart: `sudo systemctl restart chrony`
