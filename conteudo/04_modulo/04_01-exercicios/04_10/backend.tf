terraform {
  backend "s3" {
    bucket         = "my-terraform-remote-state-123456789"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}