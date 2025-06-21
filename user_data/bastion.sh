#!/bin/bash

exec > >(tee /var/log/bastion-setup.log)
exec 2>&1

echo "Starting Bastion host configuration..."

yum update -y

yum install -y \
    htop \
    vim \
    wget \
    curl \
    telnet \
    nc \
    tree \
    jq \
    awscli

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat >> /etc/ssh/sshd_config << 'EOF'

# Bastion host SSH configuration
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 3
MaxSessions 10
Protocol 2
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel no
EOF

systemctl restart sshd

cat > /etc/yum/automatic.conf << 'EOF'
[commands]
upgrade_type = security
random_sleep = 360
download_updates = yes
apply_updates = yes
EOF

systemctl enable yum-automatic.timer
systemctl start yum-automatic.timer

cat > /etc/motd << 'EOF'
=====================================
    RSSchool DevOps Bastion Host
=====================================
This is a secure jump server for accessing private resources.

Security reminders:
- Use key-based authentication only
- Keep your sessions secure
- Log all administrative activities
- Report suspicious activities

For support, contact the DevOps team.
=====================================
EOF

cat > /etc/logrotate.d/bastion-logs << 'EOF'
/var/log/auth.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

echo "Bastion host configured on $(date)" > /var/log/bastion-status.txt
echo "Bastion host configuration completed successfully!"

echo "System Information:"
uname -a
echo "Available packages:"
yum list installed | grep -E "(aws|cloud|security)" | head -10 