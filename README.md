# RS School DevOps Course - Task 3: Kubernetes Cluster

AWS Kubernetes cluster deployment using k3s with Terraform and bastion host access for RSSchool DevOps course.

## 🎯 Task Overview

Deploy a 2-node Kubernetes cluster using k3s on AWS EC2 instances with:

- ✅ Master node in private subnet (AZ-a)
- ✅ Worker node in private subnet (AZ-b)
- ✅ Access via bastion host
- ✅ Local machine access through SSH tunneling
- ✅ Simple workload deployment (nginx pod)

## 🏗️ Infrastructure Architecture

```
Internet
   │
   ├── Bastion Host (Public) - SSH access + kubectl
   ├── NAT Instance (Public) - Internet access for private subnets
   │
   └── VPC (10.0.0.0/16)
       ├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
       └── Private Subnets (10.0.10.0/24, 10.0.20.0/24)
           ├── K3s Master Node (10.0.10.x) - AZ-a
           └── K3s Worker Node (10.0.20.x) - AZ-b
```

## 🛠️ What's Included

### Infrastructure Components

- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **EC2 Instances**:
  - Bastion host (t2.micro) with kubectl pre-installed
  - NAT instance (t2.micro) for private subnet internet access
  - K3s master node (t2.micro) in private subnet
  - K3s worker node (t2.micro) in private subnet
- **Security Groups**: Properly configured for K8s cluster communication
- **IAM Roles**: SSM access for cluster node communication
- **SSM Parameter**: Secure storage for K3s node token

### Kubernetes Setup

- **K3s cluster**: Lightweight Kubernetes distribution
- **Flannel CNI**: Default networking for pod communication
- **kubectl**: Pre-configured on bastion host
- **Cluster access**: Both from bastion and local machine

## 📋 Prerequisites

1. **AWS Account** with Free Tier access
2. **AWS CLI** configured with appropriate permissions
3. **Terraform** installed (v1.0+)
4. **SSH key pair** created in AWS (default: `rsschool-devops-key`)
5. **kubectl** installed on local machine (for local access)

## 🚀 Deployment Steps

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd rsschool-devops-course-tasks-1
git checkout task_3
```

### 2. Review Configuration

Check `variables.tf` for default values:

```hcl
aws_region = "eu-west-2"
vpc_cidr = "10.0.0.0/16"
key_pair_name = "rsschool-devops-key"  # Your SSH key name
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

⏱️ **Deployment time**: ~8-10 minutes

- Infrastructure creation: ~3 minutes
- K3s cluster initialization: ~5-7 minutes

### 4. Wait for Cluster Initialization

The K3s cluster needs time to initialize after EC2 instances are created:

```bash
# Check deployment status
terraform output
```

## 🔧 Accessing the Cluster

### Option A: From Bastion Host (Recommended)

1. **SSH to bastion:**

```bash
ssh -i rsschool-devops-key.pem ec2-user@<BASTION_PUBLIC_IP>
```

2. **Setup kubectl access:**

```bash
# Run the setup script (wait 3-5 minutes after terraform apply)
./setup-kubectl.sh
```

3. **Verify cluster:**

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

4. **Deploy test workload:**

```bash
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
kubectl get pod nginx
```

### Option B: From Local Machine

1. **Use the setup script:**

```bash
# Get values from terraform output
chmod +x setup/local-kubectl.sh
./setup/local-kubectl.sh -b <BASTION_IP> -k ~/.ssh/rsschool-devops-key.pem -m <MASTER_PRIVATE_IP>
```

2. **Start port forwarding (Terminal 1):**

```bash
~/.kube/k3s-port-forward.sh
# Keep this running
```

3. **Use kubectl (Terminal 2):**

```bash
KUBECONFIG=~/.kube/config-k3s kubectl get nodes
KUBECONFIG=~/.kube/config-k3s kubectl get pods --all-namespaces
```

## 📊 Verification Commands

### Check Cluster Status

```bash
# From bastion or local (with proper kubeconfig)
kubectl get nodes -o wide
kubectl get pods --all-namespaces
kubectl cluster-info
```

### Deploy and Test Workload

```bash
# Deploy nginx pod
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml

# Check pod status
kubectl get pod nginx
kubectl describe pod nginx

# Check logs
kubectl logs nginx

# Cleanup
kubectl delete pod nginx
```

### Helper Scripts (on bastion)

