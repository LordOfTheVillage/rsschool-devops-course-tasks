#!/bin/bash

exec > >(tee /var/log/k3s-master-setup.log)
exec 2>&1

echo "Starting K3s Master node configuration..."

yum update -y

yum install -y \
    curl \
    wget \
    htop \
    vim

echo "Installing K3s server..."

LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "Local IP detected: $LOCAL_IP"

curl -sfL https://get.k3s.io | K3S_TOKEN="${k3s_token}" sh -s - server \
  --write-kubeconfig-mode=644 \
  --cluster-domain="${cluster_name}.local" \
  --node-label="node-role=master" \
  --bind-address=0.0.0.0 \
  --advertise-address=$LOCAL_IP \
  --disable=traefik \
  --disable=servicelb \
  --disable=metrics-server \
  --kube-controller-manager-arg="--node-monitor-period=40s" \
  --kube-controller-manager-arg="--node-monitor-grace-period=40s" \
  --kubelet-arg="--max-pods=110"

echo "Waiting for K3s to be ready..."
sleep 30

systemctl status k3s

echo "Using pre-generated cluster token..."
echo "Token configured successfully"

mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

cp /etc/rancher/k3s/k3s.yaml /etc/kubernetes/
chmod 644 /etc/kubernetes/k3s.yaml

echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

sleep 60

echo "Testing K3s cluster..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
kubectl get pods --all-namespaces

cat > /home/ec2-user/check-cluster.sh << 'EOF'
#!/bin/bash
export KUBECONFIG=/home/ec2-user/.kube/config
echo "=== K3s Cluster Status ==="
echo "Nodes:"
kubectl get nodes
echo ""
echo "All Pods:"
kubectl get pods --all-namespaces
echo ""
echo "Cluster Info:"
kubectl cluster-info
EOF

chmod +x /home/ec2-user/check-cluster.sh
chown ec2-user:ec2-user /home/ec2-user/check-cluster.sh

echo "K3s master node configured on $(date)" > /var/log/k3s-master-status.txt
echo "K3s Master node configuration completed successfully!"

echo "Master node ready!"
echo "Cluster token configured successfully"
echo "Kubeconfig available at: /home/ec2-user/.kube/config" 