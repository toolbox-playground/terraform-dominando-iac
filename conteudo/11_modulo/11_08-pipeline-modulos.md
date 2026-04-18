# 11_08 - Pipeline de módulos + release automático

Pipelines de **infra** aplicam mudanças. Pipelines de **módulo** publicam versões. Este tópico cobre o segundo tipo: como automatizar lint, testes, e publicação de um módulo Terraform em registry privada do GitLab.

## Objetivo

Quando alguém cria tag `vX.Y.Z` no repo do módulo, o pipeline:

1. Valida código (`fmt`, `validate`, `tflint`, `checkov`).
2. Roda `plan` nos exemplos.
3. Gera arquivo `.tgz` do módulo.
4. Publica no GitLab Terraform Module Registry.
5. Gera release com CHANGELOG.

## Estrutura sugerida

```
terraform-aws-bucket-seguro/
├── .gitlab-ci.yml
├── CHANGELOG.md
├── README.md
├── LICENSE
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── examples/
    ├── basico/
    │   ├── main.tf
    │   └── terraform.tfvars
    └── com-replication/
        └── main.tf
```

## Pipeline em duas fases

### Fase 1 — Validação (em todo push e MR)

```yaml
stages:
  - validate
  - test
  - publish

default:
  image:
    name: hashicorp/terraform:1.9
    entrypoint: [""]

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
    - checkov -d . --framework terraform --quiet --compact

terraform-docs:
  stage: validate
  image: quay.io/terraform-docs/terraform-docs:0.17.0
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - terraform-docs markdown table --output-mode inject --output-file README.md .
    - git diff --exit-code README.md
```

### Fase 2 — Teste dos examples

Cada pasta em `examples/` é um root module. Rode `plan` em cada:

```yaml
.example_plan:
  stage: test
  extends: .aws_oidc   # conforme 11_06
  script:
    - cd examples/${EXAMPLE}
    - terraform init
    - terraform plan -input=false

plan_basico:
  extends: .example_plan
  variables:
    EXAMPLE: basico

plan_com_replication:
  extends: .example_plan
  variables:
    EXAMPLE: com-replication
```

**Opcional** (mais caro): `apply` + `destroy` em conta sandbox.

### Fase 3 — Publicação em tag

Quando tag `vX.Y.Z` for criada:

```yaml
publish:
  stage: publish
  image: curlimages/curl:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  variables:
    MODULE_NAME: bucket-seguro
    MODULE_SYSTEM: aws
    MODULE_VERSION: ${CI_COMMIT_TAG#v}   # remove prefixo v
  before_script:
    - apk add --no-cache tar
  script:
    # Empacota apenas arquivos relevantes (não inclui .git/, .terraform/, etc.)
    - |
      tar czf module.tgz \
        --exclude='.git' \
        --exclude='.terraform' \
        --exclude='.terraform.lock.hcl' \
        --exclude='*.tfstate*' \
        --exclude='examples' \
        .
    # Publica no GitLab Terraform Module Registry
    - |
      curl --fail-with-body \
        --request PUT \
        --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
        --upload-file module.tgz \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${MODULE_NAME}/${MODULE_SYSTEM}/${MODULE_VERSION}/file"
```

## Consumindo o módulo publicado

Em outro projeto:

```hcl
module "bucket" {
  source  = "gitlab.com/grupo-raiz/terraform-aws-bucket-seguro/aws"
  version = "1.0.0"

  nome     = "meu-bucket"
  ambiente = "prod"
}
```

O **namespace** é o **top-level group** do projeto do módulo.

### Autenticação para consumir

Localmente, `~/.terraformrc`:

```hcl
credentials "gitlab.com" {
  token = "glpat-xxx"
}
```

Em CI (outro projeto), por padrão o `CI_JOB_TOKEN` tem acesso apenas ao próprio projeto. Para permitir acesso entre projetos:

- No projeto do módulo: **Settings → CI/CD → Token access** → permitir que o projeto consumidor use `CI_JOB_TOKEN`.
- No projeto consumidor: também permitir.

Alternativa: usar **Project Access Token** com escopo `read_api` dedicado.

## Release + CHANGELOG automático