```bash
# Show available commands
./k8s-commands.sh

# Quick cluster test
./k8s-commands.sh test

# Deploy test pod
./k8s-commands.sh deploy

# Check nodes
./k8s-commands.sh nodes
```

## 📸 Required Screenshots

For task submission, capture these outputs:

1. **kubectl get nodes** (showing 2 nodes):

```bash
kubectl get nodes
```

2. **kubectl get all --all-namespaces** (showing nginx pod):

```bash
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
kubectl get all --all-namespaces
```

## 🔍 Troubleshooting

### Cluster Not Ready

```bash
# Check master node logs
ssh -J ec2-user@<BASTION_IP> ec2-user@<MASTER_IP>
sudo journalctl -u k3s

# Check worker node logs
ssh -J ec2-user@<BASTION_IP> ec2-user@<WORKER_IP>
sudo journalctl -u k3s-agent
```

### kubectl Access Issues

```bash
# Re-run setup on bastion
./setup-kubectl.sh

# Check kubeconfig
cat ~/.kube/config

# Test basic connectivity
kubectl version --client
```

### Local Access Issues

```bash
# Verify port forwarding
netstat -an | grep 6443

# Check kubeconfig
KUBECONFIG=~/.kube/config-k3s kubectl config view
```

## 💰 AWS Free Tier Usage

**Instance Hours per Month:**

- Bastion: t2.micro (24/7) = ~750 hours
- NAT: t2.micro (24/7) = ~750 hours
- K3s Master: t2.micro (24/7) = ~750 hours
- K3s Worker: t2.micro (24/7) = ~750 hours
- **Total: ~3000 hours** (exceeds 750 hour limit)

**Cost Optimization:**

- Stop cluster when not in use: `terraform destroy`
- Use smaller instances for testing
- Consider using NAT Gateway only when needed

## 🏗️ Infrastructure Details

### Terraform Resources

```
├── vpc.tf                # VPC, subnets, routing
├── security.tf           # Security groups + K8s cluster SG
├── bastion.tf            # Bastion host with kubectl
├── nat.tf                # NAT instance
├── k3s-cluster.tf        # K8s cluster nodes + IAM roles
├── variables.tf          # Configuration variables
├── outputs.tf            # Infrastructure outputs
└── user_data/            # Instance initialization scripts
    ├── bastion.sh        # Bastion + kubectl setup
    ├── k3s-master.sh     # K3s server installation
    └── k3s-worker.sh     # K3s agent installation
```

### Security Groups

- **Bastion SG**: SSH (22) from internet
- **NAT SG**: HTTP/HTTPS from private subnets
- **K3s Cluster SG**: K8s ports (6443, 8472, 10250, etc.) within VPC

### Key Features

- **Automatic cluster setup**: No manual intervention required
- **Secure communication**: K3s token stored in SSM Parameter Store
- **High availability**: Nodes in different AZs
- **Production-ready**: Proper security groups and IAM roles

## 📚 Useful Commands

### Terraform

```bash
terraform plan                    # Review changes
terraform apply                   # Deploy infrastructure
terraform destroy                 # Cleanup all resources
terraform output                  # Show important outputs
```

### SSH Access

```bash
# Bastion host
ssh -i key.pem ec2-user@<BASTION_IP>

# K3s master via bastion
ssh -i key.pem -J ec2-user@<BASTION_IP> ec2-user@<MASTER_IP>

# K3s worker via bastion
ssh -i key.pem -J ec2-user@<BASTION_IP> ec2-user@<WORKER_IP>
```

### Kubernetes

```bash
kubectl get nodes -o wide         # Cluster nodes
kubectl get pods --all-namespaces # All pods
kubectl describe node <node>      # Node details
kubectl top nodes                 # Resource usage
```

## 🎯 Task Completion Checklist

- [x] K3s cluster with 2 nodes deployed
- [x] Cluster accessible from bastion host
- [x] Cluster accessible from local machine
- [x] Simple workload (nginx) deployable
- [x] Terraform code for all infrastructure
- [x] Security groups properly configured
- [x] Documentation complete
- [x] Screenshots ready for submission

## 📞 Support

For issues or questions:

1. Check troubleshooting section above
2. Review Terraform outputs: `terraform output`
3. Check instance logs via SSH
4. Verify security group rules in AWS console

---

**Task 3 - Kubernetes Cluster Deployment** ✅  
RS School DevOps Course 2025
