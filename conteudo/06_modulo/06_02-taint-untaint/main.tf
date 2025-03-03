provider "aws" {
  region "us-east-1" # Erro: Falta de '=' para definir a região
}

resource "aws_instance" "example" {
  ami           "ami-0c55b159cbfafe1f0" # Erro: Falta de '=' para definir o valor da AMI
  instance_type "t2.micro" # Erro: Falta de '=' para definir o tipo de instância

  tags = {
    Name "MinhaInstancia" # Erro: Falta de '=' dentro do bloco de tags
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "meu-bucket-exemplo"
  
  acl "private" # Erro: Falta de '=' para definir o ACL

  versioning {
    enabled = true
  }
}
