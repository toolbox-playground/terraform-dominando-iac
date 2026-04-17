# 11_04 - State remoto no GitLab (HTTP Backend)

O GitLab oferece um **HTTP backend nativo** para armazenar state do Terraform. Não precisa de S3 nem de Terraform Cloud — o próprio GitLab cuida de:

- Armazenamento.
- Locking (pessimistic, com POST/DELETE de locks).
- Versionamento.
- Controle de acesso via tokens.

Perfeito para labs, projetos pequenos/médios e demonstrações didáticas.

## Pré-requisitos

- GitLab 13.0+ (o gitlab.com funciona direto).
- Projeto com a feature **Infrastructure → Terraform states** habilitada (padrão).

## Configuração

### 1. URL do backend

```
https://<GITLAB>/api/v4/projects/<PROJECT_ID>/terraform/state/<STATE_NAME>
```

- `<GITLAB>`: `gitlab.com` ou seu self-hosted.
- `<PROJECT_ID>`: ID numérico do projeto (mostrado em **Settings → General**).
- `<STATE_NAME>`: nome livre (`prod`, `dev`, `rede`, `eks`…). Um projeto pode ter **vários** states.

### 2. Bloco `terraform`

```hcl
terraform {
  backend "http" {}
}
```

Os valores **não** são hardcoded: são passados via `terraform init -backend-config=...`.

### 3. Inicialização local

Gere um **Personal Access Token** (PAT) com escopo `api`:

```bash
GITLAB_USER=seu.usuario
GITLAB_TOKEN=glpat-xxxxx
PROJECT_ID=12345678
STATE_NAME=dev

TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/${STATE_NAME}"

terraform init \
  -backend-config="address=${TF_ADDRESS}" \
  -backend-config="lock_address=${TF_ADDRESS}/lock" \
  -backend-config="unlock_address=${TF_ADDRESS}/lock" \
  -backend-config="username=${GITLAB_USER}" \
  -backend-config="password=${GITLAB_TOKEN}" \
  -backend-config="lock_method=POST" \
  -backend-config="unlock_method=DELETE" \
  -backend-config="retry_wait_min=5"
```

Depois é `terraform plan/apply` normal.

### 4. Inicialização em CI

No pipeline, use `CI_JOB_TOKEN` — criado automaticamente com permissão no próprio projeto:

```yaml
variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: dev
  TF_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"

.init_terraform: &init_terraform |
  terraform -chdir=${TF_ROOT} init \
    -backend-config="address=${TF_ADDRESS}" \
    -backend-config="lock_address=${TF_ADDRESS}/lock" \
    -backend-config="unlock_address=${TF_ADDRESS}/lock" \
    -backend-config="username=gitlab-ci-token" \
    -backend-config="password=${CI_JOB_TOKEN}" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"

plan:
  stage: plan
  script:
    - *init_terraform
    - terraform -chdir=${TF_ROOT} plan -out=tfplan
  artifacts:
    paths: [${TF_ROOT}/tfplan]
```

## Usando o template oficial

O GitLab publica templates prontos. Em `.gitlab-ci.yml`:

```yaml
include:
  - template: Terraform/Base.latest.gitlab-ci.yml

stages:
  - validate
  - test
  - build
  - deploy

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: default

fmt:
  extends: .terraform:fmt
validate:
  extends: .terraform:validate
build:
  extends: .terraform:build
deploy:
  extends: .terraform:deploy
```

Esse template já:

- Usa imagem correta.
- Inicializa backend.
- Publica artifacts.
- Cria job `deploy` **manual**.

Trade-off: você perde controle fino. Para cursos/projetos pequenos, é excelente.

## Múltiplos states (ambientes)

Para dev/hml/prod no mesmo repo, varie `TF_STATE_NAME`:

```yaml
plan_dev:
  variables:
    TF_STATE_NAME: dev
  # ...

plan_hml:
  variables:
    TF_STATE_NAME: hml
  # ...

plan_prod:
  variables:
    TF_STATE_NAME: prod
  # ...
```

Cada ambiente tem seu próprio state, locks separados, histórico próprio.

## Navegando os states

Em **Infrastructure → Terraform states**, o GitLab mostra:

- Lista de states.
- Última modificação.
- Quem/qual pipeline aplicou.
- Download do state (limitado a quem tem acesso).
- Botão **Remove** state (cuidado!).

## Segurança

### Controle de acesso

- Leitura do state = qualquer membro do projeto com permissão `Developer+`.
- Gravação = quem tem permissão de escrita.
- Tokens:
  - **`CI_JOB_TOKEN`**: limitado ao próprio projeto (ou projetos que concederam acesso).
  - **PAT**: amplo, use só para dev local.
  - **Project Access Token**: ideal para CI cross-projects.

### State ainda tem secrets

O state armazena valores mesmo de variáveis `sensitive`. O GitLab **não** criptografa em disco por padrão (depende do deployment).

Para produção rigorosa:

- Ative **GitLab Secrets** para criptografia adicional.
- Considere usar **Vault** ou **Secrets Manager** em vez de guardar secrets no state.
- Restrinja quem pode baixar o state.

## Lock: troubleshooting

Se um job falhou no meio e deixou o state lockado:

```bash
terraform force-unlock <LOCK_ID>
```

O `LOCK_ID` aparece na mensagem de erro. **Só use** quando tiver certeza que nada está rodando.

Na UI: **Infrastructure → Terraform states → (clicar no state) → Unlock**.

## Migração de S3 → GitLab

Já tem state no S3? É possível migrar.

1. Mude o bloco `backend` no código:

   ```hcl
   terraform {
     backend "http" {}
   }
   ```

2. Rode `init` com `-migrate-state`:

   ```bash
   terraform init -migrate-state \
     -backend-config=...
   ```

3. Responda `yes` na pergunta de cópia.
4. Valide com `terraform state list`.

## Limites

| Item | Limite (gitlab.com) |
|------|---------------------|
| Tamanho do state | Depende do plan; em self-hosted é ilimitado |
| Versões mantidas | Todas, por padrão |
| Retenção | Configurável |
| Lock concurrent | 1 por state (como qualquer backend decente) |

Para projetos com **centenas de Mb de state** (muito raro), prefira S3.

## Cuidados

- **Nunca** exponha o token no log (mascare nas variáveis).
- **Proteja** a branch `main` para evitar apply não autorizado.
- **Não versione** `.terraform/`, `.tfstate` local, nem `terraform.tfvars` com secrets.

## `.gitignore` recomendado

```
# Local .terraform directories
.terraform/
.terraform.lock.hcl   # (exceção: commit este para pin)

# .tfstate files (todo!)
*.tfstate
*.tfstate.*
*.tfstate.backup

# Crash logs
crash.log
crash.*.log

# tfvars com secrets
*.tfvars
!examples/*.tfvars
!*.tfvars.example

# Directories
.terragrunt-cache/
```

`terraform.lock.hcl` **deve** ser commitado — garante reproducibilidade.

## Resumo

- GitLab HTTP backend = zero infra extra + locking nativo.
- `CI_JOB_TOKEN` autentica o pipeline sem secrets permanentes.
- Múltiplos states por projeto permitem separar ambientes.
- Proteja branches e revise acessos.

Próximo: gerar **plan em MR** como parte do fluxo de revisão.
