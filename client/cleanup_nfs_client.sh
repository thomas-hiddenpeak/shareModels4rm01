#!/bin/bash
# cleanup_nfs_client.sh
# Run on 10.10.99.99 to remove previous NFS client configs

set -e

echo "[*] Cleaning up previous NFS client setup..."

# 1. Stop autofs service
echo "[+] Stopping autofs service..."
sudo systemctl stop autofs 2>/dev/null || true
sudo systemctl disable autofs 2>/dev/null || true

# 2. Unmount any existing NFS mounts
TARGET_DIR="/home/rm01/models98"
if mountpoint -q "$TARGET_DIR" 2>/dev/null; then
    echo "[+] Unmounting $TARGET_DIR..."
    sudo umount -f "$TARGET_DIR" 2>/dev/null || true
else
    echo "[✓] No active mount at $TARGET_DIR"
fi

# 3. Remove autofs configuration files
echo "[+] Removing autofs configuration..."
sudo rm -f /etc/auto.master.d/models.autofs 2>/dev/null || true
sudo rm -f /etc/auto.models 2>/dev/null || true

# 4. Clean up /etc/fstab entries for NFS mounts
echo "[+] Cleaning /etc/fstab..."
if grep -q "10.10.99.98:/home/rm01/models" /etc/fstab 2>/dev/null; then
    sudo sed -i.bak '/10\.10\.99\.98:\/home\/rm01\/models/d' /etc/fstab
    echo "[✓] Removed NFS entries from /etc/fstab (backup saved as /etc/fstab.bak)"
else
    echo "[✓] No NFS entries found in /etc/fstab"
fi

# 5. Remove mount point directory if empty
if [ -d "$TARGET_DIR" ] && [ -z "$(ls -A $TARGET_DIR)" ]; then
    echo "[+] Removing empty mount point directory..."
    rmdir "$TARGET_DIR" 2>/dev/null || true
fi

# 6. Reload systemd daemon
echo "[+] Reloading systemd daemon..."
sudo systemctl daemon-reload

echo ""
echo "=========================================="
echo "[✓] NFS Client Cleanup Complete!"
echo "=========================================="
echo "All previous NFS configurations have been removed."
echo "You can now run setup_nfs_client.sh to set up fresh configuration."
