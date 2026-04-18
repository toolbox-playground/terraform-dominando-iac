# 09_01 - Meta-argumento `count`

`count` cria **N cópias** de um recurso a partir de um número inteiro. É o meta-argumento mais antigo para replicar recursos.

## Sintaxe básica

```hcl
resource "aws_instance" "web" {
  count = 3

  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index}"
  }
}
```

Cria 3 instâncias: `aws_instance.web[0]`, `aws_instance.web[1]`, `aws_instance.web[2]`.

## `count.index`

Acessível dentro do bloco do recurso: inteiro de `0` a `count - 1`.

```hcl
resource "aws_subnet" "public" {
  count = 3

  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

## Referenciando

```hcl
# Todas as instâncias
output "all_ids" {
  value = aws_instance.web[*].id
}

# Uma específica
output "primeira" {
  value = aws_instance.web[0].id
}
```

O operador **splat `[*]`** extrai o atributo de todos.

## Quando usar `count`

- Quando você precisa de **N cópias idênticas** (ou quase).
- Quando N é calculado a partir de lista/ambiente: `count = length(var.zonas)`.
- Para provisionar condicionalmente: `count = var.criar_nat ? 1 : 0`.

## Quando **não** usar `count`

- Quando cada "cópia" tem **identidade distinta** (nomes, tags, tamanhos diferentes).
- Em listas **estáveis em ordem** que podem mudar: remover um elemento do meio reidenta todos os recursos posteriores.

Exemplo problemático:

```hcl
variable "usuarios" {
  type = list(string)
  default = ["alice", "bob", "carol"]
}

resource "aws_iam_user" "this" {
  count = length(var.usuarios)
  name  = var.usuarios[count.index]
}
```

Se você remover `"bob"`, `carol` passa de `[2]` para `[1]` → Terraform **recria** `carol` e **deleta** o antigo. Isso frequentemente é indesejável.

Solução: `for_each` com set/map (próximo tópico).

## `count` condicional: 0 ou 1

Padrão clássico para "criar recurso só se condição":

```hcl
resource "aws_eip" "nat" {
  count = var.criar_nat ? 1 : 0

  domain = "vpc"
}
```

Referência:

```hcl
output "nat_ip" {
  value = var.criar_nat ? aws_eip.nat[0].public_ip : null
}
```

Atenção: o recurso **existe** (mesmo que com `count = 0`) como **lista vazia**. `aws_eip.nat` é sempre uma lista.

## Múltiplos recursos dependentes

```hcl
resource "aws_instance" "web" {
  count = 3
  # ...
}

resource "aws_eip" "ip" {
  count = length(aws_instance.web)

  instance = aws_instance.web[count.index].id
}
```

Dependência elemento a elemento.

## Limitações

- `count` aceita expressão, mas seu valor precisa ser **determinado no plan** — não pode depender de atributos de outros recursos ainda não criados.
- Se `count` muda de `3` para `2`, o índice `[2]` é destruído. Se muda para `4`, o `[3]` é criado.
- Dentro de **módulos**, `count` funciona de forma semelhante: `count` no bloco `module` replica o módulo inteiro.

## Comparação visual com `for_each`

| | `count` | `for_each` |
|---|---------|-----------|
| Entrada | `number` | `set(string)` ou `map(T)` |
| Chave | índice numérico | string |
| Resiliente a remoção | ❌ | ✅ |
| Útil para condicional 0/1 | ✅ | ⚠️ (menos idiomático) |
| Útil para cópias idênticas | ✅ | ⚠️ |
| Útil para conjunto estável | ❌ | ✅ |

Próximo tópico: **`for_each`** em profundidade.
