
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "remote-state-bucket"
    key          = "aws-lab/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# ================================================================
# 1. VPC
# ================================================================

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# ================================================================
# 2. PUBLIC SUBNET
# ================================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-subnet"
  }
}

# ================================================================
# 3. INTERNET GATEWAY
# ================================================================

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# ================================================================
# 4. ROUTE TABLE
# ================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ================================================================
# 5. SECURITY GROUP
# ================================================================

resource "aws_security_group" "ec2" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Allow SSH from trusted IP"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}

# ================================================================
# 6. AMAZON LINUX AMI
# ================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ================================================================
# 7. EC2 INSTANCE
# ================================================================

resource "aws_instance" "lab" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 36
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-ec2"
  }
}

# ================================================================
# 8. EBS DATA VOLUME
# ================================================================

resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.name_prefix}-data"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.lab.id
}

# ================================================================
# 9. INTERNAL NETWORK LOAD BALANCER
# ================================================================

# resource "aws_lb" "internal" {
#   name               = "${var.name_prefix}-nlb"
#   internal           = true
#   load_balancer_type = "network"

#   subnets = [aws_subnet.public.id]

#   tags = {
#     Name = "${var.name_prefix}-nlb"
#   }
# }

# ================================================================
# 10. TARGET GROUP
# ================================================================

# resource "aws_lb_target_group" "app" {
#   name        = "${var.name_prefix}-tg"
#   port        = 8080
#   protocol    = "TCP"
#   vpc_id      = aws_vpc.lab.id
#   target_type = "instance"

#   health_check {
#     protocol = "TCP"
#     port     = "traffic-port"
#   }
# }

# ================================================================
# 11. TARGET REGISTRATION
# ================================================================

# resource "aws_lb_target_group_attachment" "ec2" {
#   target_group_arn = aws_lb_target_group.app.arn
#   target_id        = aws_instance.lab.id
#   port             = 8080
# }

# ================================================================
# 12. NLB LISTENER
# ================================================================

# resource "aws_lb_listener" "tcp_80" {
#   load_balancer_arn = aws_lb.internal.arn
#   port              = 80
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }
