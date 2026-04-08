# Chapter 1: Environment Preparation & Global Settings

Before deploying any OpenStack services, the underlying infrastructure must be synchronized and aware of every node in the cluster. This chapter defines the variables used throughout the installation and the initial OS-level configurations.

## 1.1 Variable Reference Table

The following placeholders must be defined before starting the installation. Ensure these values are consistent across all configuration files.

| Variable | Description |
|--- | --- |
| `<ip_controlador>` | Management IP of the Controller node.| 
| `<red de management/mascara>` | Network address and CIDR for management traffic. |
| `<ADMIN_PASS>` | Password for the OpenStack admin user. |
| `<RABBIT_PASS>` | Password for the RabbitMQ openstack user. |
| `<METADATA_SECRET>` | Shared secret for the Neutron metadata agent. |
| `<SERVICE_DBPASS>` Unique database passwords for Keystone, Glance, Placement, Nova, and Neutron.|
| `<SERVICE_PASS>` | Unique service user passwords for Glance, Placement, Nova, and Neutron. |

## 1.2 Network Configuration & Host Resolution
 
For the services to communicate via hostnames rather than static IPs, you must modify the /etc/hosts file on every node in the cluster.

- Controller Node: Assign the hostname controller to your controller's management IP.
- Compute Nodes (1-30): Map the management IPs for all thirty compute nodes as follows :

```Plaintext
192.168.133.1  computo1
192.168.133.2  computo2
192.168.133.3  computo3
...
192.168.133.30 computo30
```

## 1.3 Base Package Installation

Update your repository local cache and install the core supporting services and OpenStack clients on the Controller node.

```Bash
sudo apt update
sudo apt install -y chrony mariadb-server python3-pymysql memcached \
python3-memcache etcd-server keystone python3-openstackclient \
glance placement-api nova-api nova-conductor nova-novncproxy \
nova-scheduler neutron-server neutron-plugin-ml2 \
neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
neutron-metadata-agent openstack-dashboard rabbitmq-server
```

**Note: This command installs the Identity service (Keystone), Image service (Glance), Placement API, Compute (Nova), and Networking (Neutron) components simultaneously**


