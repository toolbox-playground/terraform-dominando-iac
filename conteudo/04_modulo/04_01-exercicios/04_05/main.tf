provider "aws" {
  region = "us-east-1"
}

# Criando uma VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# Criando uma sub-rede pública dentro da VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id  # Dependência implícita!
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# Criando uma instância EC2 dentro da sub-rede pública
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Altere para uma AMI válida na sua região
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id  # Dependência implícita!

  tags = {
    Name = "WebServer"
  }
}

# Outputs para visualizar os recursos criados
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}