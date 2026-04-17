resource "aws_instance" "example" {
  ami           = lookup(var.amis, var.aws_region)
  instance_type = "t3.micro"

  tags = {
    Name = "Toolbox-Playground-AWS-1"
  }
}
