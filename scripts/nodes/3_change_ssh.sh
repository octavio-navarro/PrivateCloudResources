#!/bin/bash

# --- 1. Validate Parameter ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <PORT_NUMBER>"
    echo "Example: sudo $0 65032"
    exit 1
fi

NEW_PORT=$1
SOCKET_OVERRIDE_DIR="/etc/systemd/system/ssh.socket.d"
SSHD_CONFIG_D="/etc/ssh/sshd_config.d"
HARDENING_CONF="$SSHD_CONFIG_D/50-cloud-init.conf"

echo "------------------------------------------------------------"
echo "Starting SSH Hardening and Port Migration to $NEW_PORT"
echo "------------------------------------------------------------"

# --- 2. Port Migration (Systemd Socket) ---
echo "[1/4] Configuring Systemd Socket for port $NEW_PORT..."
sudo mkdir -p "$SOCKET_OVERRIDE_DIR"
sudo tee "$SOCKET_OVERRIDE_DIR/override.conf" > /dev/null <<EOF
[Socket]
ListenStream=
ListenStream=0.0.0.0:$NEW_PORT
ListenStream=[::]:$NEW_PORT
EOF

# --- 3. Security Hardening (Disable Passwords/Root) ---
echo "[2/4] Applying security policies to $HARDENING_CONF..."
sudo mkdir -p "$SSHD_CONFIG_D"

# Creating the hardening file
sudo tee "$HARDENING_CONF" > /dev/null <<EOF
PasswordAuthentication no
UsePAM no
PermitRootLogin no
EOF

# Note: In Ubuntu, 50-cloud-init.conf can sometimes override settings.
# We ensure our hardening file exists. If 50-cloud-init.conf exists, 
# it usually includes 'PasswordAuthentication yes'. 
# You may want to check if that file conflicts.

# --- 4. Configuration Sync ---
echo "[3/4] Syncing main sshd_config port..."
sudo sed -i "s/^#Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config
sudo sed -i "s/^Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config

# --- 5. Reload and Restart ---
echo "[4/4] Reloading systemd and restarting services..."
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
# We restart the service as well to ensure the new sshd_config.d files are read
sudo systemctl restart ssh

# --- 6. Verification ---
echo "------------------------------------------------------------"
echo "Verification:"
echo "Socket listening on:"
sudo ss -tlnp | grep ssh
echo "Hardening File Content ($HARDENING_CONF):"
sudo cat "$HARDENING_CONF"
echo "------------------------------------------------------------"
echo "SSH is now restricted to Key-Based Auth only on port $NEW_PORT."
