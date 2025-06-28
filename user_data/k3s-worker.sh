#!/bin/bash

exec > >(tee /var/log/k3s-worker-setup.log)
exec 2>&1

echo "Starting K3s Worker node configuration..."

yum update -y

yum install -y \
    curl \
    wget \
    htop \
    vim \
    awscli

aws configure set region eu-west-2

echo "Waiting for master node to be ready..."
sleep 120

echo "Retrieving node token from SSM..."
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    NODE_TOKEN=$(aws ssm get-parameter --name "${ssm_token_param}" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null)
    
    if [ ! -z "$NODE_TOKEN" ] && [ "$NODE_TOKEN" != "None" ] && [ "$NODE_TOKEN" != "placeholder" ]; then
        echo "Successfully retrieved node token (attempt $attempt)"
        break
    else
        echo "Waiting for node token... (attempt $attempt/$max_attempts)"
        sleep 30
        ((attempt++))
    fi
done

if [ -z "$NODE_TOKEN" ] || [ "$NODE_TOKEN" == "None" ] || [ "$NODE_TOKEN" == "placeholder" ]; then
    echo "ERROR: Could not retrieve node token from SSM"
    exit 1
fi

K3S_URL="https://${master_ip}:6443"

echo "Installing K3s agent..."
echo "Master IP: ${master_ip}"
echo "K3s URL: $K3S_URL"

curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$NODE_TOKEN sh -s - agent \
  --node-label="node-role=worker"

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
EOF

chmod +x /home/ec2-user/check-node.sh
chown ec2-user:ec2-user /home/ec2-user/check-node.sh

echo "K3s worker node configured on $(date)" > /var/log/k3s-worker-status.txt
echo "K3s Worker node configuration completed successfully!"

echo "Worker node ready!"
echo "Connected to master: ${master_ip}" 