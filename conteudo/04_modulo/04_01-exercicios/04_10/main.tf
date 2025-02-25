provider "aws" {
  region = "us-east-1"
}

# Criando um bucket S3 de exemplo
resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket-terraform-123"

  tags = {
    Name        = "ExampleBucket"
    Environment = "Dev"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.example.id
}