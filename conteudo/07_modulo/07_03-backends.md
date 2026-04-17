# 07_03 - Backends Remotos

Um **backend** define onde o Terraform armazena o state e como executa certas operações. Backends remotos são obrigatórios para trabalho em time, CI/CD e produção.

## Tipos suportados (resumo)

| Backend | Hospedagem | Locking nativo? | Quando usar |
|---------|------------|-----------------|-------------|
| `local` | Disco local | não | Estudo |
| `s3` | AWS S3 (+ DynamoDB para lock) | sim | Projetos AWS-centric |
| `gcs` | Google Cloud Storage | sim (objeto) | Projetos GCP |
| `azurerm` | Azure Storage | sim (lease blob) | Projetos Azure |
| `http` | API HTTP customizada | sim (se suportado) | GitLab Managed State, outros |
| `remote` (HCP Terraform) | Terraform Cloud | sim | Workflows Terraform Cloud |
| `consul` | HashiCorp Consul | sim | Ambiente com Consul existente |
| `kubernetes` | Secret no K8s | sim | Clusters Kubernetes dedicados |
| `pg` | PostgreSQL | sim | Times usando PG como "tudo" |

Para a maioria dos cenários: **`s3` + DynamoDB** (AWS), **`gcs`** (GCP), **`azurerm`** (Azure), ou **`http`** (GitLab).

## Configuração

Vai dentro do bloco `terraform`:

```hcl
terraform {
  backend "s3" {
    bucket         = "minha-empresa-tfstate"
    key            = "prod/rede/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Regras importantes**:

- Backend **não** aceita variáveis (`var.*`, `local.*`, etc.) — apenas strings literais.
- Parametrização só via arquivo de config (`-backend-config="bucket=..."`).
- Ao mudar o backend ou seus argumentos, rode `terraform init` novamente.

## Parametrização com `-backend-config`

Como backend não aceita variáveis, use arquivos separados:

`backend-prod.hcl`:

```hcl
bucket         = "minha-empresa-tfstate"
key            = "prod/rede/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-locks"
```

`backend-dev.hcl`:

```hcl
bucket         = "minha-empresa-tfstate"
key            = "dev/rede/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-locks"
```

E no código:

```hcl
terraform {
  backend "s3" {}   # vazio, parametrizado via CLI
}
```

Inicialização:

```bash
terraform init -backend-config=backend-prod.hcl
```

Isso permite **mesmo código, múltiplos states**.

## S3 + DynamoDB (AWS)

A receita clássica:

- **Bucket S3** armazena o state.
- **Tabela DynamoDB** garante o **lock** (só um `apply` por vez).

Provisionamento manual (uma vez):

```hcl
resource "aws_s3_bucket" "tfstate" {
  bucket = "minha-empresa-tfstate"
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

resource "aws_dynamodb_table" "locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

(Rode isso uma vez com state local, depois migre o próprio state para o bucket.)

Uso:

```hcl
terraform {
  backend "s3" {
    bucket         = "minha-empresa-tfstate"
    key            = "plataforma/rede/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## GCS

```hcl
terraform {
  backend "gcs" {
    bucket = "minha-empresa-tfstate"
    prefix = "plataforma/rede"
  }
}
```

Lock é garantido pelo GCS (via `x-goog-if-generation-match`).

Ative **object versioning** no bucket para rollback.

## Azure

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "prod/rede/terraform.tfstate"
  }
}
```

Lock por lease do blob. Ative versioning no storage account.

## HTTP (GitLab Managed State)

GitLab oferece state managed via API HTTP:

```hcl
terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/123/terraform/state/prod"
    lock_address   = "https://gitlab.com/api/v4/projects/123/terraform/state/prod/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/123/terraform/state/prod/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
```

Credenciais via env: `TF_HTTP_USERNAME=oauth2`, `TF_HTTP_PASSWORD=<token>`.

Detalhado no **Módulo 11 - GitLab CI/CD**.

## `remote` (HCP Terraform / Terraform Cloud)

```hcl
terraform {
  cloud {
    organization = "minha-empresa"

    workspaces {
      name = "plataforma-rede-prod"
    }
  }
}
```

Com isso você ganha: state, runs, políticas (Sentinel/OPA), UI web, private registry, VCS integration.

## Inicialização e mudança de backend

Sempre que o bloco `backend` muda:

```bash
terraform init
# ou para mover state existente
terraform init -migrate-state
# ou para começar limpo
terraform init -reconfigure
```

- **`-migrate-state`**: Terraform copia o state do backend antigo para o novo.
- **`-reconfigure`**: descarta config antiga, reinicializa do zero (sem copiar).

## Locking

Quando habilitado:

1. `apply` pega um lock no backend.
2. Se outro `apply` tentar, recebe erro `Error acquiring the state lock`.
3. Ao terminar, libera o lock.

Comandos úteis:

```bash
# Destrancar manualmente (após confirmar que nenhum apply está em andamento!)
terraform force-unlock LOCK_ID
```

**Cuidado**: usar `force-unlock` com apply ativo corrompe o state.

## Estratégias de organização

### Por ambiente (key paths)

Um bucket, múltiplas keys:

```
s3://minha-empresa-tfstate/
  ├── dev/
  │   ├── rede/terraform.tfstate
  │   └── app/terraform.tfstate
  ├── hml/
  │   ├── rede/terraform.tfstate
  │   └── app/terraform.tfstate
  └── prod/
      ├── rede/terraform.tfstate
      └── app/terraform.tfstate
```

Recomendado para projetos médios/grandes.

### Por projeto (buckets separados)

Um bucket por projeto/time. Aumenta isolamento, complica rotina.

### Workspaces (evitar em prod)

Um único state dividido em "workspaces". Bom para cenários simples; para produção séria, prefira paths explícitos.

## Segurança

- **Criptografia** obrigatória em repouso e em trânsito.
- **IAM/ACL**: apenas quem precisa pode ler/gravar.
- **Audit logging**: CloudTrail (S3), Audit Logs (GCS), etc.
- **Não exponha** credenciais de backend em logs.
- Use **KMS** ou equivalente para gerenciar chaves.

## Checklist ao criar um backend novo

- [ ] Bucket/container com versioning habilitado.
- [ ] Encryption em repouso (KMS se possível).
- [ ] Acesso restrito por IAM.
- [ ] Audit/log de acessos ligado.
- [ ] Lock configurado (DynamoDB, lease, etc.).
- [ ] Backup/retention configurado.
- [ ] Key path documentado.
- [ ] Fluxo de `init -backend-config` testado por dev e CI.

Próximo tópico: **detalhes do state locking**.
