# 03_02 - Write

## O que é a fase Write

**Write** é o ato de escrever e evoluir os arquivos `.tf` que descrevem sua infraestrutura. Aparentemente "é só editar um arquivo", mas a qualidade dessa fase determina a saúde do seu código a longo prazo.

## Convenções de arquivos

Conforme visto em [02_10 - Configurações](../02_modulo/02_10-configuracoes-terraform.md), a comunidade adota uma separação por responsabilidade:

```text
meu-projeto/
├── versions.tf        # bloco terraform, required_providers
├── providers.tf       # bloco provider (pode estar em versions.tf)
├── variables.tf       # declarações de variable
├── locals.tf          # bloco locals (opcional)
├── data.tf            # blocos data (opcional)
├── main.tf            # recursos principais
├── outputs.tf         # declarações de output
├── terraform.tfvars   # valores (NÃO commitar se tiver segredos)
└── README.md          # explicação do módulo/projeto
```

Em módulos maiores, **agrupar por domínio** pode fazer mais sentido:

```text
infra/
├── versions.tf
├── variables.tf
├── outputs.tf
├── network.tf         # VPC, subnets, security groups
├── compute.tf         # EC2, ASG, ALB
├── storage.tf         # S3, EBS
├── iam.tf             # roles, policies
└── README.md
```

A regra de ouro: **um desenvolvedor novo no projeto deve conseguir encontrar onde um recurso foi declarado em menos de 30 segundos**.

## Estilo HCL — regras essenciais

### 1. Indentação: **2 espaços**, nunca tab

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "meus-logs"

  tags = {
    Projeto = "plataforma"
  }
}
```

### 2. Atributos alinhados com `=`

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"
  key_name      = "minha-key"
}
```

`terraform fmt` alinha automaticamente. Não se preocupe em alinhar manualmente.

### 3. Blocos aninhados separados por linha em branco

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "web"
  }
}
```

### 4. Nomes em `snake_case`

- Recurso: `resource "aws_s3_bucket" "bucket_de_logs"` ✅
- Recurso: `resource "aws_s3_bucket" "BucketDeLogs"` ❌ (não proibido, mas destoa)
- Variável: `bucket_name` ✅ / `bucketName` ❌

### 5. Use nomes descritivos, não prefixos redundantes

- ✅ `resource "aws_s3_bucket" "logs"` → referência: `aws_s3_bucket.logs.arn`
- ❌ `resource "aws_s3_bucket" "s3_bucket_logs"` → ruído: `aws_s3_bucket.s3_bucket_logs.arn`

### 6. Comentários explicam **o porquê**, não o **o quê**

```hcl
# ERRADO
# Cria um bucket S3
resource "aws_s3_bucket" "logs" { ... }

# CORRETO
# Bucket destinado a logs de CloudTrail; retenção gerida por compliance.
resource "aws_s3_bucket" "logs" { ... }
```

## Boas práticas de autoria

### Parametrize cedo

Resista à tentação de hardcoded. Se há qualquer chance de um valor mudar entre ambientes, transforme em variável:

```hcl
# Ruim
resource "aws_instance" "web" {
  instance_type = "t3.micro"
}

# Bom
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

Isso prepara o código para ser reutilizado.

### Use `locals` para valores calculados

```hcl
locals {
  name_prefix = "${var.ambiente}-${var.projeto}"
  common_tags = {
    Ambiente = var.ambiente
    Projeto  = var.projeto
    Owner    = var.owner
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"
  tags   = local.common_tags
}
```

Repetir a mesma expressão em N recursos é convite a bug. `locals` é DRY para Terraform.

### Descrições e tipos explícitos

```hcl
# Ruim
variable "region" {
  default = "us-east-1"
}

# Bom
variable "region" {
  description = "Região AWS para todos os recursos"
  type        = string
  default     = "us-east-1"
}
```

Ter `description` + `type` é leitura obrigatória em módulos públicos e fortemente recomendada em privados.

### Outputs com descrição

```hcl
output "bucket_arn" {
  description = "ARN do bucket de logs para uso em políticas IAM externas"
  value       = aws_s3_bucket.logs.arn
}
```

### Evite lógica excessiva dentro de recursos

Cálculos complexos ficam melhor em `locals`:

```hcl
# Ruim
resource "aws_s3_bucket" "b" {
  bucket = lower(replace("${var.projeto}-${var.env}", "_", "-"))
}

# Bom
locals {
  bucket_name = lower(replace("${var.projeto}-${var.env}", "_", "-"))
}

resource "aws_s3_bucket" "b" {
  bucket = local.bucket_name
}
```

Mais fácil de testar, debugar e reutilizar.

## Git: tratando Terraform como código real

### `.gitignore` essencial

```gitignore
# diretório de trabalho do Terraform
.terraform/
.terraform.tfstate.lock.info

# state local (se usar)
*.tfstate
*.tfstate.*
crash.log
crash.*.log

# variáveis com segredos
*.tfvars
*.tfvars.json
!example.tfvars
!*.tfvars.example

# plano salvo
*.tfplan
```

### Arquivos para commitar

- Todos os `.tf`.
- `.terraform.lock.hcl` — **sim**, commita (garante reprodutibilidade de providers).
- `README.md` — sim.
- `terraform.tfvars.example` — sim, sem valores reais.

### Mensagens de commit úteis

Siga convenção, ex.: [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(rds): adiciona read replica em us-east-2
fix(iam): corrige policy faltando permissao s3:PutObject
refactor(vpc): extrai blocos em modulo aws-vpc
chore(providers): atualiza aws 4.x -> 5.x
```

### Revisão em PR

Em PR de Terraform, o revisor deve olhar:

1. O **plan anexado** (se CI publica) — mostra impacto real.
2. Se o diff afeta **recursos críticos** (prod, DB, DNS).
3. Se **testes de política** (Sentinel, OPA, tflint) passaram.
4. Se variáveis novas têm `description` e `type`.
5. Se há hardcoded que deveria ser variável.

## Ferramentas de apoio

- **`terraform fmt`** — formatação ([03_04](03_04-fmt.md)).
- **`terraform validate`** — sintaxe e referências ([03_03](03_03-validate.md)).
- **[tflint](https://github.com/terraform-linters/tflint)** — linter avançado (atributos inválidos, AMIs inexistentes).
- **[tfsec](https://github.com/aquasecurity/tfsec) / [Checkov](https://www.checkov.io/)** — análise de segurança estática.
- **[terraform-docs](https://github.com/terraform-docs/terraform-docs)** — gera README a partir do código.
- **[pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)** — bundle dos hooks acima.

## Sinais de que seu código precisa de atenção

- Mesmo valor repetido em vários lugares (crie `locals` ou variável).
- Recursos gigantescos com dezenas de atributos (considere módulo).
- `main.tf` com > 500 linhas (quebre por domínio).
- Plan muito longo e difícil de revisar (refatore).
- Atributos sem comentário explicando "por quê esse valor".

## Referências

- [Style Conventions](https://developer.hashicorp.com/terraform/language/syntax/style)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Provider Registry Docs](https://registry.terraform.io/)
