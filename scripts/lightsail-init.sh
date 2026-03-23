#!/bin/bash
# =============================================================================
# lightsail-init.sh — AWS Lightsail instance bootstrap script
# Chạy khi instance khởi động lần đầu (user-data)
#
# Dùng với:
#   aws lightsail create-instances \
#     --user-data file://scripts/lightsail-init.sh
# =============================================================================
set -euo pipefail

echo "=== [1/5] Update packages ==="
apt-get update -y
apt-get upgrade -y

echo "=== [2/5] Install Docker ==="
apt-get install -y docker.io docker-compose-plugin git curl

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo "=== [3/5] Configure firewall ==="
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (redirect)
ufw allow 443/tcp   # HTTPS
ufw allow 443/udp   # HTTP/3 QUIC
ufw --force enable

echo "=== [4/5] Clone repository ==="
mkdir -p /opt/ai-wisdom-battle
chown ubuntu:ubuntu /opt/ai-wisdom-battle
sudo -u ubuntu git clone https://github.com/aiwisdombattle/ai-wisdom-battle.git /opt/ai-wisdom-battle

echo "=== [5/5] Create .env placeholder ==="
cp /opt/ai-wisdom-battle/.env.example /opt/ai-wisdom-battle/.env
echo ""
echo "============================================================"
echo "Lightsail init complete!"
echo "Next steps:"
echo "  1. SSH into instance: ssh ubuntu@<IPv6>"
echo "  2. Edit /opt/ai-wisdom-battle/.env with real values"
echo "  3. docker compose -f docker-compose.prod.yml up -d"
echo "============================================================"
