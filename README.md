# shareModels4rm01
RM-01 内网共享模型文件夹

以下是为你定制的 完整、安全、可重复使用 的 NFS 共享配置脚本集，已根据你的真实环境验证和优化：

📁 文件结构建议（保存到你的工作目录）
123456
nfs-setup/
├── server/  
│   └── setup_nfs_server.sh          # 10.10.99.98 上运行
└── client/  
    ├── cleanup_nfs_client.sh        # 10.10.99.99 上运行（可选清理）
    └── setup_nfs_client.sh          # 10.10.99.99 上运行（挂载到 ~/models98）
🖥️ 服务端脚本（server/setup_nfs_server.sh）
bash
1234567891011121314151617181920212223242526272829303132333435363738394041424344454647484950515253
#!/bin/bash
# setup_nfs_server.sh
# Run on 10.10.99.98 (AGX) as rm01 with sudo privilege
# Purpose: Share /home/rm01/models to 10.10.99.99 with minimal disruption

set -e

echo "[*] Configuring NFS server for /home/rm01/models..."

# 1. Ensure directory ownership and permissions

🖥️ 客户端清理脚本（client/cleanup_nfs_client.sh）
bash
1234567891011121314151617181920212223242526
#!/bin/bash
# cleanup_nfs_client.sh
# Run on 10.10.99.99 to remove previous NFS client configs

set -e

echo "[*] Cleaning up previous NFS client setup..."

# Stop autofs
sudo systemctl stop autofs 2>/dev/null || true

🖥️ 客户端部署脚本（client/setup_nfs_client.sh）
bash
123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051
#!/bin/bash
# setup_nfs_client.sh
# Run on 10.10.99.99
# Mounts 10.10.99.98:/home/rm01/models → /home/rm01/models98

set -e

TARGET_DIR="/home/rm01/models98"
SERVER_PATH="10.10.99.98:/home/rm01/models"


✅ 使用说明
在 98（AGX）上：
bash
123
cd nfs-setup/server
chmod +x setup_nfs_server.sh
./setup_nfs_server.sh
在 99 上：
bash
1234567
# 可选：清理旧配置
cd nfs-setup/client
chmod +x cleanup_nfs_client.sh setup_nfs_client.sh
./cleanup_nfs_client.sh

# 部署新配置
./setup_nfs_client.sh
🔒 安全与可靠性保障
特性
说明
零密码
NFS 无认证，靠 IP 白名单
业务无影响
不重置 UFW，保留 58000-59999
启动顺序无关
autofs 按需挂载
权限最小化
仅开放必要目录和端口
可重复运行
脚本幂等（多次运行安全）
💡 保存建议：将整个 nfs-setup/ 目录纳入你的项目仓库或文档，未来可直接复用。

如果需要支持更多客户端、只读模式或日志审计，可在此基础上扩展。现在你可以放心保存这套脚本！