Use o [release-cli](https://docs.gitlab.com/ee/ci/yaml/index.html#release) do GitLab:

```yaml
release:
  stage: publish
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  script:
    - echo "Creating release for $CI_COMMIT_TAG"
  release:
    tag_name: $CI_COMMIT_TAG
    description: |
      Release $CI_COMMIT_TAG
      
      Veja [CHANGELOG.md](CHANGELOG.md) para detalhes.
    assets:
      links:
        - name: "Module package"
          url: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${MODULE_NAME}/${MODULE_SYSTEM}/${CI_COMMIT_TAG#v}/file"
```

### CHANGELOG automático com conventional commits

Se o time usa [conventional commits](https://www.conventionalcommits.org/), gere CHANGELOG automaticamente:

```yaml
changelog:
  stage: publish
  image: node:20-alpine
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  script:
    - npm install -g conventional-changelog-cli
    - conventional-changelog -p angular -r 2 > CHANGELOG_RELEASE.md
    - cat CHANGELOG_RELEASE.md
  artifacts:
    paths: [CHANGELOG_RELEASE.md]
```

## Publicação condicional: só após validação

Combine com `needs`:

```yaml
publish:
  stage: publish
  needs:
    - fmt
    - validate
    - tflint
    - checkov
    - plan_basico
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  # ...
```

Se qualquer validação falhar, a tag **não** publica.

## Versionamento automático via CI

Alternativa mais sofisticada: usar [`semantic-release`](https://semantic-release.gitbook.io/) para analisar commits e criar tags automaticamente.

```yaml
release_auto:
  stage: publish
  image: node:20-alpine
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script:
    - npm install -g semantic-release @semantic-release/gitlab
    - GITLAB_TOKEN=$GITLAB_RELEASE_TOKEN npx semantic-release
```

Configuração `.releaserc.json`:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/gitlab"
  ]
}
```

Commit `feat: ...` = minor. `fix: ...` = patch. `BREAKING CHANGE` = major.

Resultado: você escreve apenas commits bem formados, o CI cuida das tags e releases.

## Pipeline completo de módulo

```yaml
stages:
  - validate
  - test
  - publish

default:
  image:
    name: hashicorp/terraform:1.9
    entrypoint: [""]

# --- validate ---

fmt:
  stage: validate
  script: [terraform fmt -check -recursive]

validate:
  stage: validate
  script:
    - terraform init -backend=false
    - terraform validate

tflint:
  stage: validate
  image: ghcr.io/terraform-linters/tflint:latest
  script: [tflint --init, tflint --recursive]

checkov:
  stage: validate
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script: [checkov -d . --framework terraform --quiet --compact]

# --- test ---

.example:
  stage: test
  before_script:
    - cd examples/${EXAMPLE}
  script:
    - terraform init -backend=false
    - terraform validate

test_basico:
  extends: .example
  variables:
    EXAMPLE: basico

# --- publish ---

publish:
  stage: publish
  image: curlimages/curl:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  variables:
    MODULE_NAME: bucket-seguro
    MODULE_SYSTEM: aws
    MODULE_VERSION: ${CI_COMMIT_TAG#v}
  before_script:
    - apk add --no-cache tar
  script:
    - |
      tar czf module.tgz \
        --exclude='.git' \
        --exclude='.terraform*' \
        --exclude='examples' .
    - |
      curl --fail-with-body \
        --request PUT \
        --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
        --upload-file module.tgz \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${MODULE_NAME}/${MODULE_SYSTEM}/${MODULE_VERSION}/file"

release:
  stage: publish
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  script:
    - echo "release ${CI_COMMIT_TAG}"
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG"
  needs: [publish]
```

## Testando localmente antes do push

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
tflint --init && tflint --recursive
checkov -d . --framework terraform

# Simular publicação local (sem enviar):
tar czf module.tgz --exclude='.git' --exclude='.terraform*' .
ls -lh module.tgz
```

## Pitfalls

### 1. Sem tags SemVer

`git push` sem tag = nenhum release. Crie a tag **depois** de mergear em main:

```bash
git tag -a v1.2.0 -m "feat: suporte a replication"
git push --tags
```

### 2. Pacote muito grande

Excluir pastas `examples/`, `.git/`, `.terraform/` é essencial.

### 3. Autenticação entre projetos

Se consumidor em outro grupo/projeto não consegue baixar, revise **Token access** e permissões de grupo.

### 4. Tags não protegidas

Qualquer dev pode criar tag `v*` e disparar publish. Configure **Protected tags** em **Settings → Repository**.

## Resumo

- Pipeline de módulo garante qualidade + publicação automática.
- Tags são gatilhos para publish + release.
- GitLab Terraform Registry é nativo — sem infraestrutura extra.
- SemVer + CHANGELOG + protected tags = processo maduro.

Próximo: **boas práticas** e armadilhas transversais.
