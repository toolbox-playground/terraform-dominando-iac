provider "aws" {
  region = "us-east-1"
}

# Criando um bucket S3
resource "aws_s3_bucket" "example" {
  bucket = "my-drift-example-bucket-123"

  tags = {
    Environment = "Dev"
    Owner       = "Terraform"
  }
}

# Habilitando versionamento no bucket
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.example.id
}
