provider "aws" {
  region = "us-west-2"
}

variable "instances" {
  type = map(object({
    ami           = string
    instance_type = string
  }))
  default = {
    "inst1" = {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"
    },
    "inst2" = {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.small"
    }
  }
}

resource "aws_instance" "example" {
  for_each      = var.instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
}
