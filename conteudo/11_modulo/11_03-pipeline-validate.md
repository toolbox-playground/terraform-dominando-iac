# 11_03 - Primeiro pipeline: validação

Vamos criar o pipeline **mais simples possível** que roda `terraform fmt` e `terraform validate`. Esse é o piso de qualidade que todo projeto deve ter.

## Estrutura do projeto

```
meu-infra/
├── .gitlab-ci.yml
├── main.tf
├── variables.tf
├── versions.tf
└── outputs.tf
```

## `.gitlab-ci.yml` mínimo

```yaml
stages:
  - validate

default:
  image: hashicorp/terraform:1.9

fmt:
  stage: validate
  script:
    - terraform fmt -check -recursive

validate:
  stage: validate
  script:
    - terraform init -backend=false
    - terraform validate
```

Pontos importantes:

- **`terraform fmt -check`**: falha se algo estiver mal formatado. Corrija com `terraform fmt -recursive` localmente.
- **`-recursive`**: desce em submódulos.
- **`terraform init -backend=false`**: evita precisar de credenciais de state só para validar.

## Commit e teste

```bash
git add .gitlab-ci.yml
git commit -m "ci: add fmt and validate"
git push
```

Abra **CI/CD → Pipelines** no GitLab. Ambos os jobs devem rodar.

## Melhorando: `tflint`

[tflint](https://github.com/terraform-linters/tflint) detecta problemas que o `validate` não vê:

- Argumentos deprecated.
- AMIs inexistentes.
- Tipos de instância inválidos.
- Problemas de sintaxe provider-specific.

```yaml
tflint:
  stage: validate
  image: ghcr.io/terraform-linters/tflint:latest
  script:
    - tflint --init
    - tflint --recursive
```

Se você usa AWS, adicione um `.tflint.hcl`:

```hcl
# .tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

## Melhorando: `checkov`

[checkov](https://www.checkov.io/) faz análise de segurança estática:

- S3 buckets sem encryption.
- Security groups abertos 0.0.0.0/0 em portas críticas.
- IAM policies permissivas demais.
- RDS sem backup.
- Centenas de outros checks por provider.

```yaml
checkov:
  stage: validate
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script:
    - checkov --directory . --framework terraform --quiet --compact
  allow_failure: false
```

### Ignorando checks específicos

```hcl
resource "aws_s3_bucket" "legacy" {
  bucket = "old-bucket"
  # checkov:skip=CKV_AWS_18:Logging não aplicável neste caso
}
```

## Melhorando: `terraform-docs` lint

Forçar que o README esteja sempre em sync:

```yaml
docs_lint:
  stage: validate
  image: quay.io/terraform-docs/terraform-docs:0.17.0
  script:
    - terraform-docs markdown table --output-mode inject --output-file README.md .
    - git diff --exit-code README.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

O `git diff --exit-code` falha se houve mudança no README — forçando o autor a regenerar.

## Pipeline consolidado

```yaml
stages:
  - validate

default:
  image: hashicorp/terraform:1.9

fmt:
  stage: validate
  script:
    - terraform fmt -check -recursive

validate:
  stage: validate
  script:
    - terraform init -backend=false
    - terraform validate

tflint:
  stage: validate
  image: ghcr.io/terraform-linters/tflint:latest
  script:
    - tflint --init
    - tflint --recursive

checkov:
  stage: validate
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script:
    - checkov --directory . --framework terraform --quiet --compact
```

Todos os 4 rodam em paralelo (mesmo stage, sem `needs`).

## Regras: só em MR?

Para não gastar minutos em commits direto na main:

```yaml
default:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Isso dispara em MR e em push para `main`.

Alternativa: só em MR:

```yaml
validate:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Resultado esperado

Ao abrir um MR, você deve ver algo assim:

```
Pipeline #12345 passed in 1 minute 30 seconds
 ✓ fmt
 ✓ validate
 ✓ tflint
 ✓ checkov
```

Se algum falhar, o MR **não** pode ser mergeado (configure isso em **Settings → Merge requests → Pipelines must succeed**).

## Ambiente local vs. CI

Para ter o mesmo comportamento localmente, crie um `Makefile`:

```makefile
.PHONY: fmt validate lint security

fmt:
	terraform fmt -recursive

check-fmt:
	terraform fmt -check -recursive

validate:
	terraform init -backend=false
	terraform validate

lint:
	tflint --init
	tflint --recursive

security:
	checkov --directory . --framework terraform --quiet --compact

pre-commit: check-fmt validate lint security
```

Rodar `make pre-commit` antes de abrir MR evita piplines falhos.

## Pre-commit (opcional)

[pre-commit](https://pre-commit.com/) automatiza checks no `git commit`:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_checkov
```

```bash
pre-commit install
```

## Resumo

O pipeline mínimo já é útil:

- `fmt` → estilo.
- `validate` → sintaxe.
- `tflint` → erros específicos.
- `checkov` → segurança.

Com esses 4 jobs, você já filtra 80% dos problemas antes deles chegarem ao `plan`. Próximo tópico: **como gerar e revisar o `plan` em MR**.
