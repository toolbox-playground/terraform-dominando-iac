provider "aws" {
  region = "us-east-1"
}

# Criando uma instância EC2
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Altere para uma AMI válida na sua região
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}

# Criando um bucket S3 para armazenar logs da EC2
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-explicit-dependency-bucket-123"

  tags = {
    Name = "LogBucket"
  }
}

# Configuração de logging (simulada com um output)
resource "null_resource" "log_configuration" {
  depends_on = [aws_instance.web, aws_s3_bucket.log_bucket]  # Forçando a dependência explícita

  provisioner "local-exec" {
    command = "echo 'Configurando logs para a instância EC2 e o bucket S3...'"
  }
}

# Outputs para visualizar os recursos criados
output "instance_id" {
  value = aws_instance.web.id
}

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}
