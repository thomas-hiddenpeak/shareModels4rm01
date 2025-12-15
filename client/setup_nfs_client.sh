#!/bin/bash
# setup_nfs_client.sh
# Run on 10.10.99.99
# Mounts 10.10.99.98:/home/rm01/models → /home/rm01/models98

set -e

TARGET_DIR="/home/rm01/models98"
SERVER_PATH="10.10.99.98:/home/rm01/models"
NFS_MOUNT_OPTIONS="rw,hard,intr,timeo=600,retrans=3"

echo "[*] Setting up NFS client to mount $SERVER_PATH..."

# 1. Install required packages
if ! dpkg -l | grep -q nfs-common; then
    echo "[+] Installing NFS client packages..."
    sudo apt update
    sudo apt install -y nfs-common
else
    echo "[✓] NFS client packages already installed"
fi

if ! dpkg -l | grep -q autofs; then
    echo "[+] Installing autofs..."
    sudo apt install -y autofs
else
    echo "[✓] autofs already installed"
fi

# 2. Create mount point directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "[+] Creating mount point: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
else
    echo "[✓] Mount point already exists: $TARGET_DIR"
fi

# 3. Test NFS server connectivity
echo "[+] Testing NFS server connectivity..."
if showmount -e 10.10.99.98 >/dev/null 2>&1; then
    echo "[✓] NFS server is accessible"
    showmount -e 10.10.99.98
else
    echo "[!] Warning: Cannot reach NFS server. Make sure server is configured first."
fi

# 4. Configure autofs for automatic mounting
echo "[+] Configuring autofs..."

# Create master configuration
MASTER_CONFIG="/etc/auto.master.d/models.autofs"
if [ ! -f "$MASTER_CONFIG" ]; then
    echo "/home/rm01 /etc/auto.models --timeout=300" | sudo tee "$MASTER_CONFIG" > /dev/null
    echo "[✓] Created autofs master config: $MASTER_CONFIG"
else
    echo "[✓] autofs master config already exists"
fi

# Create mount map
AUTO_MAP="/etc/auto.models"
MAP_LINE="models98 -fstype=nfs,${NFS_MOUNT_OPTIONS} ${SERVER_PATH}"
if [ ! -f "$AUTO_MAP" ] || ! grep -Fxq "$MAP_LINE" "$AUTO_MAP" 2>/dev/null; then
    echo "$MAP_LINE" | sudo tee "$AUTO_MAP" > /dev/null
    echo "[✓] Created autofs mount map: $AUTO_MAP"
else
    echo "[✓] autofs mount map already configured"
fi

# 5. Reload and enable autofs
echo "[+] Reloading autofs service..."
sudo systemctl daemon-reload
sudo systemctl enable autofs
sudo systemctl restart autofs
sudo systemctl status autofs --no-pager | head -10

# 6. Test the mount
echo ""
echo "[+] Testing mount access..."
sleep 2
if ls "$TARGET_DIR" >/dev/null 2>&1; then
    echo "[✓] Mount test successful!"
    echo "Contents of $TARGET_DIR:"
    ls -lah "$TARGET_DIR" | head -10
else
    echo "[!] Warning: Could not access mount point. Check logs with: journalctl -u autofs -n 50"
fi

echo ""
echo "=========================================="
echo "[✓] NFS Client Setup Complete!"
echo "=========================================="
echo "Server: $SERVER_PATH"
echo "Mount point: $TARGET_DIR"
echo "Mount type: autofs (on-demand)"
echo ""
echo "The directory will be automatically mounted when you access it:"
echo "  cd $TARGET_DIR"
echo ""
echo "To manually check autofs status:"
echo "  sudo systemctl status autofs"
echo "  sudo automount -f -v"
