provider "aws" {
  region = "us-west-2"
}

# Criando uma VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# Criando uma instância EC2
resource "aws_instance" "web" {
  ami             = "ami-0cf2b4e024cdb6960"  # Altere para uma AMI válida na sua região
  instance_type   = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}

# Criando um bucket S3
resource "aws_s3_bucket" "my_bucket" {
  bucket = "shubsttttttsuper" # Escolha um nome único

  tags = {
    Name = "MyBucket"
  }
}

# Outputs para visualizar os recursos criados
output "vpc_id" {
  value = aws_vpc.main.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
