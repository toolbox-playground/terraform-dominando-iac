# 05_03 - Tipos Primitivos

HCL possui três tipos **primitivos**:

| Tipo | Descrição | Exemplos |
|------|-----------|----------|
| `string` | Texto UTF-8 | `"prod"`, `"us-east-1"` |
| `number` | Inteiro ou decimal | `80`, `3.14`, `-42` |
| `bool` | Booleano | `true`, `false` |

Além deles, existe o valor especial `null`.

## `string`

```hcl
variable "ambiente" {
  type    = string
  default = "dev"
}
```

Operações comuns com strings:

- Concatenação: `"prefix-" + "suffix"` ou interpolação `"prefix-${var.x}"`.
- Comparação: `==`, `!=`.
- Funções úteis: `upper()`, `lower()`, `trim()`, `replace()`, `split()`, `join()`, `format()`.

```hcl
locals {
  nome_bucket = lower("Logs-${var.ambiente}-2026")
  # "logs-dev-2026"
}
```

## `number`

```hcl
variable "porta" {
  type    = number
  default = 80
}
```

Aceita inteiros e decimais. Operadores aritméticos:

- `+`, `-`, `*`, `/`, `%`.
- Unário: `-x`.

```hcl
locals {
  cpu_total    = var.cpu_por_pod * var.replicas
  desconto_pct = 100 - var.markup
}
```

Funções úteis: `ceil()`, `floor()`, `abs()`, `min()`, `max()`, `parseint()`.

### Precisão

HCL usa precisão arbitrária (via `big.Float`). Para operações com números muito grandes ou decimais sensíveis, funciona bem. Porém, ao serializar em JSON/state, pode haver arredondamento em ferramentas externas.

## `bool`

```hcl
variable "habilitar_ssl" {
  type    = bool
  default = true
}
```

Operadores:

- `&&` (and), `||` (or), `!` (not).
- `==`, `!=`.

```hcl
resource "aws_instance" "web" {
  # ...
  monitoring = var.ambiente == "prod" && var.habilitar_monitoramento
}
```

## Conversões implícitas

HCL **converte** automaticamente:

| De → Para | Resultado |
|-----------|-----------|
| `number` → `string` | `"80"` |
| `string` com dígitos → `number` | `80` |
| `bool` → `string` | `"true"` / `"false"` |
| `string` `"true"`/`"false"` → `bool` | `true` / `false` |

```hcl
locals {
  texto  = "porta ${var.porta}"   # number → string automático
  numero = tonumber("42")         # string → number explícito
}
```

Quando em dúvida, use as funções explícitas: `tostring()`, `tonumber()`, `tobool()`.

## Valor `null`

`null` representa "atributo ausente". Útil para atributos opcionais:

```hcl
resource "aws_instance" "web" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = var.tipo
  availability_zone = var.az != "" ? var.az : null
}
```

Com `null`, o provider usa o default dele próprio (se houver), em vez de você informar um valor.

## Detecção de tipo com `type`

O bloco `variable` permite restringir o tipo:

```hcl
variable "porta" {
  type = number
}

variable "ambientes" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
```

Se você passar um valor incompatível, o Terraform falha com erro de tipo.

## Sensibilidade

Não é exatamente um tipo, mas uma **propriedade**: um valor pode ser marcado como `sensitive` e o Terraform evita exibi-lo nos logs e no output.

```hcl
variable "senha_db" {
  type      = string
  sensitive = true
}
```

## Resumo

- **`string`**: para tudo que é texto. Aspas duplas obrigatórias.
- **`number`**: inteiros e decimais, com precisão alta.
- **`bool`**: `true`/`false`, sem aspas.
- **`null`**: "sem valor" → fallback para default do provider.

O próximo tópico trata dos tipos **complexos**: `list`, `set`, `map`, `object`, `tuple`.
