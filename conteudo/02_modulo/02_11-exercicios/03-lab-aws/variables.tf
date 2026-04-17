variable "aws_region" {
  description = "Região AWS onde criar a instância"
  type        = string
  default     = "us-west-2"
}

variable "amis" {
  description = "AMI Ubuntu por região"
  type        = map(string)
  default = {
    us-east-1 = "ami-0c7217cdde317cfec"
    us-west-2 = "ami-0cf2b4e024cdb6960"
  }
}
