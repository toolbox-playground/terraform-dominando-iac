# 10_03 - Inputs e Outputs de módulos

A **interface** do módulo = inputs + outputs. Um módulo é uma "caixa": o pai passa dados via `variables` e consome resultados via `outputs`.

## Inputs: padrões de design

### 1. Inputs obrigatórios x opcionais

```hcl
# Obrigatório: sem default
variable "nome" {
  type = string
}

# Opcional: com default sensato
variable "retencao_dias" {
  type    = number
  default = 30
}
```

Regra: **se o módulo não pode funcionar sem**, não dê default. Obrigue o caller a fornecer.

### 2. Inputs granulares vs. objeto

**Granular** (muitos inputs):

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr               = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  habilitar_nat      = true
  habilitar_dns      = true
  subnets_publicas   = ["10.0.1.0/24", "10.0.2.0/24"]
  subnets_privadas   = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

**Objeto agrupado**:

```hcl
variable "config" {
  type = object({
    cidr             = string
    azs              = list(string)
    habilitar_nat    = bool
    subnets_publicas = list(string)
    subnets_privadas = list(string)
  })
}

module "vpc" {
  source = "./modules/vpc"
  config = {
    cidr             = "10.0.0.0/16"
    azs              = ["us-east-1a", "us-east-1b"]
    habilitar_nat    = true
    subnets_publicas = ["10.0.1.0/24"]
    subnets_privadas = ["10.0.11.0/24"]
  }
}
```

**Granular é melhor** em módulos pequenos (mais descoberta em IDE, defaults por campo).
**Objeto** faz sentido quando os campos "viajam juntos" conceitualmente (ex.: `scaling_config`).

### 3. Atributos opcionais em objetos (Terraform 1.3+)

```hcl
variable "config" {
  type = object({
    cidr          = string
    habilitar_nat = optional(bool, false)
    tags          = optional(map(string), {})
  })
}
```

### 4. Listas tipadas de objetos

Ótimo para `for_each`:

```hcl
variable "usuarios" {
  type = list(object({
    nome  = string
    email = string
    admin = optional(bool, false)
  }))
  default = []
}
```

### 5. Validação

```hcl
variable "ambiente" {
  type = string

  validation {
    condition     = contains(["dev", "hml", "prod"], var.ambiente)
    error_message = "Ambiente deve ser dev, hml ou prod."
  }
}

variable "cidr" {
  type = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "CIDR inválido."
  }
}
```

Valide **no módulo** — protege todos os consumers.

### 6. Sensitive

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

O módulo **continua marcando** como sensitive no state e em outputs derivados.

## Outputs: padrões de design

### 1. Exponha o mínimo

Cada output = acoplamento. Expor "tudo" = caller pode começar a depender de coisas que você gostaria de mudar.

### 2. Exponha **referências**, não strings formatadas

Ruim:
```hcl
output "bucket_url" {
  value = "https://${aws_s3_bucket.this.bucket}.s3.amazonaws.com"
}
```

Melhor:
```hcl
output "bucket_id" {
  value = aws_s3_bucket.this.id
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}
```

Deixe o caller compor URLs se quiser.

### 3. Grupe outputs relacionados

```hcl
output "vpc" {
  description = "Informações da VPC criada."
  value = {
    id         = aws_vpc.main.id
    cidr       = aws_vpc.main.cidr_block
    default_sg = aws_vpc.main.default_security_group_id
  }
}
```

Vs. 3 outputs separados. Preferência é estilística — mas objetos facilitam "passar adiante".

### 4. Outputs sensitive

Se um valor derivado contém algo sensível:

```hcl
output "db_connection_string" {
  value     = "postgres://${aws_db_instance.main.username}:${random_password.db.result}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive = true
}
```

### 5. Outputs condicionais

Se você cria um recurso opcional, use splat ou `try()`:

```hcl
resource "aws_eip" "this" {
  count = var.eip_publico ? 1 : 0
}

output "ip_publico" {
  value = try(aws_eip.this[0].public_ip, null)
}
```

### 6. Dependências explícitas via `depends_on`

Raro, mas existe: quando um consumer precisa esperar por efeito colateral de outro recurso do módulo:

```hcl
output "url" {
  value      = "https://${aws_lb.this.dns_name}"
  depends_on = [aws_lb_listener.this]
}
```

## Passando dados entre módulos

### Encadeamento

```hcl
module "vpc" {
  source = "./modules/vpc"
  cidr   = "10.0.0.0/16"
}

module "eks" {
  source = "./modules/eks"

  vpc_id     = module.vpc.id
  subnet_ids = module.vpc.subnets_privadas
}
```

### Locals para não repetir

```hcl
locals {
  tags_padrao = {
    Projeto   = "loja-online"
    Ambiente  = var.ambiente
    ManagedBy = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"
  tags   = local.tags_padrao
}

module "rds" {
  source = "./modules/rds"
  tags   = local.tags_padrao
}
```

## Pitfalls

### 1. Modificar estruturas default

```hcl
variable "tags" {
  type    = map(string)
  default = { ManagedBy = "terraform" }
}
```

Se o caller passar `tags = { Env = "prod" }`, o default **não** é mergeado. Use pattern:

```hcl
variable "tags_base" {
  type    = map(string)
  default = { ManagedBy = "terraform" }
}

variable "tags_extras" {
  type    = map(string)
  default = {}
}

locals {
  tags = merge(var.tags_base, var.tags_extras)
}
```

Ou documente explicitamente que o caller deve mergear.

### 2. Esperar que o módulo "saiba" contexto do pai

Módulos **não** acessam variáveis do pai. Se precisa, declare no próprio módulo.

### 3. Usar `self` em referências cruzadas entre módulos

```hcl
# DENTRO do módulo VPC
module "outra_coisa" {
  source = "./outra"
  vpc_id = aws_vpc.main.id  # OK
}
```

Módulos podem chamar outros módulos (submódulos) — mas cuidado com profundidade. **Máximo 2 níveis** como regra prática.

### 4. Outputs que bloqueiam destroy

Outputs dependem de recursos. Ao remover um recurso, remova o output também ou use `try()`.

## Exemplo completo: módulo ECS service

```hcl
# modules/ecs-service/variables.tf
variable "nome" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "container" {
  type = object({
    imagem = string
    porta  = number
    cpu    = optional(number, 256)
    memory = optional(number, 512)
    env    = optional(map(string), {})
  })
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

```hcl
# modules/ecs-service/outputs.tf
output "service_arn" {
  value = aws_ecs_service.this.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
```

## Resumo

- **Inputs**: granulares ou em objeto; obrigatórios sem default; valide sempre.
- **Outputs**: mínimos; exponha referências, não strings formatadas; agrupe quando fizer sentido.
- **Sensitive**: propague.
- **Interface estável**: mude com cuidado, pode quebrar callers.

Próximo tópico: **sources e versionamento** — como distribuir módulos.
