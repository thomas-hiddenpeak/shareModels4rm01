#!/bin/bash
# setup_nfs_server.sh
# Run on 10.10.99.98 (AGX) as rm01 with sudo privilege
# Purpose: Share /home/rm01/models to 10.10.99.99 with minimal disruption

set -e

echo "[*] Configuring NFS server for /home/rm01/models..."

# 1. Ensure directory ownership and permissions
SHARE_DIR="/home/rm01/models"
if [ ! -d "$SHARE_DIR" ]; then
    echo "[+] Creating share directory: $SHARE_DIR"
    sudo mkdir -p "$SHARE_DIR"
    sudo chown rm01:rm01 "$SHARE_DIR"
    sudo chmod 755 "$SHARE_DIR"
else
    echo "[✓] Share directory already exists: $SHARE_DIR"
fi

# 2. Install NFS server packages if needed
if ! dpkg -l | grep -q nfs-kernel-server; then
    echo "[+] Installing NFS server packages..."
    sudo apt update
    sudo apt install -y nfs-kernel-server
else
    echo "[✓] NFS server packages already installed"
fi

# 3. Configure /etc/exports (idempotent)
EXPORT_LINE="$SHARE_DIR 10.10.99.99(rw,sync,no_subtree_check,no_root_squash)"
if ! sudo grep -Fxq "$EXPORT_LINE" /etc/exports 2>/dev/null; then
    echo "[+] Adding NFS export configuration..."
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null
else
    echo "[✓] NFS export already configured"
fi

# 4. Export the shared directory
echo "[+] Applying NFS exports..."
sudo exportfs -ra

# 5. Configure UFW firewall (without resetting existing rules)
if command -v ufw >/dev/null 2>&1; then
    echo "[+] Configuring UFW firewall for NFS..."
    
    # Allow NFS services from client IP
    sudo ufw allow from 10.10.99.99 to any port 2049 comment 'NFS server' 2>/dev/null || true
    sudo ufw allow from 10.10.99.99 to any port 111 comment 'NFS rpcbind' 2>/dev/null || true
    sudo ufw allow from 10.10.99.99 to any port 20048 comment 'NFS mountd' 2>/dev/null || true
    
    echo "[✓] UFW rules added (existing rules preserved)"
else
    echo "[!] UFW not found, skipping firewall configuration"
fi

# 6. Start and enable NFS services
echo "[+] Starting NFS services..."
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-kernel-server --no-pager | head -10

# 7. Verify configuration
echo ""
echo "=========================================="
echo "[✓] NFS Server Setup Complete!"
echo "=========================================="
echo "Shared directory: $SHARE_DIR"
echo "Client allowed: 10.10.99.99"
echo ""
echo "Current exports:"
sudo exportfs -v
echo ""
echo "NFS server is ready for client connections."
