# 11_07 - Apply, environments e approvals

Agora fechamos o ciclo: após `plan` revisado no MR e merge em `main`, o pipeline faz `apply` com approval humano e rastreia o deploy em GitLab Environments.

## Fluxo completo

```
MR aberta ─► validate + plan ──► review ──► merge
                                               │
                                               ▼
                                    main ─► validate + plan
                                               │
                                               ▼
                                    apply_dev (auto ou manual)
                                               │
                                               ▼
                                    apply_hml (manual, protected)
                                               │
                                               ▼
                                    apply_prod (manual, 2 approvals)
```

## Stage `apply`

```yaml
stages:
  - validate
  - plan
  - apply
```

## Job apply básico

```yaml
apply:
  stage: apply
  extends: .aws_oidc
  script:
    - *init
    - terraform apply -auto-approve tfplan
  dependencies: [plan]
  environment:
    name: dev
    url: https://console.aws.amazon.com/
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual        # mesmo em main, exige clique
  allow_failure: false
```

Destaques:

- `dependencies: [plan]` — reaproveita o `tfplan` gerado antes.
- `environment.name` — GitLab registra como deploy de ambiente.
- `when: manual` — requer acionamento humano.
- `rules` + `main` — nunca roda em MR.

## Por que `tfplan` entre stages?

```yaml
plan:
  stage: plan
  script:
    - *init
    - terraform plan -out=tfplan
  artifacts:
    paths: [tfplan, .terraform.lock.hcl]

apply:
  stage: apply
  script:
    - *init
    - terraform apply tfplan
  dependencies: [plan]
```

- O `tfplan` é **apenas aplicável** se a base não mudou.
- Se entre plan e apply alguém mudou outra coisa, `apply` falha — e isso é proteção.
- Evita "surpresa": o apply faz **exatamente** o que foi revisado.

Alternativa pragmática: re-rodar `plan + apply` juntos (sem reaproveitar tfplan). Mais simples, menos seguro.

## Environments múltiplos

```yaml
.apply_template:
  stage: apply
  extends: .aws_oidc
  script:
    - *init
    - terraform plan -var-file="envs/${TF_ENV}.tfvars" -out=tfplan
    - terraform apply tfplan

apply_dev:
  extends: .apply_template
  variables:
    TF_STATE_NAME: dev
    TF_ENV: dev
  environment:
    name: dev
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

apply_hml:
  extends: .apply_template
  variables:
    TF_STATE_NAME: hml
    TF_ENV: hml
  environment:
    name: hml
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  needs: [apply_dev]

apply_prod:
  extends: .apply_template
  variables:
    TF_STATE_NAME: prod
    TF_ENV: prod
  environment:
    name: prod
    deployment_tier: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  needs: [apply_hml]
```

Progressão: dev automático → hml manual → prod manual com approval.

## Protected environments

Em **Settings → CI/CD → Protected environments**, configure:

- **Environment**: `prod`
- **Allowed to deploy**: `Maintainers` (ou grupo específico).
- **Approval rules**: 2 approvers de grupos distintos.

Agora o botão "Deploy" em prod só funciona após approvals.

## Proteger a branch `main`

**Settings → Repository → Protected branches**:

- `main`:
  - Allowed to merge: Maintainers.
  - Allowed to push: No one (apenas via MR).
  - Require approval: 1+ aprovação.
  - Pipelines must succeed: ✅

Combinado com protected environments, temos:

1. Só maintainers podem mergear em `main`.
2. Só maintainers/grupos específicos podem disparar `apply_prod`.
3. `apply_prod` exige 2 approvals do próprio environment.

## `stop` action: destruindo ambientes efêmeros

Útil para review apps:

```yaml
deploy_review:
  stage: apply
  script:
    - terraform apply -auto-approve
  environment:
    name: review/${CI_COMMIT_REF_SLUG}
    on_stop: stop_review
    auto_stop_in: 1 week
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

stop_review:
  stage: apply
  script:
    - terraform destroy -auto-approve
  environment:
    name: review/${CI_COMMIT_REF_SLUG}
    action: stop
  when: manual
```

Ao fechar o MR (ou após 1 semana), o GitLab dispara `stop_review`.

## Drift detection com schedule

Crie **Schedules** em **CI/CD → Schedules**:

- Cron: `0 6 * * 1-5` (dias úteis às 6h).
- Variable: `JOB_TYPE = drift_check`

Pipeline:

