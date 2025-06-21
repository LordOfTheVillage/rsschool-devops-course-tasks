data "aws_ami" "amazon_linux_x86_nat" {
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

resource "aws_eip" "nat_instance" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_instance" "nat_instance" {
  ami                    = data.aws_ami.amazon_linux_x86_nat.id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.nat_instance.id]
  source_dest_check      = false
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data/nat_instance.sh", {}))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-instance"
    Type = "nat"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "nat_instance" {
  instance_id   = aws_instance.nat_instance.id
  allocation_id = aws_eip.nat_instance.id
}

resource "aws_route" "private_nat" {
  count = length(aws_route_table.private)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id

  depends_on = [aws_instance.nat_instance]
} 