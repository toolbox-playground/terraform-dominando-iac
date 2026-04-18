# 09_05 - `dynamic` Blocks

Alguns recursos usam **sub-blocos repetidos** (ex.: `ingress` em security group, `setting` em ASG). Quando a lista desses sub-blocos é dinâmica, use `dynamic`.

## Problema que resolve

Sem `dynamic`:

```hcl
resource "aws_security_group" "web" {
  name = "web"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Se quiser variar a lista de portas por ambiente → impossível sem duplicar código.

## Sintaxe

```hcl
dynamic "NOME_DO_BLOCO" {
  for_each = COLECAO

  content {
    # atributos do bloco, usando NOME_DO_BLOCO.value
  }
}
```

## Exemplo: ingress dinâmico

```hcl
variable "regras_ingress" {
  type = list(object({
    descricao = string
    porta     = number
    cidrs     = list(string)
  }))

  default = [
    { descricao = "HTTP",  porta = 80,  cidrs = ["0.0.0.0/0"] },
    { descricao = "HTTPS", porta = 443, cidrs = ["0.0.0.0/0"] },
    { descricao = "SSH",   porta = 22,  cidrs = ["10.0.0.0/8"] },
  ]
}

resource "aws_security_group" "web" {
  name = "web"

  dynamic "ingress" {
    for_each = var.regras_ingress

    content {
      description = ingress.value.descricao
      from_port   = ingress.value.porta
      to_port     = ingress.value.porta
      protocol    = "tcp"
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

## Variáveis disponíveis em `content`

| Variável | Uso |
|----------|-----|
| `NOME.key` | Chave da iteração |
| `NOME.value` | Valor (objeto/string/number) |

Onde `NOME` é o primeiro argumento de `dynamic`. Ex.: `ingress.key`, `ingress.value`.

## `for_each` pode ser map

```hcl
dynamic "setting" {
  for_each = {
    "ecs_managed_draining" = "ENABLED"
    "containerInsights"    = "enhanced"
  }

  content {
    name  = setting.key
    value = setting.value
  }
}
```

## `dynamic` aninhado

Raro, mas possível:

```hcl
resource "aws_autoscaling_group" "app" {
  # ...

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
```

Se um sub-bloco tiver outro `dynamic` dentro:

```hcl
dynamic "rule" {
  for_each = var.regras

  content {
    priority = rule.value.priority
    dynamic "action" {
      for_each = rule.value.acoes
      content {
        type = action.value.tipo
      }
    }
  }
}
```

## `dynamic` condicional

Para incluir um bloco só em certos casos:

```hcl
dynamic "lifecycle_rule" {
  for_each = var.habilitar_expiracao ? [1] : []

  content {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
```

Lista `[1]` faz o bloco aparecer uma vez; `[]` o omite.

## Quando **não** usar `dynamic`

- Quando você tem **sempre** as mesmas 2-3 regras — escreva estáticas, fica mais legível.
- Quando as regras diferem muito em estrutura (alguns campos presentes, outros não) — explicite cada caso.
- Quando a clareza sofre mais do que se beneficia.

## Performance

`dynamic` adiciona um grafo extra internamente. Em quantidades normais (<100 iterações) é imperceptível. Em quantidades extremas (milhares), considere revisar design.

## `dynamic` vs. `for_each` no recurso

| | `dynamic` no bloco | `for_each` no recurso |
|---|-------------------|-----------------------|
| Finalidade | Repetir **sub-bloco** | Repetir **recurso inteiro** |
| Exemplo | `ingress` em SG | `aws_iam_user` por usuário |
| Referenciar fora | `aws_sg.web.ingress` (lista) | `aws_iam_user.x["alice"]` |

Os dois se combinam bem: recursos `for_each` + sub-blocos `dynamic`.

## Erros comuns

### `content` esquecido

```hcl
# Errado
dynamic "ingress" {
  for_each = var.regras
  from_port = ingress.value.porta   # erro
}

# Certo
dynamic "ingress" {
  for_each = var.regras
  content {
    from_port = ingress.value.porta
  }
}
```

### Tipo incompatível em `for_each`

`for_each` aceita `map` ou `list`. Se passar `set`, cada item é string; `ingress.value` será string.

### Nome do bloco incorreto

`dynamic "ingress"` não funciona se o recurso não tem sub-bloco `ingress`. Consulte a doc do recurso.

## Exemplo completo

```hcl
variable "reglas" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = {
    http  = { description = "HTTP",  from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    https = { description = "HTTPS", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ssh   = { description = "SSH",   from_port = 22,  to_port = 22,  protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] }
  }
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.reglas

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}
```

Próximo tópico: **`lifecycle`**.
