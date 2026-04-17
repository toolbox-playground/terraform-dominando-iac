# 05_02 - Sintaxe Básica

## Estrutura geral

Todo arquivo `.tf` é uma sequência de **blocos**. Cada bloco tem:

1. Um **tipo** (ex.: `resource`, `variable`, `provider`).
2. **Zero ou mais labels** (rótulos) entre aspas.
3. Um **corpo** `{ ... }` com atributos e sub-blocos.

```hcl
<TIPO_DO_BLOCO> [LABEL1] [LABEL2] {
  <ATRIBUTO> = <VALOR>

  <SUB_BLOCO> {
    <ATRIBUTO> = <VALOR>
  }
}
```

## Blocos do Terraform (tabela)

| Bloco | Labels esperados | Exemplo |
|-------|-----------------|---------|
| `terraform` | nenhum | `terraform { required_version = ">= 1.5" }` |
| `provider` | 1 (nome) | `provider "aws" { region = "us-east-1" }` |
| `resource` | 2 (tipo, nome) | `resource "aws_s3_bucket" "logs" { ... }` |
| `data` | 2 (tipo, nome) | `data "aws_ami" "ubuntu" { ... }` |
| `variable` | 1 (nome) | `variable "ambiente" { ... }` |
| `output` | 1 (nome) | `output "bucket_arn" { ... }` |
| `locals` | nenhum | `locals { nome = "app" }` |
| `module` | 1 (nome) | `module "vpc" { source = "..." }` |

## Atributos

São pares `chave = valor`:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket        = "logs-2026"
  force_destroy = true
  tags = {
    Env = "prod"
  }
}
```

- **Nomes de atributos**: lowercase + `_`.
- **Valores**: podem ser literais (string, number, bool), referências (`var.x`, `aws_vpc.main.id`), funções (`upper("x")`), expressões (`var.x + 1`).

## Sub-blocos

Alguns atributos são na verdade **blocos aninhados** (não pares chave=valor):

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tag {
    key                 = "Env"
    value               = "prod"
    propagate_at_launch = true
  }
}
```

**Diferença chave**:
- Atributo com chave = valor: `tags = { ... }` (um valor `map`).
- Sub-bloco: `root_block_device { ... }` (sem `=`).

A documentação de cada recurso no Registry diz qual é qual.

## Identificadores

- Começam com **letra** ou underscore.
- Continuam com letras, dígitos, `_` ou `-`.
- Case-sensitive.
- **Convenção**: `snake_case` para atributos e nomes de recursos.

Exemplos válidos: `web_server`, `bucket_01`, `ambiente`, `_interno`.
Exemplos inválidos: `1web`, `web server`, `web.server`.

## Comentários

```hcl
# comentário estilo shell

// comentário estilo C

/*
  comentário
  em várias linhas
*/
```

`terraform fmt` padroniza todos para `#`.

## Aspas e quoting

HCL tem vários tipos de strings:

### String simples (dupla aspa)

```hcl
nome = "web-01"
```

### String com interpolação

```hcl
nome = "web-${var.ambiente}"
```

Dentro de `"${...}"` você pode colocar qualquer expressão HCL.

### String heredoc (multilinha)

```hcl
script = <<-EOT
  #!/bin/bash
  apt-get update
  apt-get install -y nginx
EOT
```

O `-` em `<<-` permite indentar; o HCL remove a indentação comum.

### String bruta (aspa simples)

HCL **não** tem string bruta como Python — strings são sempre `"..."`. Aspas simples **não** funcionam.

## Valores literais

### Number

```hcl
porta    = 80
cpu      = 0.5
negativo = -42
```

### Bool

```hcl
habilitado = true
arquivado  = false
```

### Null

```hcl
opcional = null
```

`null` sinaliza "sem valor" — o atributo assume o default do provider.

## Igualdade e atribuição

Sempre `=`, nunca `:` (JSON-style).

```hcl
# Correto
nome = "web"

# Errado (estilo JSON)
nome: "web"
```

## Listas e mapas literais

```hcl
regioes = ["us-east-1", "us-west-2"]

tags = {
  Env   = "prod"
  Owner = "plataforma"
}
```

Mais detalhes em [05_04 - Tipos complexos](05_04-tipos-complexos.md).

## Espaçamento e quebras de linha

- Indentação: **2 espaços**, sem tab.
- Blocos separados por **linha em branco**.
- Atributos não separados por vírgulas (diferente de JSON).

## Anatomia comentada

```hcl
# versions.tf - Define requisitos da ferramenta

terraform {                              # bloco de configuração do Terraform
  required_version = ">= 1.5"            # atributo: versão mínima
  required_providers {                   # sub-bloco: providers obrigatórios
    aws = {
      source  = "hashicorp/aws"          # chave/valor dentro de mapa
      version = "~> 5.0"
    }
  }
}

provider "aws" {                         # bloco provider, label "aws"
  region = "us-east-1"
}

variable "ambiente" {                    # bloco variable, label "ambiente"
  description = "Ambiente de deploy"
  type        = string
  default     = "dev"
}

resource "aws_s3_bucket" "logs" {        # resource, labels "tipo" "nome"
  bucket = "logs-${var.ambiente}-2026"   # atributo com interpolação

  tags = {                               # atributo do tipo map
    Env = var.ambiente
  }

  lifecycle {                            # sub-bloco lifecycle
    prevent_destroy = true
  }
}

output "bucket_arn" {                    # bloco output
  value = aws_s3_bucket.logs.arn         # referência a atributo de outro recurso
}
```

## Referências

- [HCL Syntax](https://developer.hashicorp.com/terraform/language/syntax/configuration)
- [Style Conventions](https://developer.hashicorp.com/terraform/language/syntax/style)
