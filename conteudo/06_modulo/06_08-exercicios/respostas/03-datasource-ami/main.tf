provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

locals {
  instance_details = {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
  }
}

resource "aws_instance" "example" {
  ami           = local.instance_details.ami
  instance_type = local.instance_details.instance_type
}

output "instance_info" {
  value = local.instance_details
}
