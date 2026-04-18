# 05_08 - Exemplo Completo Comentado

Este tópico consolida tudo que foi visto no módulo em um projeto pequeno, porém realista: provisionar uma aplicação web em EC2 com bucket de logs, security group e IAM role. Cada bloco é explicado.

## Estrutura de arquivos

```
app-web/
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── templates/
    └── user-data.sh.tpl
```

## `versions.tf`

```hcl
# Requisitos de versão: trava a ferramenta e o provider.
# Isso garante reprodutibilidade entre máquinas e no CI.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # aceita 5.x, mas não 6.0
    }
  }
}
```

Conceitos aplicados:
- **Bloco `terraform`** (sem labels).
- **`required_providers`** com mapa cujo valor é um `object`.
- **Constraint** `~> 5.0` (pessimistic constraint).

## `providers.tf`

```hcl
# Configura o provider AWS. A região vem de variável.
provider "aws" {
  region = var.regiao

  default_tags {
    tags = local.tags_padrao
  }
}
```

Conceitos:
- **Referência a variável**: `var.regiao`.
- **Sub-bloco `default_tags`** — aplicado a todos os recursos AWS.
- **Referência a `local`**: `local.tags_padrao`.

## `variables.tf`

```hcl
variable "projeto" {
  description = "Nome do projeto"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.projeto))
    error_message = "Use apenas minúsculas, dígitos e hifens (3-31 chars)."
  }
}

variable "ambiente" {
  description = "Ambiente de deploy"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "hml", "prod"], var.ambiente)
    error_message = "Ambiente deve ser: dev, hml ou prod."
  }
}

variable "regiao" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type_por_ambiente" {
  description = "Tipo de instância por ambiente"
  type        = map(string)

  default = {
    dev  = "t3.micro"
    hml  = "t3.small"
    prod = "t3.large"
  }
}

variable "tags_extras" {
  description = "Tags adicionais aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
```

Conceitos:
- **`description`** explicita o propósito.
- **`type`** com primitivo (`string`) e complexo (`map(string)`).
- **`validation`** com `can(regex(...))` e `contains(...)`.
- **Defaults** para evitar pedir tudo toda vez.

## `locals.tf`

```hcl
locals {
  nome_base = lower("${var.projeto}-${var.ambiente}")

  tags_padrao = merge(
    {
      Projeto     = var.projeto
      Ambiente    = var.ambiente
      ManagedBy   = "terraform"
      CostCenter  = var.ambiente == "prod" ? "business" : "engineering"
    },
    var.tags_extras,
  )

  instance_type = var.instance_type_por_ambiente[var.ambiente]

  nome_bucket = "${local.nome_base}-logs"
  nome_sg     = "${local.nome_base}-web-sg"
}
```

Conceitos:
- **`locals`** centraliza cálculos/derivações.
- **Interpolação** com `"${...}-${...}"`.
- **Ternário** em `var.ambiente == "prod" ? ... : ...`.
- **`merge(...)`** para combinar mapas (tags padrão + extras).
- **Lookup em map** via `var.instance_type_por_ambiente[var.ambiente]`.

## `main.tf`

```hcl
# --- Data sources: usando recursos existentes na conta ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- Bucket de logs com ciclo de vida ---
resource "aws_s3_bucket" "logs" {
  bucket = local.nome_bucket

  tags = {
    Role = "logs"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-30d"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# --- Security group permitindo HTTP ---
resource "aws_security_group" "web" {
  name        = local.nome_sg
  description = "HTTP para web"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- IAM role para a instância (permite gravar no bucket) ---
resource "aws_iam_role" "web" {
  name = "${local.nome_base}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "web" {
  name = "logs-write"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.logs.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  name = "${local.nome_base}-web-profile"
  role = aws_iam_role.web.name
}

# --- Instância EC2 ---
resource "aws_instance" "web" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = local.instance_type
  subnet_id            = data.aws_subnets.default.ids[0]
  iam_instance_profile = aws_iam_instance_profile.web.name

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    projeto     = var.projeto
    ambiente    = var.ambiente
    log_bucket  = aws_s3_bucket.logs.bucket
  })

  tags = {
    Name = "${local.nome_base}-web"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

Conceitos:
- **`data` sources** para VPC, subnets e AMI.
- **Filtros em data** com sub-blocos `filter`.
- **Dependências implícitas**: `aws_s3_bucket_lifecycle_configuration.logs` referencia `aws_s3_bucket.logs.id`.
- **`jsonencode`** para políticas IAM.
- **Splat/listas**: `data.aws_subnets.default.ids[0]`.
- **`templatefile`** para user-data.
- **`lifecycle { create_before_destroy }`** para imutabilidade.

## `templates/user-data.sh.tpl`

```bash
#!/bin/bash
set -e

echo "Projeto: ${projeto}"
echo "Ambiente: ${ambiente}"
echo "Bucket de logs: ${log_bucket}"

apt-get update
apt-get install -y nginx awscli

# Configura envio de logs para S3 a cada minuto
cat > /etc/cron.d/upload-logs <<EOF
* * * * * root aws s3 cp /var/log/nginx/access.log s3://${log_bucket}/$(hostname)-$(date +%s).log
EOF

systemctl enable --now nginx
```

Conceitos:
- **Template externo** com variáveis `${projeto}`, `${ambiente}`, `${log_bucket}`.
- Separado do HCL → bash com syntax highlight no editor.

## `outputs.tf`

```hcl
output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "IP público da instância"
  value       = aws_instance.web.public_ip
}

output "log_bucket_arn" {
  description = "ARN do bucket de logs"
  value       = aws_s3_bucket.logs.arn
}

output "conexao_ssm" {
  description = "Comando para conectar via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.regiao}"
}
```

Conceitos:
- **Descrição** em cada output.
- Uso em **interpolações** para construir comandos úteis.

## O que este exemplo demonstra

| Conceito | Onde |
|----------|------|
| Blocos `terraform`, `provider`, `variable`, `local`, `resource`, `data`, `output` | Todos os arquivos |
| Tipos primitivos | `variables.tf` (string) |
| Tipos complexos | `variables.tf` (`map(string)`) |
| `locals` para cálculos | `locals.tf` |
| Interpolação em strings | `locals.tf`, `main.tf` |
| Ternário | `locals.tf` |
| `merge`, `jsonencode`, `templatefile` | `locals.tf`, `main.tf` |
| Sub-blocos | `providers.tf` (`default_tags`), `main.tf` (`ingress`, `egress`, `filter`) |
| Dependência implícita | Várias (`.id`, `.arn`, `.name`) |
| Validações de variável | `variables.tf` |
| `lifecycle` | `main.tf` |

## Exercícios sugeridos

Leia o código e responda (no arquivo ou mentalmente):

1. Que aconteceria se `var.ambiente` fosse `"staging"`? (Pista: `validation`)
2. Onde exatamente ocorrem dependências implícitas?
3. Por que `aws_iam_role_policy` e `aws_iam_role` não têm `depends_on`?
4. Como você adicionaria `HTTPS` ao security group preservando o `HTTP`? (Pista: `dynamic` — Módulo 9)
5. Se tiver dois ambientes (dev e prod) apontando para o mesmo bucket, o que aconteceria?

No próximo módulo, **providers**, você vai entender como o provider é configurado de forma mais profunda: versões, aliases, autenticação e múltiplas contas.
