# 10_06 - Padrões avançados

Técnicas para escalar módulos além do básico.

## 1. Feature flags

Permita ligar/desligar partes do módulo via `bool`.

```hcl
variable "habilitar_backup" {
  type    = bool
  default = true
}

resource "aws_db_instance" "main" {
  # ...
  backup_retention_period = var.habilitar_backup ? 7 : 0
}

resource "aws_s3_bucket" "backup_offsite" {
  count  = var.habilitar_backup ? 1 : 0
  bucket = "${var.nome}-backup-offsite"
}
```

**Cuidado**: ativar/desativar uma flag pode recriar recursos (`count = 0` → destrói). Sempre revise o `plan`.

## 2. Composição via sub-módulos

Módulo "grande" compondo módulos menores:

```hcl
# modules/landing-zone/main.tf
module "vpc" {
  source = "../vpc"
  cidr   = var.cidr
}

module "kms" {
  source = "../kms"
  nome   = "landing-${var.ambiente}"
}

module "logs" {
  source = "../logs"
  bucket = "logs-${var.ambiente}"
  kms_key = module.kms.key_arn
}
```

Caller usa apenas o módulo superior:

```hcl
module "landing" {
  source   = "./modules/landing-zone"
  cidr     = "10.0.0.0/16"
  ambiente = "prod"
}
```

**Limite**: **máximo 2 níveis** de profundidade como regra prática.

## 3. Dependency injection

Ao invés de o módulo **criar** dependências, deixe-o **receber**:

```hcl
# Pior: módulo cria VPC interna
module "app" {
  source   = "./modules/app"
  # cria a própria VPC dentro
}

# Melhor: recebe
module "app" {
  source       = "./modules/app"
  vpc_id       = module.vpc.id
  subnet_ids   = module.vpc.subnets_privadas
  security_groups = [module.sg.app]
}
```

Benefícios:
- Módulo testável em isolamento.
- Caller controla dependências.
- Reuso com recursos pré-existentes.

## 4. Passagem de providers

Quando o módulo precisa rodar em **regiões/contas diferentes**:

```hcl
# modules/multiregion-bucket/versions.tf
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.replica]
    }
  }
}
```

```hcl
# modules/multiregion-bucket/main.tf
resource "aws_s3_bucket" "principal" {
  provider = aws
  bucket   = "${var.nome}-principal"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.nome}-replica"
}
```

Caller:

```hcl
provider "aws"         { region = "us-east-1" }
provider "aws" { alias = "eu", region = "eu-west-1" }

module "backup" {
  source = "./modules/multiregion-bucket"
  nome   = "critical"

  providers = {
    aws         = aws
    aws.replica = aws.eu
  }
}
```

## 5. Módulo de "wrapper" para padronizar defaults

Empresa tem regras de tag/encryption/etc. Cria wrapper sobre módulo público:

```hcl
# modules/minha-empresa-s3/main.tf
module "base" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${var.ambiente}-${var.nome}"

  versioning = {
    enabled = true      # obrigatório na empresa
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = merge(var.tags, {
    ManagedBy = "terraform"
    CostCenter = var.cost_center
  })
}
```

Consumers interagem com API simples; compliance fica dentro do wrapper.

## 6. `for_each` no bloco `module`

Crie **múltiplas instâncias** do mesmo módulo (Terraform 0.13+):

```hcl
module "app" {
  for_each = var.apps

  source = "./modules/ecs-service"

  nome       = each.key
  imagem     = each.value.imagem
  cpu        = each.value.cpu
  memory     = each.value.memory
  vpc_id     = module.vpc.id
  subnet_ids = module.vpc.subnets_privadas
}

variable "apps" {
  type = map(object({
    imagem = string
    cpu    = number
    memory = number
  }))
  default = {
    api    = { imagem = "org/api:v1", cpu = 512, memory = 1024 }
    worker = { imagem = "org/worker:v1", cpu = 256, memory = 512 }
  }
}
```

