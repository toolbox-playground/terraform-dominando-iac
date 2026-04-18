# 09_08 - Funções Built-in Essenciais

Terraform tem ~100 funções built-in. Este tópico lista as mais usadas, agrupadas por categoria. Todas estão documentadas em [Terraform Functions](https://developer.hashicorp.com/terraform/language/functions).

## Strings

### Case

```hcl
upper("oi")    # "OI"
lower("OI")    # "oi"
title("ola mundo")  # "Ola Mundo"
```

### Manipulação

```hcl
trim("  oi  ", " ")            # "oi"
trimspace("\toi\n")            # "oi"
trimprefix("prefix-abc", "prefix-")   # "abc"
trimsuffix("abc-suffix", "-suffix")   # "abc"

substr("hashicorp", 0, 4)      # "hash"
replace("a-b-c", "-", "_")     # "a_b_c"
format("%s-%02d", "web", 3)    # "web-03"
formatlist("%s.txt", ["a", "b"])   # ["a.txt", "b.txt"]
```

### Split / Join

```hcl
split(",", "a,b,c")            # ["a", "b", "c"]
join("-", ["a", "b", "c"])     # "a-b-c"
```

### Busca

```hcl
startswith("arn:aws:...", "arn:aws:")   # true
endswith("file.txt", ".txt")            # true
contains(["a", "b"], "a")               # true
regex("^[a-z]+", "abc123")              # "abc"
regexall("\\d+", "a1b22c333")           # ["1", "22", "333"]
```

## Números

```hcl
abs(-5)                # 5
ceil(4.2)              # 5
floor(4.8)             # 4
max(1, 5, 3)           # 5
min(1, 5, 3)           # 1
parseint("42", 10)     # 42
pow(2, 10)             # 1024
```

## Coleções

### Listas

```hcl
length([1, 2, 3])              # 3
concat([1, 2], [3, 4])         # [1, 2, 3, 4]
reverse([1, 2, 3])             # [3, 2, 1]
slice([1, 2, 3, 4, 5], 1, 3)   # [2, 3]
sort(["b", "a", "c"])          # ["a", "b", "c"]
distinct([1, 1, 2, 3, 3])      # [1, 2, 3]
element(["a", "b", "c"], 1)    # "b"
index(["a", "b", "c"], "b")    # 1
flatten([[1, 2], [3, 4]])      # [1, 2, 3, 4]
compact(["a", "", "b", null])  # ["a", "b"]
```

### Mapas / objetos

```hcl
keys({a = 1, b = 2})                   # ["a", "b"]
values({a = 1, b = 2})                 # [1, 2]
lookup({a = 1}, "a", 99)               # 1
lookup({a = 1}, "z", 99)               # 99
merge({a = 1}, {b = 2})                # {a=1, b=2}
zipmap(["a", "b"], [1, 2])             # {a=1, b=2}
contains(["a", "b"], "a")              # true
```

### Sets

```hcl
toset([1, 1, 2, 3])                    # {1, 2, 3}
tolist(toset(["a", "b"]))              # ["a", "b"]
setintersection(["a", "b"], ["b", "c"])   # ["b"]
setunion(["a"], ["b"], ["c"])          # ["a", "b", "c"]
setsubtract(["a", "b"], ["a"])         # ["b"]
```

## Tipos / conversões

```hcl
tostring(42)              # "42"
tonumber("42")            # 42
tobool("true")            # true
tolist(["a", "b"])        # ["a", "b"]
toset([1, 2])             # {1, 2}
tomap({a = 1})            # {a = 1}

type(42)                  # "number"
can(tonumber("x"))        # false (não lança erro)
try(var.x.nested, "default")   # tenta, senão default
```

`can()` e `try()` são essenciais para código defensivo.

## Encoding

```hcl
jsonencode({ a = 1 })               # "{\"a\":1}"
jsondecode("{\"a\":1}")             # {a = 1}

yamlencode({ a = 1 })               # "a: 1\n"
yamldecode("a: 1")                  # {a = 1}

base64encode("abc")                 # "YWJj"
base64decode("YWJj")                # "abc"

urlencode("a b?c")                  # "a+b%3Fc"
```

## Arquivo e path

```hcl
file("${path.module}/config.yaml")          # lê arquivo cru
filebase64("${path.module}/binary.dat")      # lê e base64
templatefile("${path.module}/t.sh.tpl", vars)

fileexists("${path.module}/x.txt")           # true/false
basename("/a/b/c.txt")                       # "c.txt"
dirname("/a/b/c.txt")                        # "/a/b"
pathexpand("~/tf")                           # "/Users/x/tf"

fileset(path.module, "*.tf")                 # ["main.tf", "variables.tf", ...]
```

`fileset` é útil para `for_each` sobre arquivos.

## Hash / crypto

```hcl
md5("abc")
sha1("abc")
sha256("abc")
sha512("abc")
filemd5("${path.module}/x.sh")
filesha256("${path.module}/x.sh")

uuid()                         # novo UUID a cada chamada → cuidado!
```

`uuid()` regenera toda execução — provoca drift constante. Use `random_uuid` resource.

## Data e hora

```hcl
timestamp()                              # RFC3339, hora do plan
formatdate("YYYY-MM-DD", timestamp())    # "2026-04-17"
timeadd(timestamp(), "2h")               # 2 horas depois
```

Atenção: `timestamp()` muda a cada execução. Para valor estável, use `time_static` do provider `time`.

## Rede

```hcl
cidrsubnet("10.0.0.0/16", 8, 2)          # "10.0.2.0/24"
cidrhost("10.0.0.0/24", 5)               # "10.0.0.5"
cidrnetmask("10.0.0.0/24")               # "255.255.255.0"

# Divisão automática em N subnets
[for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i)]
# ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
```

## Defensivas

### `coalesce`

Primeiro não-nulo, não-vazio:

```hcl
coalesce(null, "", "valor")   # "valor"
coalesce(var.nome, "default")
```

### `coalescelist`

Primeiro não-vazio entre listas:

```hcl
coalescelist([], [], ["a"])   # ["a"]
```

### `try`

Retorna default se a expressão falhar:

```hcl
try(var.config.porta, 80)
```

### `can`

Retorna true se a expressão for avaliada sem erro:

```hcl
can(regex("^[a-z]+$", "abc"))   # true
can(tonumber("x"))              # false
```

Útil em `validation`:

```hcl
validation {
  condition = can(cidrnetmask(var.cidr))
  error_message = "CIDR inválido."
}
```

## Exemplos combinados

### Tags padrão com merge

```hcl
locals {
  tags = merge(
    { Owner = "plataforma", ManagedBy = "terraform" },
    var.tags_extras,
  )
}
```

### Lista filtrada + transformação

```hcl
locals {
  subnets_publicas_cidrs = [
    for s in var.subnets : s.cidr if s.public
  ]
}
```

### Map a partir de lista de objetos

```hcl
locals {
  por_nome = { for u in var.usuarios : u.nome => u }
}
```

### Computar N subnets distribuídas

```hcl
locals {
  azs = slice(data.aws_availability_zones.this.names, 0, 3)

  subnets = {
    for i, az in local.azs : az => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      az   = az
    }
  }
}
```

## Cheatsheet rápido

```hcl
# Concatenação
"prefix-${var.x}"
join("", ["a", "b"])

# Condicional
var.x == "prod" ? "t3.large" : "t3.micro"

# Default
coalesce(var.x, "padrao")
try(var.config.x, "padrao")

# Map lookup com default
lookup(var.mapa, "chave", "padrao")

# List → Map
{for i in var.items : i.id => i}

# Filter
[for i in var.items : i if i.ativo]

# JSON
jsonencode({ a = 1 })
jsondecode(var.json)

# Template
templatefile("path.tpl", vars)

# Hash file
filesha256(path)

# Regex
regex("^[a-z]+$", var.nome)
```

## Descoberta

Duas formas de achar função nova:

1. [Terraform Functions (docs)](https://developer.hashicorp.com/terraform/language/functions) — lista oficial.
2. `terraform console` — teste e explore:

```bash
terraform console
> split(",", "a,b,c")
[
  "a",
  "b",
  "c",
]
```

Próximo módulo: **Módulos** (o outro "módulo" da vida do Terraform — como empacotar código reutilizável).
