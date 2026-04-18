# 11_06 - OIDC e credenciais efêmeras

O padrão antigo é guardar `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` como secrets no GitLab. O padrão moderno é **OIDC** — o GitLab emite um token JWT assinado, a cloud aceita esse token via identity federation, e retorna credenciais **temporárias** (1h) para o pipeline.

Vantagens:

- **Zero secrets estáticos** no GitLab.
- **Credenciais expiram** naturalmente.
- **Auditável**: cada credencial é atrelada a um job específico.
- **Condicional**: role pode restringir qual branch, projeto, ambiente pode assumir.

Este tópico cobre AWS (o mais pedido); GCP e Azure seguem lógica similar.

## Conceito

```
┌──────────────┐                          ┌──────────────┐
│   GitLab     │──── JWT com claims ──────▶│   AWS STS    │
│   pipeline   │   (sub, aud, etc.)       │  (IAM OIDC)  │
└──────────────┘                          └──────┬───────┘
                                                 │
                                          valida assinatura
                                          valida trust policy
                                                 │
                                                 ▼
                                          credenciais temporárias
                                          (AK, SK, token)
```

## AWS — Setup

### 1. Criar Identity Provider

Uma única vez por conta AWS.

```hcl
resource "aws_iam_openid_connect_provider" "gitlab" {
  url = "https://gitlab.com"

  client_id_list = ["https://gitlab.com"]

  thumbprint_list = [
    "73a0146ef5d63e77a3fa7dccc8cdde15b02bae5a"  # verifique o atual
  ]
}
```

> O thumbprint pode ser obtido com:
> ```bash
> openssl s_client -servername gitlab.com -showcerts -connect gitlab.com:443 </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | cut -d= -f2 | tr -d :
> ```

Para self-hosted, substitua a URL pelo domínio do seu GitLab.

### 2. Criar IAM Role

Trust policy: "aceito tokens do GitLab para projeto X em branch Y":

```hcl
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "gitlab.com:aud"
      values   = ["https://gitlab.com"]
    }

    condition {
      test     = "StringLike"
      variable = "gitlab.com:sub"
      values = [
        "project_path:grupo/infra-prod:ref_type:branch:ref:main",
        "project_path:grupo/infra-prod:ref_type:tag:ref:v*",
      ]
    }
  }
}

resource "aws_iam_role" "gitlab_ci" {
  name               = "gitlab-ci-terraform"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.gitlab_ci.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"  # ajuste escopo!
}
```

Condições chave:

- `aud` — deve bater com a URL do GitLab.
- `sub` — formato: `project_path:GRUPO/PROJETO:ref_type:TIPO:ref:VALOR`.

### 3. Configurar GitLab: `id_tokens`

No `.gitlab-ci.yml`:

```yaml
.aws_oidc:
  id_tokens:
    AWS_ID_TOKEN:
      aud: https://gitlab.com
  before_script:
    - apk add --no-cache aws-cli jq
    - |
      CREDS=$(aws sts assume-role-with-web-identity \
        --role-arn $AWS_ROLE_ARN \
        --role-session-name GitLabCI-${CI_JOB_ID} \
        --web-identity-token $AWS_ID_TOKEN \
        --duration-seconds 3600)
      export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r .Credentials.AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .Credentials.SecretAccessKey)
      export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r .Credentials.SessionToken)
    - aws sts get-caller-identity
```

`AWS_ROLE_ARN` é uma variável não-sensível (pode ser plaintext no `.gitlab-ci.yml`):

```yaml
variables:
  AWS_ROLE_ARN: arn:aws:iam::123456789012:role/gitlab-ci-terraform
```

Ou definida em **Settings → CI/CD → Variables**.

### 4. Usar no plan/apply

```yaml
plan:
  extends: .aws_oidc
  stage: plan
  script:
    - *init
    - terraform plan -out=tfplan

apply:
  extends: .aws_oidc
  stage: apply
  script:
    - *init
    - terraform apply tfplan
```

Cada job renova credenciais. Se o job durar > 1h, precisa re-assumir antes de expirar.

## AWS — Setup via console (alternativa)

1. IAM → Identity providers → Add provider
   - Type: OpenID Connect
   - Provider URL: `https://gitlab.com`
   - Audience: `https://gitlab.com`
2. Create Role → Web identity
   - Provider: o criado acima
   - Audience: `https://gitlab.com`
   - Add condition: `gitlab.com:sub` = `project_path:GRUPO/PROJETO:ref_type:branch:ref:main`
