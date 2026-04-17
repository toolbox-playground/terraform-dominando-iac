# 05_05 - Operadores e Expressões

HCL avalia **expressões** para produzir valores. Expressões podem ser constantes, referências, funções ou combinações.

## Referências

Você já viu muitas:

| Referência | O que é |
|------------|---------|
| `var.nome` | Valor de `variable "nome"` |
| `local.x` | Valor de `locals { x = ... }` |
| `aws_s3_bucket.logs.arn` | Atributo de recurso |
| `data.aws_ami.ubuntu.id` | Atributo de data source |
| `module.vpc.vpc_id` | Output de módulo |
| `each.key`, `each.value` | Dentro de `for_each` |
| `count.index` | Dentro de `count` |
| `self.private_ip` | Dentro de provisioners/lifecycle |
| `path.module`, `path.root` | Paths úteis |
| `terraform.workspace` | Nome do workspace atual |

## Operadores aritméticos

`+`, `-`, `*`, `/`, `%`, unário `-`:

```hcl
locals {
  cpu_total       = var.cpu_por_pod * var.replicas
  restante        = 100 - var.percentual_usado
  resto           = var.total % var.divisor
  negativo        = -var.saldo
}
```

Precedência padrão: `*`, `/`, `%` antes de `+`, `-`. Use parênteses quando em dúvida.

## Operadores de comparação

`==`, `!=`, `<`, `<=`, `>`, `>=`:

```hcl
locals {
  eh_prod       = var.ambiente == "prod"
  nao_default   = var.nome != "default"
  muitas_zonas  = length(var.zonas) > 2
}
```

## Operadores lógicos

`&&`, `||`, `!`:

```hcl
locals {
  usar_monitoramento_avancado = var.ambiente == "prod" && var.plano == "enterprise"
  criar_nat                   = var.habilitar_internet || var.habilitar_saida
  nao_desenvolvimento         = !(var.ambiente == "dev")
}
```

`&&` e `||` são **short-circuit**: se o lado esquerdo já resolve, o direito não é avaliado.

## Operador condicional (ternário)

`condicao ? valor_se_verdadeiro : valor_se_falso`:

```hcl
locals {
  tipo_instancia = var.ambiente == "prod" ? "t3.large" : "t3.micro"
  tamanho_disco  = var.ambiente == "prod" ? 100 : 20
}
```

Pode aninhar, mas prefira clareza:

```hcl
locals {
  # Aninhado (legível só se poucos casos)
  tipo = var.ambiente == "prod" ? "t3.large" : (var.ambiente == "hml" ? "t3.medium" : "t3.micro")

  # Melhor: use map
  tipos_por_ambiente = {
    prod = "t3.large"
    hml  = "t3.medium"
    dev  = "t3.micro"
  }

  tipo_clean = local.tipos_por_ambiente[var.ambiente]
}
```

## Acesso a elementos

### Índice em list/tuple

```hcl
primeiro = var.zonas[0]
ultimo   = var.zonas[length(var.zonas) - 1]
```

### Chave em map/object

```hcl
amb = var.tags["Environment"]  # map
nome = var.cluster.nome        # object - notação dot
```

## Operador splat `[*]`

Extrai o **mesmo atributo** de todos os elementos de uma lista:

```hcl
resource "aws_instance" "web" {
  count = 3
  # ...
}

output "ips" {
  value = aws_instance.web[*].private_ip
  # Equivalente a [for i in aws_instance.web : i.private_ip]
}
```

Splat é atalho sintático para uma expressão `for`.

## Expressão `for`

Constrói listas, sets ou mapas a partir de outras coleções:

```hcl
locals {
  # list → list
  nomes_upper = [for n in var.nomes : upper(n)]

  # list → map
  por_id = { for obj in var.items : obj.id => obj }

  # map → list
  chaves_ativas = [for k, v in var.flags : k if v]

  # Com filtro
  somente_prod = [for s in var.subnets : s.cidr if s.env == "prod"]
}
```

Sintaxe:

- `[for x in coll : expr]` → list
- `{for k, v in coll : k => expr}` → map
- `... if condicao` → filtra
- Chaves de mapa devem ser únicas.

## Expressão `conditional` em `for`

```hcl
locals {
  pares = [for n in range(1, 10) : n if n % 2 == 0]
  # [2, 4, 6, 8]
}
```

## Interpolação em strings

Dentro de `"..."`, use `${...}` para inserir expressões:

```hcl
locals {
  nome_completo = "${var.projeto}-${var.ambiente}-${var.regiao}"
}
```

E `%{...}` para **diretivas** (condicionais e loops):

```hcl
locals {
  mensagem = "Olá %{if var.formal}senhor(a)%{else}fera%{endif} ${var.nome}!"
}
```

```hcl
locals {
  lista = <<-EOT
  Usuários ativos:
  %{for u in var.usuarios}
  - ${u}
  %{endfor}
  EOT
}
```

## Funções built-in

Terraform oferece **~100 funções**. Exemplos:

```hcl
upper("oi")                  # "OI"
length(["a", "b"])           # 2
replace("a-b", "-", "_")     # "a_b"
format("%s-%02d", "web", 3)  # "web-03"
lookup(var.amis, var.regiao, "default-ami")
coalesce(null, "", "final")  # "final"
try(var.config.nome, "padrao")
cidrsubnet("10.0.0.0/16", 8, 2)  # "10.0.2.0/24"
jsonencode({a = 1})
jsondecode("{\"a\":1}")
file("${path.module}/script.sh")
```

Lista completa: [Terraform Functions](https://developer.hashicorp.com/terraform/language/functions).

## Precedência (resumo)

Da maior para a menor:

1. `!`, unário `-`
2. `*`, `/`, `%`
3. `+`, `-`
4. `>`, `>=`, `<`, `<=`
5. `==`, `!=`
6. `&&`
7. `||`
8. `? :`

Na dúvida, parênteses.

## Boas práticas

- **Extraia expressões complexas para `locals`** com nomes explícitos.
- **Evite ternários aninhados** — prefira `map` de lookup.
- **Nomeie claramente**: `eh_prod`, `total_replicas`, `usar_cache`.
- **Teste no console**: `terraform console` → valida expressão sem aplicar nada.

```bash
terraform console
> upper("oi")
"OI"
> var.ambiente == "prod" ? "t3.large" : "t3.micro"
"t3.large"
```

## Exemplos combinando vários conceitos

```hcl
locals {
  # Ambiente "prod" entra, outros não
  criar_replicas = var.ambiente == "prod"

  # Tags padrão + tags extras, mescladas
  tags_final = merge(
    {
      Env     = var.ambiente
      Owner   = var.time
    },
    var.tags_extras,
  )

  # Subnets públicas apenas
  subnets_publicas = [for s in var.subnets : s.id if s.publica]

  # Mapa de zona → preço (exemplo didático)
  precos_por_zona = { for z in var.zonas : z => var.preco_base * (z == "us-east-1a" ? 1 : 1.1) }
}
```

No próximo tópico: **strings e templating avançado**.
