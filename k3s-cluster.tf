resource "aws_iam_role" "k3s_node_role" {
  name = "${var.project_name}-k3s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-k3s-node-role"
  })
}

resource "aws_iam_role_policy" "k3s_node_ssm_policy" {
  name = "${var.project_name}-k3s-node-ssm-policy"
  role = aws_iam_role.k3s_node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/k3s/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k3s_node_profile" {
  name = "${var.project_name}-k3s-node-profile"
  role = aws_iam_role.k3s_node_role.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-k3s-node-profile"
  })
}

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

resource "aws_ssm_parameter" "k3s_token" {
  name  = "/k3s/node-token"
  type  = "SecureString"
  value = "placeholder"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-k3s-token"
  })

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.k3s_nodes.id
  instance_type          = var.k3s_master_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.k3s_node_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data/k3s-master.sh", {
    cluster_name    = var.k3s_cluster_name
    ssm_token_param = aws_ssm_parameter.k3s_token.name
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
  iam_instance_profile   = aws_iam_instance_profile.k3s_node_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data/k3s-worker.sh", {
    master_ip       = aws_instance.k3s_master.private_ip
    ssm_token_param = aws_ssm_parameter.k3s_token.name
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