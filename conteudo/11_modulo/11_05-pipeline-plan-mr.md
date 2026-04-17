# 11_05 - Plan em MR com revisão

Agora integramos state remoto + pipeline: toda abertura/atualização de MR gera um `plan` salvo como artifact e comentado no MR, permitindo revisão antes do merge.

## Objetivos

1. Em MR: rodar `fmt`, `validate`, `tflint`, `plan`.
2. Publicar o `plan` no MR.
3. Bloquear o merge se o pipeline falhar.
4. Após merge em `main`: abrir caminho para o `apply` (próximo tópico).

## Estrutura do pipeline

```yaml
stages:
  - validate
  - plan
```

## Setup reutilizável

```yaml
default:
  image:
    name: hashicorp/terraform:1.9
    entrypoint: [""]

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: dev
  TF_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"

.init: &init |
  cd "${TF_ROOT}"
  terraform --version
  terraform init \
    -backend-config="address=${TF_ADDRESS}" \
    -backend-config="lock_address=${TF_ADDRESS}/lock" \
    -backend-config="unlock_address=${TF_ADDRESS}/lock" \
    -backend-config="username=gitlab-ci-token" \
    -backend-config="password=${CI_JOB_TOKEN}" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"

.tf_rules: &tf_rules
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## Stage validate

```yaml
fmt:
  stage: validate
  <<: *tf_rules
  script:
    - terraform fmt -check -recursive

validate:
  stage: validate
  <<: *tf_rules
  script:
    - terraform init -backend=false
    - terraform validate

tflint:
  stage: validate
  image: ghcr.io/terraform-linters/tflint:latest
  <<: *tf_rules
  script:
    - tflint --init
    - tflint --recursive
```

## Stage plan

```yaml
plan:
  stage: plan
  <<: *tf_rules
  script:
    - *init
    - terraform plan -out=tfplan -no-color | tee plan.txt
    - terraform show -json tfplan > plan.json
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
      - ${TF_ROOT}/plan.txt
      - ${TF_ROOT}/plan.json
    expire_in: 1 week
    reports:
      # Integração nativa: GitLab mostra diff do plan na MR
      terraform: ${TF_ROOT}/plan.json
```

O campo `reports.terraform` é uma **feature do GitLab** — ele renderiza um widget na MR com contagem de `added / changed / destroyed`.

## Comentando o plan no MR

Para deixar o plan visível dentro da discussão (além do widget), use a API do GitLab:

```yaml
plan_comment:
  stage: plan
  needs: [plan]
  image: curlimages/curl:latest
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - |
      PLAN_TEXT=$(cat ${TF_ROOT}/plan.txt | head -c 60000)
      BODY=$(jq -Rs --arg plan "$PLAN_TEXT" '{body: ("### Terraform Plan\n```\n" + $plan + "\n```")}')
      curl --fail-with-body \
        --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_BOT_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "$BODY" \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes"
```

- `GITLAB_BOT_TOKEN`: Project Access Token com escopo `api`.
- O plan é truncado em 60 KB para caber no comentário.

Alternativamente, use ferramentas como [tfcomment](https://github.com/liamg/tfcomment) ou [Atlantis](https://www.runatlantis.io/) se quiser algo mais sofisticado.

## Bloqueando merge se pipeline falhar

Em **Settings → Merge requests → Merge checks**, marque:

- ✅ **Pipelines must succeed**
- ✅ **All threads must be resolved**

Agora MR com pipeline vermelho não merge.

## Multi-ambiente: plan por ambiente

```yaml
.plan_template:
  stage: plan
  <<: *tf_rules
  script:
    - *init
    - terraform plan -var-file="envs/${TF_ENV}.tfvars" -out=tfplan -no-color | tee plan.txt
    - terraform show -json tfplan > plan.json
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
      - ${TF_ROOT}/plan.txt
    reports:
      terraform: ${TF_ROOT}/plan.json

plan_dev:
  extends: .plan_template
  variables:
    TF_STATE_NAME: dev
    TF_ENV: dev

plan_hml:
  extends: .plan_template
  variables:
    TF_STATE_NAME: hml
    TF_ENV: hml

plan_prod:
  extends: .plan_template
  variables:
    TF_STATE_NAME: prod
    TF_ENV: prod
