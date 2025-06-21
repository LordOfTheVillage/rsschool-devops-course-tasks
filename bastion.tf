data "aws_ami" "amazon_linux_x86" {
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

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_x86.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data/bastion.sh", {}))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-host"
    Type = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
} 