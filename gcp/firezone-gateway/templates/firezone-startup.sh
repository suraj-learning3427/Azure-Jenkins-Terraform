#!/bin/bash
# Firezone Gateway Installation Script for GCP VM
set -e

exec > >(tee -a /var/log/firezone-startup.log)
exec 2>&1

echo "Starting Firezone Gateway setup..."
echo "Timestamp: $(date)"

FIREZONE_TOKEN="${firezone_token}"
FIREZONE_ID="${firezone_id}"
LOG_LEVEL="${log_level}"

# Update system
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget gnupg lsb-release ca-certificates software-properties-common iptables

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# Run Firezone gateway
echo "Starting Firezone gateway container..."
GATEWAY_NAME=$(hostname)
docker run -d \
  --restart=unless-stopped \
  --pull=always \
  --health-cmd="ip link | grep tun-firezone" \
  --name=firezone-gateway \
  --cap-add=NET_ADMIN \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --sysctl net.ipv6.conf.default.forwarding=1 \
  --device="/dev/net/tun:/dev/net/tun" \
  --env FIREZONE_ID="$FIREZONE_ID" \
  --env FIREZONE_TOKEN="$FIREZONE_TOKEN" \
  --env FIREZONE_NAME="$GATEWAY_NAME" \
  --env RUST_LOG=$LOG_LEVEL \
  ghcr.io/firezone/gateway:1

# Health check HTTP server for load balancer
apt-get install -y python3
mkdir -p /opt/firezone

cat > /etc/systemd/system/firezone-health.service <<EOF
[Unit]
Description=Firezone Health Check Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/firezone
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable firezone-health.service
systemctl start firezone-health.service

echo "Firezone Gateway setup completed!"
echo "Logs: /var/log/firezone-startup.log"
