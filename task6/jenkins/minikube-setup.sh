#!/bin/bash

set -e

echo "🚀 Setting up Minikube environment for Jenkins CI/CD..."

if ! minikube status > /dev/null 2>&1; then
    echo "🔧 Starting minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
fi

echo "🔌 Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable registry
minikube addons enable metrics-server

echo "🐳 Configuring Docker environment..."
eval $(minikube docker-env)

echo "📁 Setting up Kubernetes namespace..."
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Setting up registry port forwarding..."
nohup kubectl port-forward --namespace kube-system service/registry 5000:80 > /dev/null 2>&1 &

sleep 5

echo "🔍 Checking registry connectivity..."
if curl -f http://localhost:5000/v2/ > /dev/null 2>&1; then
    echo "✅ Local registry is accessible at localhost:5000"
else
    echo "⚠️  Registry might not be ready yet, but continuing..."
fi

echo "👤 Setting up Jenkins RBAC..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: default
EOF

echo "📋 Environment Information:"
echo "Minikube IP: $(minikube ip)"
echo "Kubectl context: $(kubectl config current-context)"
echo "Docker registry: localhost:5000"
echo "Ingress enabled: $(minikube addons list | grep ingress | awk '{print $4}')"

echo "🎉 Minikube environment setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Configure Jenkins to use this Kubernetes cluster"
echo "2. Set KUBECONFIG in Jenkins environment"
echo "3. Ensure Docker is accessible from Jenkins"
echo "4. Run your CI/CD pipeline!" 