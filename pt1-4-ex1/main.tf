provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count = 2

  ami           = "ami-04b938437b69a2c9c" # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"

  tags = {
    Name = "Instancia-${count.index + 1}"
  }
}
