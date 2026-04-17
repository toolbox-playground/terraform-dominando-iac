# 06_04 - Aliases e Múltiplas Instâncias de Provider

Por padrão, cada provider é configurado **uma vez** por projeto. Mas há casos em que você precisa falar com múltiplas contas, múltiplas regiões, ou múltiplos clusters — para isso existem os **aliases**.

## Quando usar aliases

Cenários comuns:

- **Multi-região AWS**: criar recursos em `us-east-1` e `eu-west-1`.
- **Multi-conta AWS**: provisionar infraestrutura de segurança na conta "audit" e de aplicação na conta "workload".
- **Múltiplos clusters Kubernetes**: aplicar manifests em clusters de dev e prod.
- **Datadog multi-org**: criar recursos em organizações diferentes.

## Sintaxe

Declare instâncias adicionais com `alias = "nome"`:

```hcl
provider "aws" {
  region = "us-east-1"
  # sem alias → configuração padrão
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "audit"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::999999999999:role/terraform"
  }
}
```

A **primeira sem alias** é a "default". Os blocos com `alias` são instâncias nomeadas.

## Usando um alias em um resource

Adicione `provider = TIPO.ALIAS`:

```hcl
resource "aws_s3_bucket" "logs_us" {
  bucket = "logs-us-2026"
  # usa provider default (sem alias)
}

resource "aws_s3_bucket" "logs_eu" {
  provider = aws.eu
  bucket   = "logs-eu-2026"
}

resource "aws_s3_bucket" "auditoria" {
  provider = aws.audit
  bucket   = "auditoria-central-2026"
}
```

A sintaxe é **`TIPO.ALIAS`**, sem aspas. Fica parecido com referência a recurso, mas é metadado de provider.

## Propagação para data sources

Data sources também aceitam:

```hcl
data "aws_caller_identity" "audit" {
  provider = aws.audit
}
```

## Aliases em módulos

Módulos **não herdam** aliases automaticamente. Você precisa passá-los via `providers = { ... }` na chamada:

Módulo (declaração de que aceita aliases):

```hcl
# modules/s3-bucket/versions.tf
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

# modules/s3-bucket/main.tf
resource "aws_s3_bucket" "this" {
  provider = aws.primary
  bucket   = var.nome
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.nome}-replica"
}
```

Uso do módulo:

```hcl
module "logs" {
  source = "./modules/s3-bucket"
  nome   = "logs-2026"

  providers = {
    aws.primary = aws           # default do caller
    aws.replica = aws.eu
  }
}
```

## Exemplo: replicação cross-region

```hcl
provider "aws" {
  alias  = "source"
  region = "us-east-1"
}

provider "aws" {
  alias  = "destination"
  region = "us-west-2"
}

resource "aws_s3_bucket" "source" {
  provider = aws.source
  bucket   = "backup-source"
}

resource "aws_s3_bucket" "destination" {
  provider = aws.destination
  bucket   = "backup-destination"
}

resource "aws_s3_bucket_replication_configuration" "this" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id
  role     = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

## Exemplo: multi-conta

```hcl
variable "conta_workload_id" { type = string }
variable "conta_audit_id"    { type = string }

provider "aws" {
  alias = "workload"
  assume_role {
    role_arn = "arn:aws:iam::${var.conta_workload_id}:role/terraform"
  }
}

provider "aws" {
  alias = "audit"
  assume_role {
    role_arn = "arn:aws:iam::${var.conta_audit_id}:role/terraform"
  }
}

resource "aws_cloudtrail" "org" {
  provider = aws.audit
  # ...
}

resource "aws_instance" "app" {
  provider = aws.workload
  # ...
}
```

## Loops sobre aliases (for_each)

Recursos podem iterar sobre uma lista de alias usando o meta-argumento `for_each` **somente indiretamente** — aliases não suportam `for_each` no bloco `provider`. Se precisar provisionar o mesmo recurso em N regiões, você geralmente usa N blocos `provider "aws" { alias = "..." }` e orquestra via módulos.

Alternativa emergente (Terraform 1.5+): `providers` como argumento de `for_each` em módulos é experimental e raramente utilizada; a prática mainstream é alias manual.

## Boas práticas

- **Nomeie aliases** de forma descritiva: `us`, `eu`, `audit`, `workload`, `sandbox`.
- **Documente** no README quais aliases o módulo espera.
- Em CI/CD, confirme que **credenciais/roles** permitem assumir tudo antes do apply.
- Mantenha o **número de aliases baixo** — cada um é uma superfície de falha.
- Se o projeto cresce em complexidade, considere **separar em diretórios/repositórios** distintos (um para cada conta/região) com state próprio.

## Erros comuns

- **Esquecer `provider = aws.alias`**: o recurso vai para a config default, errado.
- **Usar alias inexistente**: erro `Reference to undeclared provider`.
- **Passar `providers = {}` incompleto em módulos**: erro explícito do Terraform.
- **Confundir aliases com workspaces**: aliases configuram providers; workspaces isolam state.

No próximo tópico: **autenticação e credenciais**.
