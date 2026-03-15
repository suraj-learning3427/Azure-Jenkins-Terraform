#!/bin/bash
# Jenkins Installation Script for Azure VM (Ubuntu 22.04)
set -e

exec > >(tee -a /var/log/jenkins-startup.log)
exec 2>&1

echo "Starting Jenkins VM setup..."
echo "Timestamp: $(date)"

DISK_DEVICE="${data_disk_device}"
MOUNT_POINT="${mount_point}"
JENKINS_PORT="${jenkins_port}"

# Wait for data disk
echo "Waiting for data disk at $DISK_DEVICE..."
for i in $(seq 1 30); do
    if [ -e "$DISK_DEVICE" ]; then
        echo "Data disk found"
        break
    fi
    sleep 2
done

if [ ! -e "$DISK_DEVICE" ]; then
    echo "WARNING: Data disk not found at $DISK_DEVICE, using /dev/sdc fallback"
    DISK_DEVICE="/dev/sdc"
fi

# Format and mount data disk
if ! blkid "$DISK_DEVICE" 2>/dev/null; then
    echo "Formatting data disk..."
    mkfs.ext4 -F "$DISK_DEVICE"
fi

mkdir -p "$MOUNT_POINT"
mount "$DISK_DEVICE" "$MOUNT_POINT"

UUID=$(blkid -s UUID -o value "$DISK_DEVICE")
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
echo "Data disk mounted at $MOUNT_POINT"

# Install Java + Jenkins (Ubuntu/Debian)
apt-get update -y
apt-get install -y wget curl fontconfig openjdk-17-jre

wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins

# Configure Jenkins home on data disk
systemctl stop jenkins || true
mkdir -p "$MOUNT_POINT/jenkins_home"
chown -R jenkins:jenkins "$MOUNT_POINT/jenkins_home"

mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf <<EOF
[Service]
Environment="JENKINS_HOME=$MOUNT_POINT/jenkins_home"
Environment="JENKINS_PORT=$JENKINS_PORT"
EOF

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins web interface
echo "Waiting for Jenkins to start..."
for i in $(seq 1 60); do
    if curl -s -o /dev/null -w "%%{http_code}" "http://localhost:$JENKINS_PORT" | grep -qE "200|403"; then
        echo "Jenkins web interface is ready"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 5
done

ADMIN_PASS_FILE="$MOUNT_POINT/jenkins_home/secrets/initialAdminPassword"
if [ -f "$ADMIN_PASS_FILE" ]; then
    echo "Initial admin password: $(cat $ADMIN_PASS_FILE)"
fi

echo "Jenkins setup complete!"
echo "URL: http://localhost:$JENKINS_PORT"
echo "Timestamp: $(date)"
