# 05_04 - Tipos Complexos

Tipos complexos agrupam valores — úteis para parametrizar listas de regiões, conjuntos de tags, mapas de AMIs, etc.

| Tipo | Ordem | Chaves | Homogêneo? |
|------|-------|--------|-------------|
| `list(T)` | ordenada | índice numérico | sim — todos do tipo `T` |
| `set(T)` | sem ordem | - | sim — sem duplicados |
| `map(T)` | sem ordem | chave string | sim — valores do tipo `T` |
| `tuple([T1, T2, ...])` | ordenada | índice numérico | não — tipos fixos por posição |
| `object({k1=T1, k2=T2})` | sem ordem | chaves fixas | não — tipo por chave |

## `list`

Sequência ordenada de valores do **mesmo tipo**.

```hcl
variable "zonas" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  primeira = var.zonas[0]          # "us-east-1a"
  tamanho  = length(var.zonas)     # 3
}
```

Funções comuns: `length`, `concat`, `slice`, `reverse`, `sort`, `element`, `index`, `contains`.

## `set`

Coleção **sem ordem** e **sem duplicados**. Usada muito em `for_each`:

```hcl
resource "aws_iam_user" "times" {
  for_each = toset(["alice", "bob", "carol"])
  name     = each.key
}
```

Converter entre list e set: `toset(lista)`, `tolist(set)`.

## `map`

Pares chave → valor com chaves string:

```hcl
variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-0c7217cdde317cfec"
    "us-west-2" = "ami-0cf2b4e024cdb6960"
  }
}

locals {
  ami_regiao = var.amis[var.regiao]
  ami_safe   = lookup(var.amis, var.regiao, "ami-default")
}
```

Funções: `keys`, `values`, `lookup`, `merge`, `zipmap`.

## `tuple`

Como lista, mas permite tipos diferentes por posição:

```hcl
variable "config" {
  type    = tuple([string, number, bool])
  default = ["web", 80, true]
}

locals {
  nome      = var.config[0]  # string
  porta     = var.config[1]  # number
  habilitar = var.config[2]  # bool
}
```

Use `tuple` quando o número e tipos dos elementos são fixos e conhecidos. Raramente o melhor escolhido — prefira `object` quando possível.

## `object`

Estrutura com chaves e tipos fixos:

```hcl
variable "cluster" {
  type = object({
    nome     = string
    nos      = number
    ssl      = bool
    zonas    = list(string)
  })

  default = {
    nome  = "prod"
    nos   = 3
    ssl   = true
    zonas = ["us-east-1a", "us-east-1b"]
  }
}

locals {
  nome_upper = upper(var.cluster.nome)
}
```

`object` vs `map`:
- **`map(T)`**: chaves **dinâmicas**, valores do mesmo tipo.
- **`object({...})`**: chaves **fixas**, valores com tipos específicos.

Se você sabe quais são as chaves e cada uma tem seu próprio tipo → `object`.
Se a lista de chaves é variável (ex.: AMIs por região) → `map`.

## Atributos opcionais em `object` (1.3+)

```hcl
variable "db" {
  type = object({
    nome    = string
    versao  = optional(string, "14")
    backup  = optional(bool, false)
  })
}
```

Se o usuário não informar `versao` ou `backup`, os defaults são aplicados.

## `any`

Aceita qualquer tipo:

```hcl
variable "config_livre" {
  type = any
}
```

Use com cautela — perde validação estática.

## Conversões entre coleções

```hcl
tolist(["a", "b"])        # set → list
toset(["a", "a", "b"])    # list → set (sem duplicados)
tomap({a = 1, b = 2})     # object → map (com coerção)
```

## Exemplos reais

### Lista de sub-redes por AZ

```hcl
variable "subnets" {
  type = list(object({
    cidr = string
    az   = string
  }))

  default = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" }
  ]
}

resource "aws_subnet" "this" {
  for_each = { for s in var.subnets : s.az => s }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key
}
```

### Mapa de tags por ambiente

```hcl
locals {
  tags_por_ambiente = {
    prod = { Env = "prod", Backup = "daily" }
    dev  = { Env = "dev",  Backup = "none" }
  }

  tags_atuais = local.tags_por_ambiente[var.ambiente]
}
```

### Aninhamento de objetos

```hcl
variable "aplicacao" {
  type = object({
    nome = string
    cpu  = number
    http = object({
      porta    = number
      path     = string
      timeouts = list(number)
    })
  })
}
```

## Resumo

- Comece simples: `list(string)` e `map(string)` cobrem a maioria dos casos.
- Use `object` quando a estrutura é fixa e você quer validação.
- Use `set` quando a ordem não importa e você precisa de `for_each`.
- `tuple` e `any` são exceções, use só quando necessário.

No próximo tópico: **operadores e expressões**.
