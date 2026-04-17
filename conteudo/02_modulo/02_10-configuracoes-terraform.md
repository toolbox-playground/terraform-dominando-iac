# 02_10 - Configurações do Terraform

## Visão geral

"Configuração Terraform" é o conjunto de arquivos `.tf` (ou `.tf.json`) em um diretório que, juntos, descrevem **o que** você quer provisionar. O Terraform lê **todos os arquivos com extensão `.tf`** no diretório atual (não recursivo) e trata como se fossem um só.

Neste tópico: tipos de blocos, convenções de arquivos e um exemplo mínimo completo.

## Blocos fundamentais

### `terraform`

Configura o próprio Terraform: versão mínima, providers obrigatórios, backend de state.

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "meu-tf-state"
    key    = "projeto/prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### `provider`

Configura uma integração específica (AWS, GCP, Azure, etc.). Pode haver vários providers em um mesmo diretório.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

### `resource`

Declara um recurso a ser gerenciado. É o bloco mais comum.

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "logs-producao-2026"

  tags = {
    Ambiente = "producao"
  }
}
```

Sintaxe: `resource "<tipo>" "<nome_local>" { ... }`

- `tipo`: vem do provider (`aws_s3_bucket`, `google_storage_bucket`).
- `nome_local`: identificador Terraform (`logs`). Usado em referências: `aws_s3_bucket.logs.arn`.

### `data`

Consulta dados existentes **sem gerenciar** (somente leitura).

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

### `variable`

Input da configuração. Permite parametrizar.

```hcl
variable "ambiente" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.ambiente)
    error_message = "Ambiente deve ser dev, staging ou prod."
  }
}
```

Uso: `var.ambiente`.

### `output`

Expõe valor para consumo externo (CLI, pipelines, outros módulos).

```hcl
output "bucket_arn" {
  description = "ARN do bucket de logs"
  value       = aws_s3_bucket.logs.arn
}

output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

### `locals`

Valores calculados e reutilizáveis dentro da configuração (não são inputs nem outputs).

```hcl
locals {
  name_prefix = "${var.ambiente}-${var.projeto}"

  common_tags = {
    Ambiente = var.ambiente
    Projeto  = var.projeto
    Criado   = "terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"
  tags   = local.common_tags
}
```

### `module`

Chama outro diretório de configuração como unidade reutilizável.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "minha-vpc"
  cidr = "10.0.0.0/16"
}
```

O Módulo 10 do curso cobre módulos em detalhe.

## Convenções de arquivos

Terraform **não** impõe nomes de arquivo, mas a comunidade adotou:

| Arquivo | Conteúdo típico |
|---------|-----------------|
| `main.tf` | Recursos principais |
| `variables.tf` | Declarações de `variable` |
| `outputs.tf` | Declarações de `output` |
| `versions.tf` ou `providers.tf` | Bloco `terraform {}` e `provider` |
| `locals.tf` | Bloco `locals` (opcional) |
| `data.tf` | Blocos `data` (opcional) |
| `terraform.tfvars` | Valores das variáveis (NÃO commitar se tiver segredos) |
| `*.auto.tfvars` | Valores carregados automaticamente |
| `.terraform.lock.hcl` | Lock de versões de providers (commit sim!) |

Em módulos maiores, agrupar por domínio também é válido:

```text
infra/
├── network.tf
├── compute.tf
├── storage.tf
├── iam.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

## Arquivos que **não** se commita

- `.terraform/` — cache de providers/módulos baixados.
- `*.tfstate` e `*.tfstate.backup` — contém IDs e às vezes segredos.
- `terraform.tfvars` ou `*.auto.tfvars` com **segredos**.
- `crash.log` — gerado em caso de crash.

Modelo `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
crash.log
```

## Arquivos que **se commita**

- Todos os `.tf`.
- `.terraform.lock.hcl` — garante reprodutibilidade.
- `README.md` do módulo.
- `terraform.tfvars.example` (sem valores sensíveis, só placeholder).

## Exemplo mínimo completo

Pasta com:

```text
meu-projeto/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── .gitignore
```

**versions.tf**

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
```

**variables.tf**

```hcl
variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}
```

**main.tf**

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name

  tags = {
    Criado_por = "terraform"
  }
}
```

**outputs.tf**

```hcl
output "bucket_arn" {
  description = "ARN do bucket"
  value       = aws_s3_bucket.logs.arn
}
```

**terraform.tfvars**

```hcl
bucket_name = "meu-bucket-unico-2026"
```

**.gitignore**

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
```

Executando:

```bash
terraform init
terraform plan
terraform apply
terraform output
```

## Dicas finais

- **Comece mínimo** — você pode crescer para módulos, workspaces, backends depois.
- **Nome de recurso é convenção do Terraform**, não aparece na nuvem — mas impacta refatoração. Escolha bem (snake_case, descritivo).
- **Tag tudo** — tags viram contrato de governança (cost center, owner, ambiente).
- **Separe segredos** — use variáveis `sensitive = true`, `TF_VAR_*`, ou secret managers.

## Referências

- [Terraform Language Overview](https://developer.hashicorp.com/terraform/language)
- [Style Conventions](https://developer.hashicorp.com/terraform/language/syntax/style)
- [Standard Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
