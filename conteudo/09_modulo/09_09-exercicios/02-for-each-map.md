# Exercício 02 - for_each a partir de um Map

*(Integra o exercício original 22)*

## Objetivo

Criar recursos dinamicamente a partir de um map de configurações, com identidades estáveis.

## Tarefa

1. Criar uma variável `instancias` do tipo `map(object({ ami = string, tipo = string }))`.
2. Preencher com ao menos 3 entradas (ex.: `web`, `api`, `worker`).
3. Criar recursos `aws_instance` iterando com `for_each`.
4. Usar `each.key` no `Name` e no `tags.role`.
5. Expor outputs com `{for k, v in aws_instance.srv : k => v.public_ip}`.

## Dicas

```hcl
variable "instancias" {
  type = map(object({
    ami  = string
    tipo = string
  }))
  default = {
    web    = { ami = "ami-0c7217cdde317cfec", tipo = "t3.micro" }
    api    = { ami = "ami-0c7217cdde317cfec", tipo = "t3.small" }
    worker = { ami = "ami-0c7217cdde317cfec", tipo = "t3.medium" }
  }
}

resource "aws_instance" "srv" {
  for_each = var.instancias

  ami           = each.value.ami
  instance_type = each.value.tipo

  tags = {
    Name = each.key
    Role = each.key
  }
}

output "ips" {
  value = { for k, v in aws_instance.srv : k => v.public_ip }
}
```

## Verificação

- `terraform state list` deve listar `aws_instance.srv["web"]`, etc.
- Remover uma entrada do map e aplicar: **só a instância removida** deve ser destruída.

## Desafio extra

- Adicionar atributo opcional `public = optional(bool, false)` e criar EIP apenas para as públicas.
