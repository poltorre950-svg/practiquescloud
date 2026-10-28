provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/25"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subred-a"
  }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/23"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subred-b"
  }
}

resource "aws_subnet" "c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.33.0/28"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subred-c"
  }
}

resource "aws_instance" "web" {
  for_each = {
    "instancia-1" = aws_subnet.a
    "instancia-2" = aws_subnet.b
    "instancia-3" = aws_subnet.c
    "instancia-4" = aws_subnet.a
    "instancia-5" = aws_subnet.b
    "instancia-6" = aws_subnet.c
  }

  ami           = "ami-04b938437b69a2c9c" # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"
  subnet_id     = each.value.id

  tags = {
    Name = each.key
  }
}