3. Attach policy (princípio do menor privilégio).
4. Copie o ARN → use em `AWS_ROLE_ARN`.

## GCP — Setup

GCP aceita Workload Identity Federation.

```hcl
resource "google_iam_workload_identity_pool" "gitlab" {
  workload_identity_pool_id = "gitlab-pool"
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab.workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-provider"

  oidc {
    issuer_uri = "https://gitlab.com"
  }

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.project_path"     = "assertion.project_path"
    "attribute.namespace_id"     = "assertion.namespace_id"
    "attribute.user_login"       = "assertion.user_login"
    "attribute.ref"              = "assertion.ref"
  }

  attribute_condition = "assertion.project_path == 'grupo/infra'"
}
```

Bind a service account:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform@PROJECT.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/.../locations/global/workloadIdentityPools/gitlab-pool/*"
```

No pipeline:

```yaml
.gcp_oidc:
  id_tokens:
    GCP_ID_TOKEN:
      aud: //iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab-provider
  before_script:
    - echo $GCP_ID_TOKEN > /tmp/gcp-id-token
    - |
      gcloud iam workload-identity-pools create-cred-config \
        projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab-provider \
        --service-account=terraform@PROJECT.iam.gserviceaccount.com \
        --credential-source-file=/tmp/gcp-id-token \
        --output-file=/tmp/gcp-credentials.json
    - export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-credentials.json
```

## Azure — Setup

Azure também suporta federated identity credentials para apps registrados.

Passos resumidos:

1. Criar **App Registration** no Entra ID.
2. Criar **Service Principal**.
3. Adicionar **Federated Credential** com:
   - Issuer: `https://gitlab.com`
   - Subject: `project_path:grupo/infra:ref_type:branch:ref:main`
   - Audience: `api://AzureADTokenExchange`

Pipeline:

```yaml
.azure_oidc:
  id_tokens:
    AZURE_ID_TOKEN:
      aud: api://AzureADTokenExchange
  before_script:
    - az login --service-principal \
        --tenant $AZURE_TENANT_ID \
        --username $AZURE_CLIENT_ID \
        --federated-token $AZURE_ID_TOKEN
```

Para Terraform AzureRM:

```yaml
variables:
  ARM_USE_OIDC: "true"
  ARM_CLIENT_ID: ${AZURE_CLIENT_ID}
  ARM_TENANT_ID: ${AZURE_TENANT_ID}
  ARM_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}
  ARM_OIDC_TOKEN: ${AZURE_ID_TOKEN}
```

O provider AzureRM detecta e faz a federação sozinho.

## Princípio do menor privilégio

Role OIDC **não deve** ser admin. Conceda só o necessário:

- **Foundation pipeline**: rede, IAM, KMS.
- **Platform pipeline**: EKS, RDS, SG.
- **App pipeline**: ECS/EKS deploy, S3, Lambda.

Separe roles por pipeline/ambiente/stack.

## Condições avançadas de trust

```hcl
condition {
  test     = "StringLike"
  variable = "gitlab.com:sub"
  values = [
    "project_path:grupo/infra-prod:ref_type:branch:ref:main",
  ]
}

# Só em branches protegidas
condition {
  test     = "StringEquals"
  variable = "gitlab.com:ref_protected"
  values   = ["true"]
}

# Só se pipeline é de environment específico
condition {
  test     = "StringEquals"
  variable = "gitlab.com:environment"
  values   = ["prod"]
}
```

Claims disponíveis no JWT: [docs](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html).

## Pitfalls

### 1. Ausência de `id_tokens`

Esqueceu o bloco `id_tokens`? O JWT não é emitido; STS retorna erro de token inválido.

### 2. `aud` errado

AWS exige `aud = https://gitlab.com` (ou o que você configurou no IdP). Qualquer divergência = fail.

### 3. `sub` condicional

`project_path:...:ref_type:branch:ref:main` — qualquer espaço/erro na sequência vira fail silencioso (forbidden).

### 4. Thumbprint desatualizado

Se o GitLab rotacionar certificado, o thumbprint pode mudar. Atualize o Identity Provider.

### 5. Token válido mas role sem policy

Assumir funciona, mas Terraform falha em `plan` por falta de permissão. Verifique `aws sts get-caller-identity` e as policies anexadas.

## Resumo

OIDC elimina secrets estáticos, reforça auditoria e reduz blast radius. Use-o sempre que possível — especialmente em pipelines de produção.

Próximo: **pipeline com apply, environments e approvals**.
