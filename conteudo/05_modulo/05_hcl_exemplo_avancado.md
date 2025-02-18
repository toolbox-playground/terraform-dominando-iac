# Módulo 05 - HCL

## Exemplo Completo e Avançado de HCL

```yaml
variable "environments" {
  default = ["dev", "staging", "prod"]
}

resource "aws_instance" "app" {
  for_each = toset(var.environments)

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value == "prod" ? "t2.medium" : "t2.micro"

  tags = {
    Name = "App-${each.value}"
    Environment = each.value
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags]
  }

  depends_on = [aws_vpc.main]
}
```
