variable "instance_ami" {
  description = "AMI para a instância"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância"
  type        = string
  default     = "t2.micro"
}

resource "aws_instance" "example" {
  ami           = var.instance_ami
  instance_type = var.instance_type
}

output "instance_id" {
  value = aws_instance.example.id
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

module "web_server" {
  source         = "./modulo_instance"
  instance_ami   = "ami-0c55b159cbfafe1f0"
  instance_type  = "t2.micro"
}

output "server_id" {
  value = module.web_server.instance_id
}
