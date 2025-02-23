# Módulo 09 - HCL Avançado

## Usando for_each

### Aceita um mapa ou conjunto de strings, criando uma instância para cada elemento

```yaml
resource "aws_instance" "server" {
  for_each = toset(["web", "app", "db"])
  ami = "ami-a1b2c3d4"
  instance_type = "t2.micro"
  tags = {
    Name = "Server-${each.key}"
  }
}
```
