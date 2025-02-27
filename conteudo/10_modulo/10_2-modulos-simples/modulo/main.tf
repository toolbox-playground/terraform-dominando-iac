resource "aws_s3_bucket" "this" {
  bucket = "meu-bucket-fixo-123456789"

  tags = {
    Name        = "meu-bucket-fixo"
    Environment = "production"
  }
}

# Habilitando versionamento
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
