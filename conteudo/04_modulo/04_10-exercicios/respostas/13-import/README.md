Resposta
```
provider "aws" {
  region = "us-west-2"
}
```

# Defina a resource com a mesma configuração do recurso existente
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}


### Procedimento de Importação
Supondo que o ID da instância existente seja i-1234567890abcdef0, execute:
```
terraform import aws_instance.example i-1234567890abcdef0
```

Este comando associa o recurso declarado ao recurso real existente, integrando-o ao state do Terraform.