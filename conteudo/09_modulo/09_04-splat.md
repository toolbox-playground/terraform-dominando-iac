# 09_04 - Operador Splat `[*]`

O **operador splat** extrai um atributo de cada elemento de uma lista. É um atalho sintático para uma expressão `for` específica.

## Forma simples

```hcl
resource "aws_instance" "web" {
  count = 3
  # ...
}

# Splat extrai o atributo de todos
output "ips" {
  value = aws_instance.web[*].private_ip
}
# [ip0, ip1, ip2]
```

Equivalente a:

```hcl
output "ips" {
  value = [for i in aws_instance.web : i.private_ip]
}
```

Splat é mais curto e idiomático para casos simples.

## Splat com `for_each`

`for_each` produz um **map**, não uma list. Splat **não funciona** diretamente:

```hcl
resource "aws_iam_user" "time" {
  for_each = toset(["alice", "bob"])
  name     = each.key
}

# Isto NÃO funciona como você espera:
# aws_iam_user.time[*].arn  → erro ou comportamento estranho
```

Use `values()` ou `for`:

```hcl
output "arns" {
  value = values(aws_iam_user.time)[*].arn
}

# Ou:
output "arns_alt" {
  value = [for u in aws_iam_user.time : u.arn]
}
```

## Splat aninhado

```hcl
resource "aws_instance" "app" {
  count = 3

  network_interface {
    # ...
  }
}

# Primeira network_interface de cada instância
output "macs" {
  value = aws_instance.app[*].network_interface[0].mac_address
}
```

## "Full splat" (`.*`)

Há uma forma mais antiga, menos comum:

```hcl
aws_instance.web.*.private_ip
```

É quase equivalente a `aws_instance.web[*].private_ip`, mas trata valores `null`/opcionais de forma diferente. Prefira `[*]`.

## Splat + `null`

`[*]` opera em valores **não nulos**:

```hcl
locals {
  opcional = null
}

output "teste" {
  value = local.opcional[*].alguma_coisa
  # [] — lista vazia
}
```

Útil para lidar com recursos `count` condicional:

```hcl
resource "aws_eip" "nat" {
  count  = var.criar_nat ? 1 : 0
  domain = "vpc"
}

output "ip_ou_vazio" {
  value = aws_eip.nat[*].public_ip
  # [] se criar_nat = false
  # ["ip"] se true
}
```

Alternativa comum:

```hcl
output "ip" {
  value = try(aws_eip.nat[0].public_ip, null)
}
```

## Splat retorna lista, mesmo com um item

```hcl
resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"
}

output "ip_lista" {
  value = aws_eip.nat[*].public_ip
  # ["54.123.45.67"]
}

output "ip_escalar" {
  value = aws_eip.nat[0].public_ip
  # "54.123.45.67"
}
```

Às vezes você precisa de escalar — use índice.

## Splat em expressões complexas

Se você precisa de mais do que extrair um atributo (filtrar, transformar), **volte para `for`**:

```hcl
# Splat NÃO suporta filtro
# aws_instance.web[*].private_ip if aws_instance.web[*].public → erro

# Use for:
[for i in aws_instance.web : i.private_ip if !i.public]
```

## Splat com `module`

```hcl
module "vpc" {
  count  = 2
  source = "./modules/vpc"
  # ...
}

output "cidrs" {
  value = module.vpc[*].cidr_block
}
```

Funciona da mesma forma.

## Dicas

- Use splat **quando** a operação é só "pega tal atributo".
- Para filtros, transforms ou lógica extra → `for`.
- Lembre-se: splat em coleções vazias/null retorna `[]`, não erro.
- Splat depois de `values()` é **idiomático** para `for_each`.

## Quick reference

| Cenário | Sintaxe |
|---------|---------|
| count → atributo | `res[*].attr` |
| for_each → atributo | `values(res)[*].attr` |
| count condicional (0/1) → lista | `res[*].attr` (vazia ou 1 item) |
| Escalar garantido | `res[0].attr` |
| Com filtro | `[for x in res : x.attr if cond]` |

Próximo tópico: **`dynamic` blocks**.
