# 11_02 - Conceitos de GitLab CI/CD

Antes de escrever pipelines de Terraform, revise a mecânica do GitLab CI/CD. Se já domina, pode pular direto para o próximo tópico.

## `.gitlab-ci.yml`

Arquivo na raiz do repo que define o pipeline. É YAML.

```yaml
stages:
  - validate
  - plan
  - apply

validate:
  stage: validate
  image: hashicorp/terraform:1.9
  script:
    - terraform fmt -check -recursive
    - terraform init -backend=false
    - terraform validate
```

## Estrutura mínima

```yaml
# 1. Versões globais
default:
  image: hashicorp/terraform:1.9

# 2. Estágios
stages:
  - validate
  - plan
  - apply

# 3. Variáveis compartilhadas
variables:
  TF_ROOT: ${CI_PROJECT_DIR}

# 4. Jobs
validate:
  stage: validate
  script:
    - echo "validando..."
```

## Jobs

Cada job é executado em um **container limpo** (por padrão). Mínimo necessário:

```yaml
nome_do_job:
  stage: plan               # stage a que pertence
  image: hashicorp/terraform:1.9
  script:
    - terraform init
    - terraform plan
```

### Atributos úteis

| Atributo | Função |
|----------|--------|
| `image` | Imagem Docker usada |
| `stage` | Stage do job |
| `script` | Comandos (array) |
| `before_script` | Roda antes de `script` |
| `after_script` | Roda depois (mesmo em falha) |
| `variables` | Variáveis do job |
| `needs` | Dependência de outros jobs (DAG) |
| `rules` | Condições que disparam o job |
| `only` / `except` | (Legado, prefira `rules`) |
| `artifacts` | Arquivos a preservar |
| `cache` | Cache entre pipelines |
| `environment` | Ambiente GitLab |
| `when` | `on_success`, `manual`, `always`, `never` |
| `allow_failure` | Permite o pipeline continuar se falhar |
| `timeout` | Timeout do job |
| `tags` | Seletor de runner |

## `rules` vs `only`/`except`

`rules` é o padrão moderno:

```yaml
job:
  rules:
    # Só em Merge Requests
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    # Em push para main
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    # Em tags vX.Y.Z
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
    # Manualmente (nunca automático)
    - when: manual
```

Múltiplas regras = **OR**. A primeira que bate define o comportamento.

## Variáveis predefinidas do GitLab

Disponíveis em todo job:

| Variável | Descrição |
|----------|-----------|
| `CI_COMMIT_BRANCH` | Branch atual (push) |
| `CI_COMMIT_TAG` | Tag atual (se tag push) |
| `CI_COMMIT_SHA` | SHA completo |
| `CI_COMMIT_SHORT_SHA` | SHA curto |
| `CI_PIPELINE_SOURCE` | `push`, `merge_request_event`, `schedule`… |
| `CI_PROJECT_DIR` | Pasta de checkout |
| `CI_PROJECT_ID` | ID numérico |
| `CI_PROJECT_PATH` | `grupo/projeto` |
| `CI_DEFAULT_BRANCH` | Geralmente `main` |
| `CI_JOB_ID` | ID do job |
| `CI_JOB_TOKEN` | Token efêmero p/ acessar API |
| `CI_SERVER_URL` | URL do GitLab |
| `CI_API_V4_URL` | URL da API REST |
| `CI_REGISTRY` / `CI_REGISTRY_USER` / `CI_REGISTRY_PASSWORD` | Docker Registry do GitLab |

## Variáveis definidas pelo usuário

Em **Settings → CI/CD → Variables**:

- **Scope**: Project / Group / Instance.
- **Type**: Variable (string) ou File (conteúdo escrito em arquivo temporário).
- **Environment**: opcional, limita a ambiente específico (`prod`).
- **Protected**: só disponível em branches/tags protegidas.
- **Masked**: oculta em logs.

