provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "example" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

output "instances_ids" {
  value = aws_instance.example[*].id
}
