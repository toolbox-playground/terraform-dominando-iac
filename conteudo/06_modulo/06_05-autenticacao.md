# 06_05 - Autenticação e Credenciais

Providers precisam **se autenticar** contra APIs externas. Como isso é feito muda tudo: segurança, produtividade, rotinas de rotação. Este tópico cobre as formas mais comuns.

## Princípio: nunca hardcode credenciais

**NUNCA**:

```hcl
provider "aws" {
  access_key = "AKIA..."       # Não faça isso
  secret_key = "xYz123..."     # Nem isso
}
```

Isso vai parar no Git, nos logs e no state. Use as alternativas abaixo.

## AWS

### 1. Variáveis de ambiente (dev local)

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."    # se usando MFA/role assumida
export AWS_REGION="us-east-1"
```

O provider lê automaticamente.

### 2. Perfis em `~/.aws/credentials` (dev local)

```ini
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

[empresa-dev]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
```

Uso:

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "empresa-dev"
}
```

Ou exporte `AWS_PROFILE=empresa-dev` e omita `profile` no HCL.

### 3. AWS SSO / IAM Identity Center (dev corporativo)

```bash
aws sso login --profile empresa-dev
```

Usa credenciais temporárias rotacionadas.

### 4. IAM Instance Profile / Instance Role (em EC2)

Ao rodar Terraform dentro de uma EC2/ECS/EKS, o provider lê credenciais da **IMDS** (Instance Metadata Service). Não precisa configurar nada.

### 5. Assume Role (multi-conta, CI)

```hcl
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/terraform"
    session_name = "terraform-ci"
    external_id  = "my-external-id"
  }
}
```

A identidade **base** (user/role) precisa ter permissão `sts:AssumeRole` para a role alvo. A role alvo tem uma **trust policy** apontando para a base.

### 6. OIDC (GitHub Actions / GitLab CI, recomendado)

Sem credenciais estáticas; o job obtém token OIDC e o troca por credenciais temporárias via `AssumeRoleWithWebIdentity`.

GitHub Actions:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/terraform
    aws-region: us-east-1
```

Com isso, `terraform apply` passa a ter as credenciais. Sem segredo armazenado no repo.

## Google Cloud

### 1. `gcloud` ADC (dev local)

```bash
gcloud auth application-default login
```

O provider lê `~/.config/gcloud/application_default_credentials.json`.

### 2. Service Account Key (dev/CI antigo — evitar)

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/sa-key.json
```

Chaves de SA são credenciais longas em arquivo — prefira **Workload Identity Federation**.

### 3. Workload Identity Federation (CI moderno, recomendado)

GitLab/GitHub → GCP sem chave, via OIDC. Requer configurar um **Workload Identity Pool** no GCP.

### 4. Dentro do GCE/Cloud Run

Usa a service account anexada automaticamente. Sem config.

## Azure

### 1. Azure CLI (dev local)

```bash
az login
```

Provider `azurerm` usa o contexto atual.

### 2. Service Principal

```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

### 3. Managed Identity (em VMs Azure)

```hcl
provider "azurerm" {
  features {}
  use_msi = true
}
```

### 4. OIDC (GitHub/GitLab, recomendado)

Suporte nativo no `azurerm` — configure no pipeline.

## Kubernetes

```hcl
provider "kubernetes" {
  config_path    = "~/.kube/config"     # dev local
  config_context = "minikube"
}
```

Ou autenticação dinâmica (EKS, AKS, GKE):

```hcl
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.name]
  }
}
```

## Outras integrações comuns

| Provider | Forma típica |
|----------|-------------|
| `cloudflare` | `CLOUDFLARE_API_TOKEN` (env) |
| `datadog` | `DD_API_KEY`, `DD_APP_KEY` (env) |
| `github` | `GITHUB_TOKEN` (env) ou app OIDC |
| `gitlab` | `GITLAB_TOKEN` (env) |
| `vault` | `VAULT_ADDR`, `VAULT_TOKEN` (env), ou auth methods |

Sempre consulte a doc oficial do provider.

## Dicas transversais

1. **Secrets em variáveis de ambiente**: OK para CI. Em dev, prefira tokens temporários (`aws sso login`, `gcloud`).
2. **Menor privilégio**: a role/SA que roda Terraform deve ter **apenas** o que precisa.
3. **Nunca commite**: `.env`, `terraform.tfvars` com segredos, `credentials.json`.
4. **`.gitignore`** deve bloquear esses arquivos.
5. **Rotação**: credenciais estáticas precisam ser rotacionadas periodicamente.
6. **Auditoria**: use CloudTrail/Audit Logs/GitHub audit para rastrear quem aplicou o quê.
7. **State tem secrets**: backends com encryption at rest e lock são obrigatórios em prod (Módulo 7).

## Checklist para novo ambiente

- [ ] Credenciais não estão no código.
- [ ] Variáveis sensíveis estão em `TF_VAR_*` ou em Vault/SSM/Secret Manager.
- [ ] CI usa OIDC quando possível (GitHub/GitLab ↔ AWS/GCP/Azure).
- [ ] Roles/SAs têm políticas mínimas.
- [ ] `.gitignore` bloqueia `*.tfvars` sensíveis e diretórios com credenciais.
- [ ] Docs internas explicam como dev inicia sessão local.

No próximo tópico: **Terraform Registry — como navegar, versionar, consumir**.
