# Chapter 3: Keystone (Identity Service)

Keystone is the central service for authentication and authorization in OpenStack. It manages the service catalog, users, projects, and roles.

## 3.1 Configuration

- Add the following to the configuration File: `/etc/keystone/keystone.conf`

```
[database] 

#Reemplaza connection = sqlite:////var/lib/keystone/keystone.db
connection = mysql+pymysql://keystone:<KEYSTONE_DBPASS>@controller/keystone 
 
[token] 
provider = fernet
```

- Add the following line to the file `/etc/apache2/apache2.conf`: `ServerName controller`

To automate the setup of the Identity Service (Keystone), you can use the following [bash script](../../scripts/keystone_setup.sh). This script performs the configuration file edits, initializes the database, bootstraps the service, and creates the necessary projects, users, and endpoints .


