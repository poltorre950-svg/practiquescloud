provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count = 2

  # AMI gratuita de Amazon Linux 2023 en us-east-1.
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"

  tags = {
    Name = "Instancia-${count.index + 1}"
  }
}
