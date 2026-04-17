# 06_03 - Configurando o bloco `provider`

Enquanto `required_providers` declara **qual** provider usar, o bloco `provider` configura **como** ele se comporta (região, credenciais, endpoints, retries, tags padrão, etc.).

## Forma básica

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Cada provider tem sua própria lista de argumentos. Consulte o Registry para ver todos.

## Argumentos comuns

Alguns padrões que se repetem entre providers:

| Argumento | Providers comuns | Finalidade |
|-----------|------------------|------------|
| `region` | aws, google, etc. | Região padrão das APIs |
| `project` | google | ID do projeto GCP |
| `subscription_id` / `tenant_id` | azurerm | Assinatura Azure |
| `alias` | todos | Nomear instâncias múltiplas |
| `default_tags` | aws, azurerm | Tags aplicadas a todos os recursos |
| `skip_metadata_api_check` | aws | Ignora IMDS em dev |
| `assume_role` / `assume_role_with_web_identity` | aws | Assume uma IAM Role |
| `host`, `token`, `insecure` | kubernetes | Conexão ao cluster |

## Defaults e "provider configuration inheritance"

Se você **não** declara um bloco `provider "X"`, o Terraform tenta configurá-lo com defaults (lidos de variáveis de ambiente, arquivos de credencial, perfis, metadata service).

Ou seja, o código abaixo **funciona** sem `provider "aws" { ... }` se `AWS_REGION` e credenciais estão no ambiente:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "logs-2026"
}
```

Isso é conveniente, mas torna implícito o que é **melhor explícito** em projetos sérios.

## `default_tags` (AWS)

Aplica tags a **todos** os recursos que suportam tags:

```hcl
provider "aws" {
  region = var.regiao

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Projeto     = var.projeto
      Ambiente    = var.ambiente
      CostCenter  = var.cost_center
    }
  }
}
```

Ganhos:

- Garante tagging consistente.
- Reduz código em cada resource.
- Pode ser combinado com tags locais (mesclagem).

Analogia no `azurerm`: bloco `features {}` + tags por resource group. No Google: `labels` devem ser definidas por resource.

## `assume_role` (AWS)

Forma idiomática de rodar Terraform usando role ao invés de credenciais estáticas:

```hcl
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/terraform"
    session_name = "terraform-${terraform.workspace}"
    external_id  = "my-external-id"
  }
}
```

Cenários:

- **Multi-conta**: uma role por conta, com confiança mútua.
- **CI/CD**: role com confiança no OIDC do provider (GitLab/GitHub Actions).
- **Cross-region**: mesma role, múltiplos `provider` com aliases.

## `provider` com endpoints customizados

Útil para:

- Testes com **LocalStack** (AWS emulado).
- **Minio** compatível com S3.
- Ambientes corporativos atrás de proxy/PrivateLink.

```hcl
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}
```

## Dynamic values NO bloco `provider`

Restrições importantes:

- **Não pode** depender de recursos (`aws_instance.x.id`) — é resolvido no tempo de plan/init.
- **Pode** usar `var.*`, `local.*`, `data.*` (data sources cuidadosos).
- **Não pode** usar `count` ou `for_each` (exceto via aliases manuais).

```hcl
# OK
provider "aws" {
  region = var.regiao
}

# NÃO OK (depende de recurso)
provider "aws" {
  region = aws_vpc.main.region_tag  # erro
}
```

## Ordem das configurações

Credenciais e configurações vêm de (maior → menor prioridade):

1. Argumentos do bloco `provider`.
2. Variáveis de ambiente (`AWS_REGION`, `GOOGLE_PROJECT`, etc.).
3. Arquivos de credencial no disco (`~/.aws/credentials`, `~/.config/gcloud/`).
4. Metadata service (IMDS, GCE metadata).

Conheça essa ordem para evitar surpresas ("por que tá indo em outra região?").

## Configurações em módulos reutilizáveis

Dentro de módulos **publicados**, evite bloco `provider` — deixe o caller configurar. Um módulo que declara `provider` trava sua configuração e quebra workspaces multi-conta.

```hcl
# módulo - apenas declara required_providers
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
# nada de provider { ... } aqui
```

## Exemplos por provider

### Google Cloud

```hcl
provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}
```

### Azure

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

### Kubernetes

```hcl
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}
```

### Providers utilitários (sem config)

```hcl
provider "random" {}
provider "null" {}
provider "local" {}
```

## Boas práticas

- **Seja explícito**: declare `provider` mesmo quando defaults bastariam.
- **Use `default_tags`** em AWS/Azure.
- **Evite credenciais hardcoded** — use `assume_role`, OIDC, variáveis de ambiente.
- **Em módulos reutilizáveis**, não configure providers; deixe o caller fazê-lo.
- **Comente** argumentos menos óbvios (`skip_credentials_validation`, etc.).

No próximo tópico: **aliases** para múltiplas instâncias de um mesmo provider (multi-região, multi-conta).
