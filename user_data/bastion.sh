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

echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ec2-user/.bashrc

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

cat > /home/ec2-user/setup-kubectl.sh << 'EOF'
#!/bin/bash

echo "Setting up kubectl access to K3s cluster..."

# Wait for master node to be ready
echo "Waiting for K3s master node to initialize..."
sleep 180

# Try to get kubeconfig from master node
MASTER_IP=$(aws ec2 describe-instances \
  --region eu-west-2 \
  --filters "Name=tag:Type,Values=k3s-master" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

if [ "$MASTER_IP" != "None" ]; then
    echo "Found K3s master at: $MASTER_IP"
    
    # Copy kubeconfig from master node
    echo "Copying kubeconfig from master node..."
    scp -o StrictHostKeyChecking=no ec2-user@$MASTER_IP:/home/ec2-user/.kube/config ~/.kube/config 2>/dev/null
    
    if [ -f ~/.kube/config ]; then
        # Update server URL to use private IP
        sed -i "s/127.0.0.1/$MASTER_IP/g" ~/.kube/config
        echo "Kubeconfig configured successfully!"
        
        # Test connection
        echo "Testing kubectl connection..."
        kubectl get nodes
        kubectl get pods --all-namespaces
    else
        echo "Failed to copy kubeconfig. Master node may not be ready yet."
        echo "You can run this script again in a few minutes."
    fi
else
    echo "Could not find K3s master node. Please check if the cluster is deployed."
fi
EOF

chmod +x /home/ec2-user/setup-kubectl.sh
chown ec2-user:ec2-user /home/ec2-user/setup-kubectl.sh

cat > /home/ec2-user/k8s-commands.sh << 'EOF'
#!/bin/bash

echo "=== K8s Cluster Management Commands ==="
echo ""
echo "1. Check cluster nodes:"
echo "   kubectl get nodes -o wide"
echo ""
echo "2. Check all pods:"
echo "   kubectl get pods --all-namespaces"
echo ""
echo "3. Deploy simple nginx pod:"
echo "   kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml"
echo ""
echo "4. Check pod status:"
echo "   kubectl get pod nginx"
echo ""
echo "5. Get pod logs:"
echo "   kubectl logs nginx"
echo ""
echo "6. Delete test pod:"
echo "   kubectl delete pod nginx"
echo ""
echo "7. Check cluster info:"
echo "   kubectl cluster-info"
echo ""

# Execute if argument provided
if [ "$1" == "nodes" ]; then
    kubectl get nodes -o wide
elif [ "$1" == "pods" ]; then
    kubectl get pods --all-namespaces
elif [ "$1" == "deploy" ]; then
    kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
elif [ "$1" == "test" ]; then
    kubectl get nodes
    kubectl get pods --all-namespaces
elif [ "$1" == "info" ]; then
    kubectl cluster-info
fi
EOF

chmod +x /home/ec2-user/k8s-commands.sh
chown ec2-user:ec2-user /home/ec2-user/k8s-commands.sh

echo "Bastion host configuration completed successfully!"

echo "System Information:"
uname -a
echo "Available packages:"
yum list installed | grep -E "(aws|cloud|security)" | head -10 