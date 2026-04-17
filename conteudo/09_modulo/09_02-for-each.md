# 09_02 - Meta-argumento `for_each`

`for_each` replica um recurso **uma vez por chave**, usando `set(string)` ou `map(T)`. É o padrão **recomendado** quando você tem entidades com identidade própria.

## Com `set(string)`

```hcl
resource "aws_iam_user" "time" {
  for_each = toset(["alice", "bob", "carol"])

  name = each.key
}
```

Resultado:

- `aws_iam_user.time["alice"]`
- `aws_iam_user.time["bob"]`
- `aws_iam_user.time["carol"]`

Se você **remover** `"bob"`, apenas `aws_iam_user.time["bob"]` é destruído. Os outros não são afetados.

## Com `map(T)`

```hcl
variable "projetos" {
  type = map(object({
    nome  = string
    cpu   = number
    ambiente = string
  }))

  default = {
    billing = { nome = "Billing",   cpu = 4,  ambiente = "prod" }
    adm     = { nome = "Admin",     cpu = 2,  ambiente = "prod" }
    poc     = { nome = "POC Lab",   cpu = 1,  ambiente = "dev"  }
  }
}

resource "aws_instance" "app" {
  for_each = var.projetos

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.cpu >= 4 ? "t3.large" : "t3.small"

  tags = {
    Name     = each.value.nome
    Ambiente = each.value.ambiente
    Projeto  = each.key
  }
}
```

Dentro do bloco:

- `each.key` → chave do map (string).
- `each.value` → valor (objeto, string, number).

## Variáveis disponíveis em `for_each`

| Expressão | Descrição |
|-----------|-----------|
| `each.key` | Chave da iteração (string do set ou do map) |
| `each.value` | Valor associado à chave |

## Referenciando recursos criados

```hcl
output "alice_arn" {
  value = aws_iam_user.time["alice"].arn
}

output "todas_arns" {
  value = values(aws_iam_user.time)[*].arn
  # ou: [for u in aws_iam_user.time : u.arn]
}

output "por_nome" {
  value = { for k, u in aws_iam_user.time : k => u.arn }
}
```

## Quando usar `for_each`

- Entidades com **identidade estável** (usuários, contas, DNS records).
- Configurações distintas por item (diferente de `count`, onde todos são idênticos).
- Qualquer situação em que remover/adicionar um item não deve afetar os outros.

Na prática, use `for_each` em **90% dos casos**; `count` principalmente para condicional `0 ou 1` e cópias idênticas.

## Transformando lista em set/map

Terraform espera `set(string)` ou `map(T)`. Use conversões:

```hcl
# list → set
for_each = toset(var.usuarios)

# list de objetos → map usando um campo como chave
for_each = { for p in var.projetos : p.nome => p }
```

## Erros comuns

### `for_each` com valor desconhecido no plan

```hcl
resource "aws_instance" "web" {
  for_each = toset(data.external.algo.result.items)  # valor desconhecido
  # ...
}
```

Erro: *"The "for_each" value depends on resource attributes that cannot be determined until apply."*

Solução: use chaves **conhecidas no plan** (variáveis, locals calculados só de variáveis).

### Mapa com chaves duplicadas

Se o expression gerar chaves iguais, Terraform falha:

```hcl
for_each = { for p in var.projetos : p.owner => p }
# Se dois projetos têm o mesmo owner, boom.
```

Solução: garanta chaves únicas (combine campos: `"${p.owner}-${p.nome}"`).

### Mistura de `count` e `for_each` no mesmo recurso

Não pode. Escolha um.

## `for_each` em módulos

```hcl
module "bucket" {
  for_each = toset(["logs", "backups", "temp"])
  source   = "./modules/s3-bucket"
  nome     = "${var.projeto}-${each.key}"
}
```

Resultado: `module.bucket["logs"]`, `module.bucket["backups"]`, etc.

Outputs:

```hcl
output "arn_logs" {
  value = module.bucket["logs"].arn
}
```

## Migração de `count` para `for_each`

Se você tem `count` e quer migrar:

```hcl
# Antes
resource "aws_iam_user" "u" {
  count = length(var.usuarios)
  name  = var.usuarios[count.index]
}

# Depois
resource "aws_iam_user" "u" {
  for_each = toset(var.usuarios)
  name     = each.key
}
```

O Terraform vai querer **destruir** os recursos do `count` e criar os do `for_each`, pois mudaram os endereços.

Para evitar recriação, use `moved`:

```hcl
moved {
  from = aws_iam_user.u[0]
  to   = aws_iam_user.u["alice"]
}

moved {
  from = aws_iam_user.u[1]
  to   = aws_iam_user.u["bob"]
}
```

Ou faça manualmente com `terraform state mv`.

## `for_each` com `dynamic` blocks

Frequentemente combinado com `dynamic` para gerar sub-blocos dinâmicos (próximo tópico).

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.portas

    content {
      description = ingress.value.descricao
      from_port   = ingress.value.porta
      to_port     = ingress.value.porta
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidrs
    }
  }
}
```

## Boas práticas

- Prefira `for_each` com `map` quando cada item tem dados específicos.
- Use `toset(lista)` para listas de strings simples.
- Nomeie chaves para serem estáveis e legíveis.
- Documente em variáveis: `type = map(object(...))`.
- Use `moved` para refactors sem recriação.

Próximo tópico: **expressões `for`**.
