# 10_02 - Criando seu primeiro módulo

## Ponto de partida

Você tem este `main.tf` funcional que cria um bucket S3 padronizado:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "meu-projeto-logs-2026"

  tags = {
    Name       = "logs"
    Ambiente   = "prod"
    ManagedBy  = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

Você quer que isso vire um módulo reutilizável.

## Passo 1 - Criar estrutura

```
projeto/
├── main.tf              # uso do módulo
├── versions.tf
└── modules/
    └── bucket-seguro/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

```bash
mkdir -p modules/bucket-seguro
cd modules/bucket-seguro
touch main.tf variables.tf outputs.tf README.md
```

## Passo 2 - Definir inputs (`variables.tf`)

O que seu módulo precisa receber do caller?

```hcl
variable "nome" {
  description = "Nome do bucket (sem prefixo de ambiente)."
  type        = string

  validation {
    condition     = length(var.nome) >= 3 && length(var.nome) <= 63
    error_message = "Nome deve ter entre 3 e 63 caracteres."
  }
}

variable "ambiente" {
  description = "Ambiente (dev, hml, prod)."
  type        = string
}

variable "versionamento" {
  description = "Habilita versionamento."
  type        = bool
  default     = true
}

variable "tags_extras" {
  description = "Tags adicionais."
  type        = map(string)
  default     = {}
}
```

## Passo 3 - Recursos (`main.tf`)

```hcl
locals {
  nome_completo = "${var.ambiente}-${var.nome}"

  tags = merge(
    {
      Name      = local.nome_completo
      Ambiente  = var.ambiente
      ManagedBy = "terraform"
    },
    var.tags_extras,
  )
}

resource "aws_s3_bucket" "this" {
  bucket = local.nome_completo
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versionamento ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

Repare: nome do recurso é `this` — convenção quando o módulo contém "um" recurso principal.

## Passo 4 - Outputs (`outputs.tf`)

O que o caller precisa saber?

```hcl
output "id" {
  description = "ID do bucket."
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "ARN do bucket."
  value       = aws_s3_bucket.this.arn
}

output "nome" {
  description = "Nome completo do bucket (com ambiente)."
  value       = aws_s3_bucket.this.bucket
}
```

**Exponha o mínimo necessário.** Se o caller não precisa de uma informação, não crie output — reduz acoplamento.

## Passo 5 - Usar o módulo

No `main.tf` raiz:

```hcl
module "bucket_logs" {
  source = "./modules/bucket-seguro"

  nome     = "logs"
  ambiente = "prod"

  tags_extras = {
    Owner = "plataforma"
  }
}

module "bucket_backup" {
  source = "./modules/bucket-seguro"

  nome          = "backup"
  ambiente      = "prod"
  versionamento = true
}

output "bucket_logs_arn" {
  value = module.bucket_logs.arn
}
```

## Passo 6 - Inicializar

Toda vez que você **adiciona** ou **modifica** o `source` de um módulo, precisa rodar:

```bash
terraform init
```

Sem `init`, Terraform não sabe que o módulo existe.

## Passo 7 - Plan e Apply

```bash
terraform plan
```

Output parcial:

```
# module.bucket_logs.aws_s3_bucket.this will be created
+ resource "aws_s3_bucket" "this" {
    + bucket = "prod-logs"
    ...
  }

# module.bucket_backup.aws_s3_bucket.this will be created
+ resource "aws_s3_bucket" "this" {
    + bucket = "prod-backup"
    ...
  }
```

Repare no prefixo `module.NOME`. Isso mostra que os recursos estão dentro do módulo.

```bash
terraform apply
```

## Passo 8 - Observando o state

```bash
terraform state list
# module.bucket_logs.aws_s3_bucket.this
# module.bucket_logs.aws_s3_bucket_versioning.this
# module.bucket_logs.aws_s3_bucket_server_side_encryption_configuration.this
# module.bucket_logs.aws_s3_bucket_public_access_block.this
# module.bucket_backup.aws_s3_bucket.this
# ...
```

Para inspecionar um recurso:

```bash
terraform state show module.bucket_logs.aws_s3_bucket.this
```

## Passo 9 - Documentar (`README.md`)

```markdown
# Módulo bucket-seguro

Cria um bucket S3 com padrões de segurança: versionamento, encryption e block public access.

## Uso

\`\`\`hcl
module "logs" {
  source = "./modules/bucket-seguro"

  nome     = "logs"
  ambiente = "prod"
}
\`\`\`

## Inputs

| Nome | Tipo | Default | Descrição |
|------|------|---------|-----------|
| nome | string | - | Nome do bucket (sem prefixo). |
| ambiente | string | - | dev/hml/prod. |
| versionamento | bool | true | Habilita versionamento. |
| tags_extras | map(string) | {} | Tags adicionais. |

## Outputs

| Nome | Descrição |
|------|-----------|
| id | ID do bucket. |
| arn | ARN do bucket. |
| nome | Nome completo (com prefixo). |
```

## Boas práticas já aplicadas aqui

- **Defaults sensatos** (versionamento on).
- **Validação** de input.
- **Tags padronizadas** + merge com extras.
- **Nomes previsíveis** (prefixo de ambiente).
- **Security defaults** (block public access).
- **Outputs mínimos** e documentados.

## Padrão "multi-recurso"

Quando seu módulo cria **vários** recursos principais (ex.: VPC com subnets, route tables, IGW), prefira nomes descritivos ao invés de `this`:

```hcl
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_subnet" "private" { ... }
```

## Resumo

Módulo criado = `variables.tf` + `main.tf` + `outputs.tf` + docs + exemplos.
O caller chama via `module "nome" { source = "./path" }` e consome via `module.nome.output`.

Próximo tópico: **passando inputs** — padrões e pitfalls.
