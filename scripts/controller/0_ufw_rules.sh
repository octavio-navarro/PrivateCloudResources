#!/bin/bash

# --- UFW Initialization ---
echo "Enabling UFW..."
# --force ensures the script doesn't stop to ask you "Command may disrupt network connections. Proceed? (y|n)"
sudo ufw --force enable

# --- Global Rules ---
echo "Applying global access and restriction rules..."

# Rule: 65032/tcp - ALLOW Anywhere
sudo ufw allow 65032/tcp
sudo ufw allow 80/tcp
sudo ufw allow 6080/tcp

# Rule: 22/tcp - DENY Anywhere (Careful!)
sudo ufw deny 22/tcp

# --- Compute Node Range Rules (192.168.133.1 to 192.168.133.30) ---
echo "Configuring service access for compute nodes .1 through .30..."

# List of ports required by the compute nodes
SERVICES=(5672 5000 8778 9292 3306 9696)

for i in {1..30}; do
    NODE_IP="192.168.133.$i"
    echo "Adding rules for $NODE_IP..."
    
    for PORT in "${SERVICES[@]}"; do
        # Use 'insert 1' to ensure these specific rules take priority if needed
        sudo ufw allow from "$NODE_IP" to any port "$PORT" proto tcp
    done
done

# --- Reload and Verify ---
echo "Reloading firewall..."
sudo ufw reload

echo "------------------------------------------------------------"
echo "UFW Status for the Compute Cluster:"
sudo ufw status | grep "192.168.133" | head -n 10
echo "... (total rules applied for 30 nodes) ..."
echo "------------------------------------------------------------"
echo "Setup complete. The controller is now shielded, but open for nodes .1 to .30."