Nomes convencionais:

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (se usar chaves; prefira OIDC).
- `AWS_ROLE_ARN` (OIDC).
- `TF_VAR_*` (passam direto para Terraform como input variables).
- Secrets: tokens, credenciais.

Uso:

```yaml
job:
  script:
    - echo "AWS role: $AWS_ROLE_ARN"
    - terraform apply -var="db_password=$TF_VAR_db_password"
```

## Artifacts

Arquivos gerados em um job, passados ao próximo:

```yaml
plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan
      - .terraform.lock.hcl
    expire_in: 1 week

apply:
  stage: apply
  script:
    - terraform apply tfplan
  needs:
    - plan
```

Sem artifacts, cada job começa do zero (não enxerga arquivos dos anteriores — exceto os do repo Git).

## Cache

Evita reinstalar coisas:

```yaml
default:
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .terraform/providers/
```

Cache é **otimização**. Artifact é **necessário** para dados entre stages.

## `needs` (DAG)

Por padrão, um job só roda quando **todos** os do stage anterior terminam. Com `needs`, você pode criar DAG:

```yaml
plan_dev:
  stage: plan
  # ...

plan_hml:
  stage: plan
  # ...

apply_dev:
  stage: apply
  needs: [plan_dev]        # apply_dev só precisa de plan_dev

apply_hml:
  stage: apply
  needs: [plan_hml]
```

## Environments

Registre ambientes no GitLab para tracking + approvals:

```yaml
apply_prod:
  stage: apply
  script: terraform apply
  environment:
    name: prod
    url: https://minhaapp.com
  when: manual
  only:
    - main
```

O GitLab rastreia: último deploy, quem deployou, status.

## Protected branches / tags

Em **Settings → Repository → Protected branches**:

- `main` só aceita push via MR.
- Só pode ser sido mergeada por `maintainers`.
- Variáveis `protected = true` só entram em pipelines de branches protegidas.

Em **Settings → Repository → Protected tags**:

- `v*` só pode ser criada por `maintainers`.

Isso previne que um atacante com acesso a dev branch consiga fazer deploy em prod.

## `extends` — reuso

```yaml
.tf_base:
  image: hashicorp/terraform:1.9
  before_script:
    - cd ${TF_ROOT}
    - terraform init

plan:
  extends: .tf_base
  stage: plan
  script:
    - terraform plan
```

Templates iniciados com `.` não rodam como job, só servem como base.

## `include`

Importar outros YAMLs:

```yaml
include:
  - local: '/ci/terraform.yml'
  - project: 'infra/ci-templates'
    file: 'terraform-lib.yml'
    ref: v1.0.0
  - template: 'Terraform/Base.latest.gitlab-ci.yml'
```

Permite DRY cross-projects.

## Runners

- **Shared runners** (gitlab.com): prontos, Docker executor, custo em compute minutes.
- **Group / Project runners**: instale num servidor/K8s/VM próprio.
- **Tags**: indique qual runner usar:

  ```yaml
  job:
    tags: [aws, large]
  ```

## Pipelines de MR

Tipos:

- **Branch pipeline**: push em branch.
- **Merge Request pipeline**: pipeline especial que vê o resultado do merge com o target.
- **Tag pipeline**: dispara em `git push --tags`.
- **Scheduled pipeline**: cron (ótimo pra `plan` diário de drift detection).

## Debug básico

```yaml
job:
  script:
    - env | sort
    - set -x  # bash verbose
    - pwd && ls -la
```

Ou rode local com `gitlab-runner exec docker nome_do_job`.

## Resumo

- `.gitlab-ci.yml` define stages, jobs, rules.
- Jobs rodam em containers isolados — use `artifacts` para passar arquivos.
- `rules` controla quando cada job dispara.
- Variáveis são a interface para secrets e configs.
- Protected branches/tags protegem deploys em prod.

Próximo: **primeiro pipeline Terraform (fmt + validate)**.
