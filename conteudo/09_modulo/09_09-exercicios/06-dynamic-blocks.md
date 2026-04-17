# Exercício 06 - `dynamic` blocks

## Objetivo

Gerar blocos aninhados dinamicamente a partir de uma lista de configurações.

## Tarefa

1. Definir uma variável `regras_ingress` do tipo:

   ```hcl
   list(object({
     descricao = string
     porta     = number
     protocolo = string
     cidrs     = list(string)
   }))
   ```

2. Criar um `aws_security_group` com um bloco `dynamic "ingress"` que itera sobre a lista.
3. Adicionar também um bloco fixo `egress` liberando saída total.
4. Rodar `plan` e verificar que cada regra da lista virou um bloco `ingress`.

## Dicas

```hcl
variable "regras_ingress" {
  type = list(object({
    descricao = string
    porta     = number
    protocolo = string
    cidrs     = list(string)
  }))
  default = [
    { descricao = "HTTP",  porta = 80,  protocolo = "tcp", cidrs = ["0.0.0.0/0"] },
    { descricao = "HTTPS", porta = 443, protocolo = "tcp", cidrs = ["0.0.0.0/0"] },
    { descricao = "SSH",   porta = 22,  protocolo = "tcp", cidrs = ["10.0.0.0/8"] },
  ]
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "SG web"

  dynamic "ingress" {
    for_each = var.regras_ingress
    content {
      description = ingress.value.descricao
      from_port   = ingress.value.porta
      to_port     = ingress.value.porta
      protocol    = ingress.value.protocolo
      cidr_blocks = ingress.value.cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Verificação

```bash
terraform plan
# Deve aparecer 3 blocos ingress (HTTP, HTTPS, SSH)
```

## Desafio extra

- Criar um segundo `dynamic "tag"` caso você esteja com `aws_autoscaling_group` (que usa blocos `tag` ao invés de `tags = {}`).
- Adicionar uma regra apenas quando `var.ambiente == "dev"` (filtro com `if`).
