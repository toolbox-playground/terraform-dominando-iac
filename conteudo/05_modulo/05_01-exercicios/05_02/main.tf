provider "aws" {
  region = "us-east-1"
}

# Criando múltiplas instâncias EC2
resource "aws_instance" "web" {
  count         = 3  # Criará 3 instâncias
  ami           = "ami-0c55b159cbfafe1f0"  # Altere para uma AMI válida na sua região
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer-${count.index + 1}"  # Nomeia cada instância de forma única
  }
}

# Output para listar os IDs das instâncias
output "instance_ids" {
  value = aws_instance.web[*].id
}

# Criando múltiplos buckets S3 com for_each
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs-bucket", "backup-bucket", "data-bucket"])

  bucket = "${each.key}-123456789"  # Garante nomes únicos

  tags = {
    Name = each.key
  }
}

# Output para listar os buckets criados
output "bucket_names" {
  value = [for b in aws_s3_bucket.buckets : b.id]
}

resource "aws_s3_bucket" "protected_bucket" {
  bucket = "protected-bucket-123456789"

  tags = {
    Name = "ProtectedBucket"
  }

  lifecycle {
    prevent_destroy = true  # Impede a destruição acidental
    ignore_changes = [tags]  # Ignora mudanças manuais nas tags
  }
}