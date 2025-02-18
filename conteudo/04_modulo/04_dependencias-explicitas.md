# Módulo 04 - Terraform Core Workflow

## Dependências Explicitas - Exemplo completo

```yaml
# Recurso de banco de dados
resource "aws_db_instance" "example" {
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  # ... outras configurações
}

# Recurso de aplicação que depende do banco de dados
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Configurando conexão com o banco de dados..."
              # Configuração da aplicação para usar o banco de dados
              EOF

  depends_on = [aws_db_instance.example]
}

# Grupo de segurança que precisa ser criado após a VPC
resource "aws_security_group" "allow_traffic" {
  name        = "allow_specific_traffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Regras do grupo de segurança...

  depends_on = [aws_vpc.main]
}
```