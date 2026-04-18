# 08_03 - Outputs

**Outputs** são a interface de **saída** de um módulo Terraform. Eles:

- Exibem valores no terminal ao final de `apply`.
- Ficam salvos no state.
- Podem ser consumidos por outros projetos via `terraform_remote_state`.
- Quando em um módulo filho, aparecem como atributos do módulo (`module.X.output_Y`).

## Sintaxe

```hcl
output "bucket_arn" {
  description = "ARN do bucket de logs"
  value       = aws_s3_bucket.logs.arn
}
```

Argumentos:

| Argumento | Obrigatório | Uso |
|-----------|-------------|-----|
| `description` | não (recomendado) | Documenta |
| `value` | sim | Expressão que produz o valor |
| `sensitive` | não | Esconde em plan/apply |
| `depends_on` | não | Força dependência explícita |
| `precondition` | não | Valida invariante antes de usar |

## Uso no terminal

Após `apply`, Terraform imprime:

```
Outputs:

bucket_arn = "arn:aws:s3:::logs-prod-2026"
instance_id = "i-0123456789abcdef"
```

Consulta posterior:

```bash
terraform output              # todos
terraform output bucket_arn   # um específico
terraform output -json        # JSON para parsing
terraform output -raw bucket_arn   # sem aspas (útil em scripts)
```

## Exemplos comuns

### Valores simples

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}
```

### Objeto estruturado

```hcl
output "cluster" {
  value = {
    name          = aws_eks_cluster.this.name
    endpoint      = aws_eks_cluster.this.endpoint
    ca_certificate = aws_eks_cluster.this.certificate_authority[0].data
  }
}
```

### Saída sensível

```hcl
output "db_connection_string" {
  value = "postgres://${aws_db_instance.main.username}:${random_password.db.result}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive = true
}
```

No terminal aparece `db_connection_string = <sensitive>`. Para ler em script: `terraform output -raw db_connection_string` (requer permissão).

### Com `precondition`

```hcl
output "bucket_arn" {
  value = aws_s3_bucket.logs.arn

  precondition {
    condition     = aws_s3_bucket.logs.versioning[0].enabled == true
    error_message = "Bucket deve ter versioning habilitado."
  }
}
```

Se a invariante falhar, plan/apply para com erro. Útil para validar estados "impossíveis" gerados por drift.

## Em módulos filhos

Em um módulo reutilizável (`modules/vpc/outputs.tf`):

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

No caller:

```hcl
module "rede" {
  source = "./modules/vpc"
  # ...
}

resource "aws_instance" "web" {
  subnet_id = module.rede.public_subnet_ids[0]
}
```

## Em `terraform_remote_state`

Um projeto consumidor acessa outputs do produtor:

```hcl
data "terraform_remote_state" "rede" {
  backend = "s3"
  config = {
    bucket = "minha-empresa-tfstate"
    key    = "plataforma/rede/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.rede.outputs.public_subnet_ids[0]
}
```

Requisito: o produtor precisa expor os outputs; o consumidor precisa permissão de leitura no backend.

## Sensitive em outputs

Sempre que o `value` envolve dado sensível:

```hcl
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
```

Regra prática: marque como `sensitive` qualquer coisa que você não imprimiria no Slack.

## Output derivado de condição

```hcl
output "nat_public_ip" {
  description = "IP público do NAT, quando habilitado"
  value       = var.enable_nat ? aws_nat_gateway.this[0].public_ip : null
}
```

Retornar `null` é aceitável e sinaliza "não aplicável".

## Outputs de coleção com loops

```hcl
output "subnet_por_az" {
  value = { for s in aws_subnet.this : s.availability_zone => s.id }
}
```

Torna o consumo mais ergonômico: `module.rede.subnet_por_az["us-east-1a"]`.

## Mudança de outputs e quebra de dependentes

Alterar um output existente pode quebrar quem o consome:

- Em `terraform_remote_state`, o plan do consumidor falhará.
- Em módulos, o caller precisa acompanhar a versão.

Mitigações:

- **Adicione** outputs novos ao invés de renomear.
- **Deprecate** com mensagens no `description`.
- **Versionar módulos** (quando publicados).

## Padrões de output

### Expor só o essencial

Não exporte tudo — exponha o que os **consumidores** realmente usam. Excesso polui e gera dependências indesejadas.

### Agrupar em objetos

Ao invés de 10 outputs, um objeto:

```hcl
output "rede" {
  value = {
    vpc_id           = aws_vpc.main.id
    subnet_public    = aws_subnet.public[*].id
    subnet_private   = aws_subnet.private[*].id
    nat_gateway_ips  = aws_nat_gateway.this[*].public_ip
  }
}
```

Pró: uma importação só no consumidor.
Contra: se apenas uma parte muda, toda a estrutura "muda".

Adote o padrão que faz mais sentido para seu caso.

## Boas práticas

- Documente com `description`.
- Marque sensitive quando aplicável.
- Exponha pouco — "menos é mais".
- Evite outputs computados complexos — deixe a lógica em `locals`.
- Em módulos publicados, evite **breaking changes** em outputs.

Próximo tópico: **workspaces**.
