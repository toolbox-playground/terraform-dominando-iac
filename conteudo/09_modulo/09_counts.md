# Módulo 09 - HCL Avançado

## Usando count

### Aceita um número inteiro e cria esse número de instâncias

```yaml
resource "aws_instance" "server" {
  count = 4
  ami = "ami-a1b2c3d4"
  instance_type = "t2.micro"
  tags = {
    Name = "Server ${count.index}"
  }
}
```
