resource "aws_instance" "example" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t3.micro"
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t3.micro"

  tags = {
    Name = "Toolbox-Playground-AWS-1"
  }
}