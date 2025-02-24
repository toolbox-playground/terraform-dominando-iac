terraform {
  backend "s3" {
    bucket  = "meu-bucket-terraform"
    key     = "caminho/para/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "MinhaInstancia"
  }
}
