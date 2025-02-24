variable "ami" {
  description = "AMI ID para criar a instância"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # valor padrão (pode ser sobrescrito)
}

variable "instance_type" {
  description = "Tipo de instância"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Nome da instância (tag Name)"
  type        = string
  default     = "MinhaInstancia"
}
