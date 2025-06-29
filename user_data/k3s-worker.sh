#!/bin/bash

exec > >(tee /var/log/k3s-worker-setup.log)
exec 2>&1

echo "Starting K3s Worker node configuration..."

dnf update -y

echo "Installing dependencies..."
dnf install -y curl --allowerasing
dnf install -y \
    wget \
    htop \
    vim \
    nmap-ncat

echo "Waiting for master node to be ready..."
sleep 180

echo "Cleaning any existing K3s configuration..."
systemctl stop k3s-agent 2>/dev/null || true
rm -rf /var/lib/rancher/k3s/agent
rm -rf /etc/rancher/k3s/k3s.yaml
rm -f /usr/local/bin/k3s
killall k3s 2>/dev/null || true

echo "Using pre-generated cluster token..."
NODE_TOKEN="${k3s_token}"
echo "Token configured successfully"

K3S_URL="https://${master_ip}:6443"

echo "Installing K3s agent..."
echo "Master IP: ${master_ip}"
echo "K3s URL: $K3S_URL"

echo "Testing connectivity to master..."
timeout 30 bash -c "until ncat -z ${master_ip} 6443; do sleep 2; done"
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot connect to master at ${master_ip}:6443"
    exit 1
fi

curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$NODE_TOKEN sh -s - agent \
  --node-label="node-role=worker" \
  --kubelet-arg="--max-pods=110" \
  --kubelet-arg="--node-status-update-frequency=10s" \
  --kubelet-arg="--image-gc-high-threshold=70" \
  --kubelet-arg="--image-gc-low-threshold=50"

echo "Waiting for K3s agent to be ready..."
sleep 30

systemctl status k3s-agent

cat > /home/ec2-user/check-node.sh << 'EOF'
#!/bin/bash
echo "=== K3s Agent Status ==="
echo "Service status:"
systemctl status k3s-agent --no-pager
echo ""
echo "Node processes:"
ps aux | grep k3s
echo ""
echo "Agent logs (last 20 lines):"
journalctl -u k3s-agent -n 20 --no-pager
EOF

chmod +x /home/ec2-user/check-node.sh
chown ec2-user:ec2-user /home/ec2-user/check-node.sh

echo "K3s worker node configured on $(date)" > /var/log/k3s-worker-status.txt
echo "K3s Worker node configuration completed successfully!"

echo "Worker node ready!"
echo "Connected to master: ${master_ip}" 