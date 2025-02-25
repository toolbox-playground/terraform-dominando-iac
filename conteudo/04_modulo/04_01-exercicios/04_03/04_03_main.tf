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

# Criando uma sub-rede pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# Criando uma instância EC2 na sub-rede pública
resource "aws_instance" "web" {
  ami             = "ami-0c55b159cbfafe1f0"  # Altere para uma AMI válida na sua região
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id

  tags = {
    Name = "WebServer"
  }
}

# Criando um bucket S3
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-terraform-bucket-123456789" # Escolha um nome único

  tags = {
    Name = "MyBucket"
  }
}

# Criando um banco de dados RDS
resource "aws_db_instance" "db" {
  allocated_storage    = 20
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  identifier          = "mydb-instance"
  username           = "admin"
  password           = "Terraform123!"  # Apenas para fins de teste, nunca use senha em código real
  skip_final_snapshot = true
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

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}
