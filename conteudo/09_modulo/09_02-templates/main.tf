provider "aws" {
  region = "us-east-1"
}

variable "bucket_name" {
  default = "meu-bucket-exemplo"
}

variable "environment" {
  default = "production"
}

variable "enable_versioning" {
  default = true
}

# Usando templatefile para criar configurações dinâmicas
locals {
  bucket_config = templatefile("template.tftpl", {
    bucket_name      = var.bucket_name
    environment      = var.environment
    enable_versioning = var.enable_versioning
  })
}

# Criando o bucket S3
resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# Output para visualizar a configuração gerada
output "bucket_config" {
  value = local.bucket_config
}
