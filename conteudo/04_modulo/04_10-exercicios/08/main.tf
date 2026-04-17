provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket-terraform-123"

  tags = {
    Name = "ExampleBucket"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.example.id
}
