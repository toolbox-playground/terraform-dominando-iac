# Módulo 09 - HCL Avançado

## Lifecycle

```yaml
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
    ignore_changes = [tags]
    replace_triggered_by = [aws_security_group.example]
  }
}
```