```

Três plans rodam em paralelo, cada um apontando para seu state. Ideal para revisão do impacto em cada ambiente.

## Autenticação na cloud

Para que o `plan` consiga consultar a API da AWS, o job precisa de credenciais. Três opções:

### Opção 1 — Chaves estáticas (evite)

```yaml
variables:
  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
  AWS_DEFAULT_REGION: us-east-1
```

Variáveis definidas como **Masked + Protected**. Funcional, mas inseguro.

### Opção 2 — Assume Role com chave intermediária

```yaml
.aws_assume:
  before_script:
    - apk add --no-cache aws-cli jq
    - |
      creds=$(aws sts assume-role \
        --role-arn "${AWS_ROLE_ARN}" \
        --role-session-name "tf-ci-${CI_PIPELINE_ID}")
      export AWS_ACCESS_KEY_ID=$(echo $creds | jq -r .Credentials.AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(echo $creds | jq -r .Credentials.SecretAccessKey)
      export AWS_SESSION_TOKEN=$(echo $creds | jq -r .Credentials.SessionToken)
```

Ainda depende de uma chave inicial — melhor, mas não ideal.

### Opção 3 — OIDC (recomendado)

Veremos em detalhe no próximo tópico. Mini-spoiler:

```yaml
id_tokens:
  AWS_ID_TOKEN:
    aud: https://gitlab.com

.aws_oidc:
  before_script:
    - >
      STS=$(aws sts assume-role-with-web-identity
              --role-arn $AWS_ROLE_ARN
              --role-session-name GitLabCI
              --web-identity-token $AWS_ID_TOKEN)
    - export AWS_ACCESS_KEY_ID=$(echo $STS | jq -r .Credentials.AccessKeyId)
    - export AWS_SECRET_ACCESS_KEY=$(echo $STS | jq -r .Credentials.SecretAccessKey)
    - export AWS_SESSION_TOKEN=$(echo $STS | jq -r .Credentials.SessionToken)
```

## `.gitlab-ci.yml` completo para MR + plan

```yaml
stages:
  - validate
  - plan

default:
  image:
    name: hashicorp/terraform:1.9
    entrypoint: [""]

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: dev
  TF_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"

.init: &init |
  cd "${TF_ROOT}"
  terraform init \
    -backend-config="address=${TF_ADDRESS}" \
    -backend-config="lock_address=${TF_ADDRESS}/lock" \
    -backend-config="unlock_address=${TF_ADDRESS}/lock" \
    -backend-config="username=gitlab-ci-token" \
    -backend-config="password=${CI_JOB_TOKEN}" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE"

.tf_rules: &tf_rules
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

fmt:
  stage: validate
  <<: *tf_rules
  script:
    - terraform fmt -check -recursive

validate:
  stage: validate
  <<: *tf_rules
  script:
    - terraform init -backend=false
    - terraform validate

tflint:
  stage: validate
  image: ghcr.io/terraform-linters/tflint:latest
  <<: *tf_rules
  script:
    - tflint --init && tflint --recursive

plan:
  stage: plan
  <<: *tf_rules
  script:
    - *init
    - terraform plan -out=tfplan -no-color | tee plan.txt
    - terraform show -json tfplan > plan.json
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
      - ${TF_ROOT}/plan.txt
    reports:
      terraform: ${TF_ROOT}/plan.json
    expire_in: 1 week
```

## Pitfalls

### 1. `plan` sem init

Esqueceu `init`? Erro: `Backend initialization required`.

### 2. Lock travado

Pipeline falhou após `plan`? Lock fica ativo. Use `force-unlock` (ou UI).

### 3. Plan defasado

Tempo entre MR e merge pode ser longo. Re-gere o plan no apply (não reuse o tfplan antigo).

### 4. `tfplan` gigante

Projetos grandes geram plans de 10+ MB. Ajuste `expire_in` ou comprima com `gzip`.

### 5. Permissões insuficientes

`CI_JOB_TOKEN` só acessa o próprio projeto. Para consumir módulos de outro projeto, configure em **Settings → CI/CD → Token Access**.

## Resumo

- MR = plan automático + validações.
- Artifact do tfplan permite passar para o `apply` depois.
- GitLab renderiza diff via `reports.terraform`.
- Bloqueio de merge força qualidade.

Próximo tópico: **OIDC para autenticar cloud sem chaves estáticas**.
