# 09_03 - Expressões `for`

Expressões `for` transformam coleções em outras coleções. Pense em **list comprehensions** do Python / **map/filter/reduce** do mundo funcional.

## Sintaxe

### List comprehension

```hcl
[for x in colecao : expr]
```

### Map comprehension

```hcl
{for k, v in colecao : k => expr}
```

### Com filtro

```hcl
[for x in colecao : expr if condicao]
```

## Exemplos práticos

### Upper em lista

```hcl
locals {
  nomes       = ["alice", "bob", "carol"]
  nomes_upper = [for n in local.nomes : upper(n)]
  # ["ALICE", "BOB", "CAROL"]
}
```

### Filtrar

```hcl
locals {
  numeros = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  pares   = [for n in local.numeros : n if n % 2 == 0]
  # [2, 4, 6, 8, 10]
}
```

### Map → list de valores

```hcl
locals {
  amis = {
    "us-east-1" = "ami-0123"
    "us-west-2" = "ami-0456"
    "eu-west-1" = "ami-0789"
  }

  so_amis = [for v in local.amis : v]
  # ["ami-0123", "ami-0456", "ami-0789"]
}
```

Equivalente a `values(local.amis)`.

### Map → list de objetos

```hcl
locals {
  amis_lista = [for k, v in local.amis : { regiao = k, id = v }]
}
```

### List de objetos → map

Comum para preparar dados para `for_each`:

```hcl
locals {
  usuarios = [
    { nome = "alice", time = "plataforma" },
    { nome = "bob",   time = "app" },
    { nome = "carol", time = "plataforma" },
  ]

  usuarios_por_nome = { for u in local.usuarios : u.nome => u }
}

resource "aws_iam_user" "time" {
  for_each = local.usuarios_por_nome

  name = each.key
  tags = { Time = each.value.time }
}
```

### List com condicional

```hcl
locals {
  zonas       = ["us-east-1a", "us-east-1b", "us-east-1c"]
  zonas_dev   = var.ambiente == "dev" ? [local.zonas[0]] : local.zonas
}
```

## Agrupamento com `...`

Converte duplicatas em lista:

```hcl
locals {
  usuarios = [
    { nome = "alice", time = "plataforma" },
    { nome = "bob",   time = "app" },
    { nome = "carol", time = "plataforma" },
  ]

  por_time = { for u in local.usuarios : u.time => u.nome... }
  # {
  #   plataforma = ["alice", "carol"]
  #   app        = ["bob"]
  # }
}
```

Sem `...`, duplicatas causam erro "Duplicate object key".

## Iteração aninhada

Você pode usar `for` dentro de `for`:

```hcl
locals {
  matriz = [
    ["a", "b"],
    ["c", "d"],
  ]

  planas = flatten([for linha in local.matriz : [for x in linha : x]])
  # ["a", "b", "c", "d"]
}
```

Mais idiomático usar `flatten` + expressão única.

## `for` dentro de strings (templates)

```hcl
locals {
  hosts = ["web1", "web2", "web3"]
  configuracao = <<-EOT
    %{ for h in local.hosts ~}
    server ${h} { port = 80 }
    %{ endfor ~}
  EOT
}
```

Visto no **Módulo 5 - Strings e templating**.

## `for` com `range()`

Gera sequência de números:

```hcl
locals {
  indices = range(5)          # [0, 1, 2, 3, 4]
  pares   = [for n in range(10) : n if n % 2 == 0]
  # [0, 2, 4, 6, 8]
}
```

`range(stop)`, `range(start, stop)`, `range(start, stop, step)`.

## `for_each` vs. expressão `for`

Confusão frequente:

- **`for_each`** é meta-argumento de **recurso**: cria múltiplos recursos.
- **Expressão `for`** é usada em valores: transforma dados.

Você geralmente combina: use expressão `for` para **preparar** um map, e `for_each` consome esse map.

```hcl
locals {
  regras_firewall = [
    { porta = 80,  cidrs = ["0.0.0.0/0"] },
    { porta = 443, cidrs = ["0.0.0.0/0"] },
    { porta = 22,  cidrs = ["10.0.0.0/8"] },
  ]

  regras_map = { for r in local.regras_firewall : tostring(r.porta) => r }
}

resource "aws_security_group_rule" "ingress" {
  for_each = local.regras_map

  type              = "ingress"
  from_port         = each.value.porta
  to_port           = each.value.porta
  protocol          = "tcp"
  cidr_blocks       = each.value.cidrs
  security_group_id = aws_security_group.web.id
}
```

## Boas práticas

- Prefira `for` + `for_each` em vez de `count + index` para coleções não-numéricas.
- Use `tostring()` quando precisar de chaves únicas de strings a partir de números.
- Evite `for` aninhado profundo — refatore com `locals` intermediários.
- Em operações complexas, use `terraform console` para explorar o resultado antes de salvar.

Próximo tópico: **splat `[*]`**, um atalho para um `for` específico.
