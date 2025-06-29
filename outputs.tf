output "aws_region" {
  value = var.aws_region
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}

output "github_actions_role_name" {
  value = aws_iam_role.github_actions_role.name
}

output "github_actions_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}

output "environment" {
  value = var.environment
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# NAT Instance Outputs
output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = aws_instance.nat_instance.id
}

output "nat_instance_private_ip" {
  description = "Private IP address of the NAT instance"
  value       = aws_instance.nat_instance.private_ip
}

output "nat_instance_public_ip" {
  description = "Public IP address of the NAT instance"
  value       = aws_eip.nat_instance.public_ip
}

# Bastion Host Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "nat_security_group_id" {
  description = "ID of the NAT instance security group"
  value       = aws_security_group.nat_instance.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion.id
}

output "private_instances_security_group_id" {
  description = "ID of the private instances security group"
  value       = aws_security_group.private_instances.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "k3s_master_instance_id" {
  description = "ID of the K3s master node"
  value       = aws_instance.k3s_master.id
}

output "k3s_worker_instance_id" {
  description = "ID of the K3s worker node"
  value       = aws_instance.k3s_worker.id
}

output "k3s_master_private_ip" {
  description = "Private IP of the K3s master node"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ip" {
  description = "Private IP of the K3s worker node"
  value       = aws_instance.k3s_worker.private_ip
}

output "k3s_cluster_security_group_id" {
  description = "ID of the K3s cluster security group"
  value       = aws_security_group.k3s_cluster.id
}

output "ssh_connection_commands" {
  description = "SSH connection commands for accessing instances"
  value = {
    bastion_ssh            = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
    nat_via_bastion        = "ssh -i ${var.key_pair_name}.pem -J ec2-user@${aws_eip.bastion.public_ip} ec2-user@${aws_instance.nat_instance.private_ip}"
    k3s_master_via_bastion = "ssh -i ${var.key_pair_name}.pem -J ec2-user@${aws_eip.bastion.public_ip} ec2-user@${aws_instance.k3s_master.private_ip}"
    k3s_worker_via_bastion = "ssh -i ${var.key_pair_name}.pem -J ec2-user@${aws_eip.bastion.public_ip} ec2-user@${aws_instance.k3s_worker.private_ip}"
  }
}

output "kubectl_setup_commands" {
  description = "Commands to set up kubectl access"
  value = {
    setup_on_bastion    = "ssh to bastion and run: ./setup-kubectl.sh"
    bastion_ssh_command = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_eip.bastion.public_ip}"
    test_cluster        = "Run on bastion: ./k8s-commands.sh test"
    deploy_test_pod     = "Run on bastion: ./k8s-commands.sh deploy"
  }
}

output "local_kubectl_setup" {
  description = "Setup kubectl on local machine"
  value = {
    port_forward_command = "ssh -i ${var.key_pair_name}.pem -L 6443:${aws_instance.k3s_master.private_ip}:6443 ec2-user@${aws_eip.bastion.public_ip}"
    copy_kubeconfig      = "scp -i ${var.key_pair_name}.pem -o ProxyJump=ec2-user@${aws_eip.bastion.public_ip} ec2-user@${aws_instance.k3s_master.private_ip}:/home/ec2-user/.kube/config ~/.kube/config-k3s"
    usage_note           = "After copying kubeconfig, edit it to change server to https://localhost:6443 and use with KUBECONFIG=~/.kube/config-k3s kubectl get nodes"
  }
}