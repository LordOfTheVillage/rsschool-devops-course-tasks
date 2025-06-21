resource "aws_security_group" "nat_instance" {
  name_prefix = "${var.project_name}-nat-"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from private subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "All TCP from private subnets"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "private_instances" {
  name_prefix = "${var.project_name}-private-"
  description = "Security group for instances in private subnets"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "All UDP from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}