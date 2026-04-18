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

echo "=== [2/5] Install Docker CE ==="
apt-get install -y ca-certificates curl git
# Install Docker CE from official script (includes docker-compose-plugin)
curl -fsSL https://get.docker.com | sh
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
mkdir -p /opt/ai-knowledge-path
chown ubuntu:ubuntu /opt/ai-knowledge-path
sudo -u ubuntu git clone https://github.com/PhanAnh1001/ai-knowledge-path.git /opt/ai-knowledge-path

echo "=== [5/5] Create .env placeholder ==="
cp /opt/ai-knowledge-path/.env.example /opt/ai-knowledge-path/.env
echo ""
echo "============================================================"
echo "Lightsail init complete!"
echo "Next steps:"
echo "  1. SSH into instance: ssh ubuntu@<IP>"
echo "  2. Edit /opt/ai-knowledge-path/.env with real values"
echo "  3. docker compose -f docker-compose.prod.yml up -d"
echo "============================================================"
