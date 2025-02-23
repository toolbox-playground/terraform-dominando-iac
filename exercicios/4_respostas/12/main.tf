provider "aws" {
  region = "us-west-2"
}

# Defina a resource com a mesma configuração do recurso existente
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
