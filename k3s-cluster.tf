

data "aws_ami" "k3s_nodes" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "random_password" "k3s_token" {
  length  = 64
  special = true
}

resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.k3s_nodes.id
  instance_type          = var.k3s_master_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data/k3s-master.sh", {
    cluster_name = var.k3s_cluster_name
    k3s_token    = random_password.k3s_token.result
  }))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-k3s-master"
    Type = "k3s-master"
    Task = "task_3"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "k3s_worker" {
  ami                    = data.aws_ami.k3s_nodes.id
  instance_type          = var.k3s_worker_instance_type
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data/k3s-worker.sh", {
    master_ip = aws_instance.k3s_master.private_ip
    k3s_token = random_password.k3s_token.result
  }))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-k3s-worker"
    Type = "k3s-worker"
    Task = "task_3"
  })

  depends_on = [aws_instance.k3s_master]

  lifecycle {
    create_before_destroy = true
  }
} 