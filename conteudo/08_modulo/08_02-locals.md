# 08_02 - Locals

**Locals** são valores calculados **dentro** do módulo. Diferente de `variable` (interface externa), `local` é detalhe interno.

## Sintaxe

```hcl
locals {
  nome_base   = "${var.projeto}-${var.ambiente}"
  timestamp   = formatdate("YYYYMMDD", timestamp())
  eh_prod     = var.ambiente == "prod"
  tags_padrao = {
    Projeto     = var.projeto
    Ambiente    = var.ambiente
    ManagedBy   = "terraform"
  }
}
```

Múltiplos blocos `locals { ... }` no mesmo módulo são **mesclados**. Você pode ter vários arquivos `locals.tf` organizados por tema.

Referência: `local.NOME`.

## Quando usar

- **Cálculos reutilizáveis**: mesmo valor em vários lugares.
- **Simplificar expressões**: extrair um ternário longo.
- **Nomeação clara**: `local.bucket_name` ao invés de repetir `"${var.projeto}-${var.ambiente}-logs"`.
- **Composição de objetos**: montar `tags_padrao` para reutilizar.
- **Defaults condicionais**: ex. `instance_type` por ambiente via `map` + lookup.

## Diferença para `variable`

| | `variable` | `local` |
|---|-----------|---------|
| Origem do valor | **externa** (user/env/tfvars) | **interna** (HCL do módulo) |
| Pode ser sobreposto? | sim | não |
| Documentação | `description` | comentários |
| Validação | `validation {}` | `precondition`/`check` |
| Visibilidade | interface pública | detalhe interno |

Regra prática: se o **caller** deve escolher o valor, `variable`. Se é **derivação**, `local`.

## Exemplos

### Nome padronizado

```hcl
locals {
  nome = lower("${var.projeto}-${var.ambiente}")
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.nome}-logs"
}
```

### Mapa por ambiente

```hcl
locals {
  config_por_ambiente = {
    dev  = { instance_type = "t3.micro",  min_size = 1, max_size = 2 }
    hml  = { instance_type = "t3.small",  min_size = 2, max_size = 4 }
    prod = { instance_type = "t3.medium", min_size = 3, max_size = 10 }
  }

  config_atual = local.config_por_ambiente[var.ambiente]
}

resource "aws_autoscaling_group" "app" {
  min_size = local.config_atual.min_size
  max_size = local.config_atual.max_size
  # ...
}
```

Ganho: adicionar novo ambiente = editar o mapa; nada mais muda.

### Tags mescladas

```hcl
locals {
  tags = merge(
    {
      Projeto   = var.projeto
      Ambiente  = var.ambiente
      ManagedBy = "terraform"
    },
    var.tags_extras,
  )
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.nome}-logs"
  tags   = local.tags
}
```

### Condicional complexa

```hcl
locals {
  precisa_nat = var.criar_subnets_privadas && length(var.subnets_publicas) > 0
  precisa_vpn = contains(["prod", "hml"], var.ambiente)
}
```

### Derivações com funções

```hcl
locals {
  zonas_disponiveis = data.aws_availability_zones.available.names
  numero_zonas      = min(length(local.zonas_disponiveis), var.max_azs)
  zonas_usadas      = slice(local.zonas_disponiveis, 0, local.numero_zonas)
}
```

## Cuidados

### Não abuse

Nem toda expressão precisa de `local`. Se é usada **uma vez** e é clara, mantenha inline:

```hcl
# Exagero
locals {
  bucket_name = "logs"
}
resource "aws_s3_bucket" "x" {
  bucket = local.bucket_name
}

# Melhor
resource "aws_s3_bucket" "x" {
  bucket = "logs"
}
```

### Não use `local` para "esconder" segredos

Locals aparecem no plan e no state, iguais a variables. `sensitive` não existe para locals (eles herdam a marca de `variable sensitive = true` quando aplicável).

### Ciclos

Terraform detecta ciclos em `locals` (um referenciando o outro em loop). Se você tentar, recebe erro — corrija a lógica.

## `locals` vs. `data`

- **`local`**: calculado a partir de variáveis e outros locals → rápido, sem rede.
- **`data`**: consulta APIs → mais lento, pode falhar.

Quando der, prefira `local` (mais deterministico).

## Precondition em locals (1.2+)

Você pode adicionar `precondition` em `check` blocks para validar locals:

```hcl
check "azs_suficientes" {
  assert {
    condition     = local.numero_zonas >= 2
    error_message = "Projeto exige pelo menos 2 AZs disponíveis."
  }
}
```

Ou em output/resource `precondition` para invariantes críticos.

## Boas práticas

- **Nomes claros**: `eh_prod`, `nome_bucket`, `total_replicas`.
- **Agrupe por tema**: `locals.tf` pequeno, ou arquivos por área (`naming.tf`, `tags.tf`, `network.tf`).
- **Comente** quando a fórmula não é óbvia.
- **Extraia** quando melhora legibilidade — não antes.

Próximo tópico: **outputs**.
