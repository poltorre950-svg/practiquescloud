# Proveedor AWS
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "vpc_03" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC-03"
  }
}

# Subred pública A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet A"
  }
}

# Subred pública B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet B"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_03.id

  tags = {
    Name = "IGW-VPC-03"
  }
}

# Tabla de rutas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_03.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Asociación tabla de rutas - subred A
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Asociación tabla de rutas - subred B
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Grupo de seguridad
resource "aws_security_group" "sg" {
  name        = "ec2-sg"
  description = "SSH, ICMP desde VPC, egress abierto"
  vpc_id      = aws_vpc.vpc_03.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-EC2"
  }
}

# AMI Amazon Linux
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instancia EC2 A
resource "aws_instance" "ec2_a" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "ec2-a"
  }
}

# Instancia EC2 B
resource "aws_instance" "ec2_b" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_b.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "ec2-b"
  }
}
