provider "aws" {
  region = "us-east-1"
}

# Criando uma única instância EC2
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Substitua por uma AMI válida
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}

# Criando múltiplos buckets S3 usando count (necessário para usar splat `[*]`)
variable "bucket_names" {
  default = ["logs-bucket", "backup-bucket", "data-bucket"]
}

resource "aws_s3_bucket" "buckets" {
  count  = length(var.bucket_names)
  bucket = "${var.bucket_names[count.index]}-123456789"

  tags = {
    Name = var.bucket_names[count.index]
  }
}

# **Uso de splat para acessar o ID da instância EC2 (não necessário, mas incluído para exemplo)**
output "instance_id" {
  value = [aws_instance.web[*].id]  # Transforma o valor único em uma lista
}

# **Uso correto do splat `[*]` para acessar os IDs dos buckets**
output "bucket_names" {
  value = aws_s3_bucket.buckets[*].id
}
