# Exercício 01 - Count + Lifecycle (create_before_destroy)

*(Integra o exercício original 21)*

## Objetivo

Gerenciar múltiplas instâncias e garantir que novas sejam criadas **antes** da destruição das antigas — evitando downtime em mudanças de AMI, instance_type, etc.

## Tarefa

1. Criar uma variável `quantidade` (number, default 2).
2. Criar um recurso `aws_instance` usando `count = var.quantidade`.
3. Configurar `lifecycle` com `create_before_destroy = true`.
4. Dar `tags` que incluam `count.index`.
5. Testar uma alteração que force recriação (ex.: mudar `instance_type`) e observar o plano.

## Dicas

```hcl
variable "quantidade" {
  type    = number
  default = 2
}

resource "aws_instance" "web" {
  count = var.quantidade

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "web-${count.index}"
  }
}
```

## Verificação

```bash
terraform apply
# Agora altere var.instance_type e aplique novamente:
terraform apply -var='instance_type=t3.small'
```

No plan deve aparecer `+/-` (create then destroy) ao invés de `-/+`.

## Desafio extra

- Associar uma `aws_eip` a cada instância com `count = var.quantidade`.
- Trocar para `for_each` com um `set` e comparar o diff gerado ao mudar a quantidade.
