# Exercício 01 - Provisionar backend S3 + DynamoDB

*(Integra `exercicios/2_intermediarios/13.md` - Backend remoto S3.)*

## Objetivo

Criar manualmente a infraestrutura de suporte ao backend remoto (bucket S3 + DynamoDB) e então migrar um state local para ele.

## Parte 1: Provisionar infra do backend

Use um diretório **separado** (`bootstrap-backend/`) com state local para criar:

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "prefixo" {
  type    = string
  default = "toolbox-terraform"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.prefixo}-tfstate"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "${var.prefixo}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.locks.name
}
```

Rode `init/apply`. Anote os outputs.

## Parte 2: Criar app de exemplo com backend local

Em outra pasta (`app-demo/`), crie um projeto simples com state local:

```hcl
resource "aws_s3_bucket" "exemplo" {
  bucket = "demo-app-${random_id.sufixo.hex}"
}

resource "random_id" "sufixo" {
  byte_length = 4
}
```

Rode `apply` — o state vai para `app-demo/terraform.tfstate`.

## Parte 3: Migrar para o backend remoto

Adicione ao `app-demo`:

```hcl
terraform {
  backend "s3" {
    bucket         = "toolbox-terraform-tfstate"
    key            = "app-demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "toolbox-terraform-locks"
    encrypt        = true
  }
}
```

Execute:

```bash
terraform init -migrate-state
```

Confirme com `yes`.

## Validação

```bash
# state agora vive no S3
terraform state list

# objeto no bucket
aws s3 ls s3://toolbox-terraform-tfstate/app-demo/

# local .tfstate pode ser removido (já está no remoto)
rm terraform.tfstate terraform.tfstate.backup
```

## Perguntas

1. Qual a utilidade de `versioning` no bucket?
2. Por que `encrypt = true` no backend S3 se o bucket já faz SSE?
3. O que aconteceria se você rodasse `init -reconfigure` em vez de `-migrate-state`?

## Importância da segurança do state

Comente no README do projeto (em ~5 linhas) por que:

- State não pode ir pro Git.
- Encryption at rest é obrigatório.
- Lock evita corrupção por corrida.
- Versioning permite rollback em caso de desastre.
