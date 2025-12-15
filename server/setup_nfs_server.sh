#!/bin/bash
# setup_nfs_server.sh (v2 - UFW-optional)
# Run on 10.10.99.98 (AGX) — works with or without UFW

set -e

echo "[*] Configuring NFS server for /home/rm01/models..."

# 1. Fix directory permissions
sudo chown -R rm01:rm01 /home/rm01/models
sudo chmod -R 775 /home/rm01/models
sudo chmod o+x /home/rm01

# 2. Install NFS server
sudo apt update -qq
sudo DEBIAN_FRONTEND=noninteractive apt install -y nfs-kernel-server

# 3. Add export rule if missing
EXPORT_LINE="/home/rm01/models 10.10.99.99(rw,sync,no_subtree_check,no_root_squash)"
if ! grep -Fq "$EXPORT_LINE" /etc/exports; then
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports
    echo "[+] Added export rule"
else
    echo "[=] Export rule already exists"
fi

# 4. Apply NFS config
sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server

# 5. OPTIONAL: Configure UFW if available
if command -v ufw &> /dev/null; then
    echo "[*] UFW detected. Configuring firewall..."
    if ! sudo ufw status verbose 2>/dev/null | grep -q 'to any port nfs.*10.10.99.99'; then
        sudo ufw allow from 10.10.99.99 to any port nfs
        echo "[+] Added UFW rule for NFS"
    else
        echo "[=] UFW rule for NFS already exists"
    fi

    # Enable UFW if inactive (safe)
    if ! sudo ufw status | grep -q 'Status: active'; then
        echo "[*] Enabling UFW..."
        sudo ufw --force enable
    fi
else
    echo "[!] UFW not installed. Skipping firewall config."
    echo "    Make sure your network is trusted, or configure iptables manually."
fi

echo ""
echo "✅ NFS server setup complete."
echo "Shared: /home/rm01/models → to 10.10.99.99"
