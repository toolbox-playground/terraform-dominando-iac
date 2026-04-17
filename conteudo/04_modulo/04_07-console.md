# 04_07 - Terraform Console

## O que é

`terraform console` abre um **REPL** (shell interativo) onde você pode avaliar expressões HCL usando o estado atual e o código do diretório. É extremamente útil para **testar interpolações**, **explorar outputs**, **entender funções built-in** e **debugar valores**.

```bash
terraform console
```

Você vê o prompt:

```text
>
```

E começa a digitar expressões.

## Exemplos básicos

### Testar expressões simples

```text
> 1 + 1
2

> "hello" == "world"
false

> upper("terraform")
"TERRAFORM"
```

### Usar funções built-in

```text
> length(["a", "b", "c"])
3

> join("-", ["foo", "bar"])
"foo-bar"

> tomap({ a = 1, b = 2 })
{
  "a" = 1
  "b" = 2
}

> formatdate("YYYY-MM-DD", timestamp())
"2026-04-17"
```

### Inspecionar variáveis

Com um `variable "ambiente" { default = "dev" }`:

```text
> var.ambiente
"dev"
```

### Inspecionar outputs e recursos no state

Se você já rodou `apply`:

```text
> aws_s3_bucket.logs.arn
"arn:aws:s3:::logs-prod-2026"

> aws_s3_bucket.logs.tags
{
  "Ambiente" = "prod"
}
```

### Expressões complexas

```text
> [for s in ["a", "b", "c"] : upper(s)]
[
  "A",
  "B",
  "C",
]

> { for n, v in { foo = 1, bar = 2 } : n => v * 10 }
{
  "bar" = 20
  "foo" = 10
}
```

### Condicionais

```text
> var.ambiente == "prod" ? "t3.large" : "t3.micro"
"t3.micro"
```

## Casos de uso práticos

### 1. Testar uma interpolação antes de colocar no código

Em vez de escrever no arquivo, fazer `plan`, ver erro, refazer:

```text
> "${lower(var.projeto)}-${var.ambiente}"
"meu-projeto-dev"
```

### 2. Entender o que uma função retorna

Se você nunca usou `cidrsubnet`:

```text
> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
```

### 3. Explorar dados de providers

```text
> data.aws_caller_identity.current
{
  "account_id" = "123456789012"
  "arn" = "arn:aws:iam::123456789012:user/eu"
  # ...
}
```

### 4. Debugar outputs de módulos

```text
> module.vpc.vpc_id
"vpc-0abc123def456789"

> module.vpc.private_subnets
[
  "subnet-aaa",
  "subnet-bbb",
]
```

## Limitações

### Console precisa de state válido

Para inspecionar recursos (`aws_s3_bucket.x.arn`), o state precisa estar sincronizado. Se não tiver, `terraform console` devolve erro ou valor nulo.

### Alterações no código não aparecem automaticamente

Se você mudar o código, precisa **sair e abrir o console de novo** para ele reler.

### Não executa side effects

Você não pode **criar** recursos dentro do console. É read-only.

### State remoto precisa acessar

Se seu state está remoto, `terraform init` precisa ter sido feito.

## Flags

| Flag | Uso |
|------|-----|
| `-var="k=v"` | Define variável temporária. |
| `-var-file=FILE` | Carrega tfvars. |
| `-state=FILE` | Força um state específico (raramente usado). |

## Dicas

### Scripting

Você pode alimentar uma expressão via stdin:

```bash
echo 'upper("terraform")' | terraform console
# "TERRAFORM"
```

Útil para scripts.

### Combinando com `output`

Se um recurso expõe muitos atributos, `output "x" { value = recurso.atributo_gigante }` + `terraform output x` é alternativa. Mas o console é mais ad-hoc.

### Testando a documentação de funções

Sempre que aprender uma função nova na doc, teste no console. Aprende rápido e memoriza a sintaxe.

## Saindo

- `exit`
- `Ctrl+D`
- `Ctrl+C`

## Referências

- [terraform console](https://developer.hashicorp.com/terraform/cli/commands/console)
- [Built-in Functions](https://developer.hashicorp.com/terraform/language/functions)
- [Expressions Overview](https://developer.hashicorp.com/terraform/language/expressions)