```yaml
drift_check:
  stage: plan
  extends: .aws_oidc
  script:
    - *init
    - terraform plan -detailed-exitcode -out=tfplan || true
    - |
      if terraform show -json tfplan | jq -e '.resource_changes[]?' > /dev/null; then
        echo "DRIFT DETECTADO"
        # Envia notificação (Slack, email, issue automática)
        exit 1
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $JOB_TYPE == "drift_check"
```

`-detailed-exitcode` retorna:

- 0 → nenhuma mudança.
- 1 → erro.
- 2 → mudanças detectadas.

## `.gitlab-ci.yml` completo

```yaml
include:
  - template: Terraform/Base.latest.gitlab-ci.yml

stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_VERSION: "1.9.0"
  AWS_DEFAULT_REGION: us-east-1

default:
  image:
    name: hashicorp/terraform:${TF_VERSION}
    entrypoint: [""]

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
        --web-identity-token $AWS_ID_TOKEN)
      export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r .Credentials.AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .Credentials.SecretAccessKey)
      export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r .Credentials.SessionToken)

.init: &init |
  cd "${TF_ROOT}"
  TF_ADDRESS="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
  terraform init \
    -backend-config="address=${TF_ADDRESS}" \
    -backend-config="lock_address=${TF_ADDRESS}/lock" \
    -backend-config="unlock_address=${TF_ADDRESS}/lock" \
    -backend-config="username=gitlab-ci-token" \
    -backend-config="password=${CI_JOB_TOKEN}" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE"

# -------------------- VALIDATE --------------------

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
    - tflint --init && tflint --recursive

# -------------------- PLAN --------------------

.plan_template:
  stage: plan
  extends: .aws_oidc
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
    expire_in: 1 week

plan_dev:
  extends: .plan_template
  variables:
    TF_STATE_NAME: dev
    TF_ENV: dev
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

plan_prod:
  extends: .plan_template
  variables:
    TF_STATE_NAME: prod
    TF_ENV: prod
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# -------------------- APPLY --------------------

.apply_template:
  stage: apply
  extends: .aws_oidc
  script:
    - *init
    - terraform apply tfplan

apply_dev:
  extends: .apply_template
  variables:
    TF_STATE_NAME: dev
  dependencies: [plan_dev]
  environment:
    name: dev
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

apply_prod:
  extends: .apply_template
  variables:
    TF_STATE_NAME: prod
  dependencies: [plan_prod]
  environment:
    name: prod
    deployment_tier: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  needs: [apply_dev, plan_prod]
```

## Rollback

Quando algo sai errado:

### Opção 1 — Reverter o código e aplicar

```bash
git revert <commit>
git push
# Pipeline dispara: plan + apply revertendo
```

### Opção 2 — Checkout de tag anterior

```bash
git checkout v1.2.3
git checkout -b hotfix/rollback-v1.2.3
# ajuste se necessário
git push
```

Abrir MR com esse branch → plan mostra diferença para estado atual → merge → apply reverte.

### Opção 3 — `terraform state` manual

Em casos extremos (algo destruído erroneamente), você precisa de `import` ou restauração de backup do state. Procedimento caso-a-caso.

## Observabilidade

Monte dashboards que respondam:

- **Deploys por semana/mês**.
- **Taxa de sucesso/falha**.
- **Tempo médio de apply**.
- **MTTR** de problemas.
- **Drift detectado** por ambiente.

Ferramentas: GitLab Value Stream Analytics, Grafana + GitLab Exporter, ou DORA metrics API.

## Pitfalls

### 1. `apply` sem `needs: plan`

Se `plan` falha e `apply` roda mesmo assim, desastre. Use `needs`/`dependencies`.

### 2. Apply em branch errada

Sempre use `rules` com `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` no apply.

### 3. OIDC sem condição de branch

Sem condição no trust, qualquer MR pode assumir role. **Sempre** limite a `main`, branches específicas ou tags.

### 4. Sem protected environments

Qualquer dev pode clicar "deploy" em prod. Configure proteção.

### 5. Credenciais compartilhadas entre ambientes

Dev e prod usando mesma role/chave = blast radius enorme. **Separe**.

## Resumo

- Pipeline completo: validate → plan → apply em stages.
- Environments + protected environments + approvals = controle.
- OIDC + states separados + branches protegidas = segurança.
- Drift detection schedule = observabilidade.

Próximo: **pipelines de módulos** (publish em registry privada).
