# Chapter 5: Horizon (The Dashboard)

Horizon provides a web-based user interface to OpenStack services.

## 5.1 Configuration

Configuration File: /etc/openstack-dashboard/local_settings.py 

- Host Settings: Change OPENSTACK_HOST to "controller".
- Session & Cache: * Set SESSION_ENGINE to 'django.contrib.sessions.backends.cache'.
    - Update the CACHES location to 'controller:11211'.
- Identity & API Support:
    - Enable OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True.
    - Define OPENSTACK_API_VERSIONS for identity (3), image (2), and volume (3).
    - Set OPENSTACK_KEYSTONE_DEFAULT_DOMAIN to "Default".
- Endpoint URL: Update OPENSTACK_KEYSTONE_URL to point to http://%s:5000/identity/v3 using the OPENSTACK_HOST vriable
- Optimization: Comment out the COMPRESS_OFFLINE = TRUE line.
