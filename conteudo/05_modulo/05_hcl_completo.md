# Módulo 05 - HCL

## Exemplo Completo de HCL

```yaml
# Variáveis
variable "region" {
  default = "us-west-2"
}

# Provedor
provider "aws" {
  region = var.region
}

# Recurso
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  count         = 2

  tags = {
    Name = "WebServer-${count.index + 1}"
  }
}

# Output
output "instance_ips" {
  value = aws_instance.web[*].public_ip
}
```