## 7. Outputs computados com fallback

```hcl
output "endpoint" {
  value = var.publico ? aws_lb.public[0].dns_name : aws_lb.private[0].dns_name
}

output "connection" {
  value = try(
    "postgres://${module.db.endpoint}",
    "memory://local",
  )
}
```

## 8. Validação cruzada

Em objetos complexos, valide campos que se relacionam:

```hcl
variable "scaling" {
  type = object({
    min     = number
    desired = number
    max     = number
  })

  validation {
    condition     = var.scaling.min <= var.scaling.desired && var.scaling.desired <= var.scaling.max
    error_message = "Precisa: min <= desired <= max."
  }
}
```

## 9. Helpers em `locals`

Abstraia lógica repetida em `locals` expostos:

```hcl
locals {
  tags_base = {
    Projeto    = var.projeto
    Ambiente   = var.ambiente
    ManagedBy  = "terraform"
    CostCenter = var.cost_center
  }

  subnet_cidrs = {
    for i, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, i)
  }

  is_prod = var.ambiente == "prod"
}
```

Evita repetição e centraliza lógica.

## 10. `moved` para refactor sem destroy

Quando você reorganiza (ex.: extrai recursos num sub-módulo), use `moved`:

```hcl
moved {
  from = aws_s3_bucket.logs
  to   = module.storage.aws_s3_bucket.this
}
```

Terraform mapeia o estado existente para o novo endereço sem recriar o recurso. (Covered em Módulo 7.)

## 11. Testes com `examples/`

Convenção: cada módulo tem pasta `examples/` com casos de uso **funcionais**:

```
modules/vpc/
├── main.tf
├── variables.tf
├── outputs.tf
└── examples/
    ├── basico/
    │   ├── main.tf
    │   └── README.md
    ├── multi-az/
    │   └── main.tf
    └── com-peering/
        └── main.tf
```

Cada `examples/X/` é um root module que consome `../../` (o módulo pai) via `source = "../../"`. Serve como:

- Documentação executável.
- Base para testes em CI (`terraform init + plan` em cada exemplo).

## 12. Documentação automática

Use `terraform-docs` para gerar README automaticamente:

```bash
terraform-docs markdown table --output-file README.md .
```

Integre no pipeline (Módulo 11) para README sempre atualizado.

## 13. Breaking changes com `deprecation`

Ainda não há "deprecated" nativo. Sinalize:

- Via `validation` warning (lance erro se usarem).
- Via `check` blocks (Terraform 1.5+).
- Via docs + CHANGELOG.

```hcl
check "deprecated_input" {
  assert {
    condition = var.modo != "legacy"
    error_message = "var.modo='legacy' foi removido. Use 'standard'. Esta mensagem será removida em v3.0."
  }
}
```

## 14. Módulos "vazios" para agrupar

Um módulo pode não criar recursos, só organizar sub-módulos e outputs:

```hcl
# modules/platform-stack/main.tf
module "network" { source = "../network" }
module "security" { source = "../security" }
module "monitoring" { source = "../monitoring" }
```

Útil para empacotar um "pacote" lógico.

## Anti-padrões a evitar

- **Módulos com 30+ variables**: divida.
- **Módulos que exportam 50 outputs**: exponha só o necessário.
- **Aninhamento de 4+ níveis**: debug vira pesadelo.
- **Lógica excessiva em `locals`** que seria melhor no caller.
- **Módulo que só envolve 1 recurso sem valor agregado**: inline.
- **`count` + objeto dinâmico**: prefere `for_each` pra estabilidade.

## Resumo

Padrões de composição, injeção de dependência, multi-provider, `for_each` em módulos, validação cruzada e documentação são o que separa módulos "de exemplo" de módulos prontos para produção.

Próximo tópico: o **Terraform Registry** e como publicar.
