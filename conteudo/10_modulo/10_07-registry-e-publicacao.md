# 10_07 - Terraform Registry e publicação

## Terraform Registry

[registry.terraform.io](https://registry.terraform.io) hospeda **providers** e **módulos** públicos.

### Namespaces comuns de módulos AWS

- `terraform-aws-modules/*` — organização HashiCorp-approved, muito completa.
- `cloudposse/*` — Cloud Posse.
- `hashicorp/*` — HashiCorp oficial.
- Comunidade diversa.

### Anatomia da página de módulo

- **Provision instructions**: snippet pronto pra copiar.
- **Versions**: lista de tags.
- **Inputs / Outputs**: gerados automaticamente.
- **Dependencies**: módulos/providers requeridos.
- **Examples**: de `examples/` do repo.

Use a Registry para **descobrir padrões** — mesmo que você decida escrever o seu, leia os bons.

## Como a Registry publica

Requisitos para um módulo **público** na Terraform Registry:

1. Repo público no GitHub.
2. Nome `terraform-<PROVIDER>-<NAME>` (ex.: `terraform-aws-vpc`).
3. Estrutura "standard":
   ```
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   └── README.md
   ```
4. Tags seguindo **SemVer**: `vX.Y.Z`.
5. Cada push de tag aparece como nova versão.

Depois é só adicionar o repo na Registry via UI (login com GitHub).

## Consumindo da Registry pública

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "minha-vpc"
  cidr = "10.0.0.0/16"
  # ...
}
```

Sempre fixe versão (`~>` ou `=`) e leia o **CHANGELOG** ao atualizar.

## Registry privada

Três opções comuns:

### 1. Terraform Cloud / Terraform Enterprise

- Registry integrada.
- Login com VCS (GitHub, GitLab).
- Publicação automática a partir de tags.
- Suporte a `version = ...`.

```hcl
module "vpc" {
  source  = "app.terraform.io/minha-org/vpc/aws"
  version = "~> 1.0"
}
```

### 2. GitLab Terraform Module Registry

Nativo no GitLab (inclui self-hosted).

- Cada projeto pode publicar módulos como artefatos.
- Publicação via API / CI.
- Consumo com `source = "<host>/<grupo>/<nome>/<sistema>"`.

Publicação via CI (trecho simplificado; exploraremos em Módulo 11):

```yaml
publish:
  stage: publish
  image: curlimages/curl
  script:
    - |
      curl --fail-with-body \
        --request PUT \
        --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
        --upload-file modulo.tgz \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/vpc/aws/1.0.0/file"
  rules:
    - if: $CI_COMMIT_TAG
```

Consumo:

```hcl
module "vpc" {
  source  = "gitlab.example.com/infra/modulos/vpc/aws"
  version = "1.0.0"
}
```

Autenticação em CI via `CI_JOB_TOKEN` ou credentials helper.

### 3. Git puro (sem registry)

Mais simples mas **sem constraint de versão**:

```hcl
module "vpc" {
  source = "git::https://gitlab.com/infra/terraform-aws-vpc.git?ref=v1.0.0"
}
```

## Setup: `~/.terraformrc`

Para autenticar em registry privada localmente:

```hcl
# ~/.terraformrc
credentials "gitlab.example.com" {
  token = "glpat-xxxxxxxxx"
}
```

Ou via variável:

```bash
export TF_TOKEN_gitlab_example_com="glpat-xxxxxxx"
```

(Notação: pontos no hostname viram underscores.)

## Pipeline típico de módulo

```
feature/x → PR/MR → main
                       └─ CI roda:
                            - fmt
                            - validate
                            - init + plan em examples/
                            - tflint
                            - checkov / tfsec
                            - terraform-docs --lint
                       └─ merge
                       └─ release (tag vX.Y.Z)
                            └─ CI publica na registry
```

Vamos implementar isso detalhadamente no **Módulo 11**.

## Checklist de qualidade pro seu módulo

### Interface
- [ ] Variables com `description`, `type`, `validation` quando fizer sentido.
- [ ] Defaults sensatos em opcionais.
- [ ] Outputs com `description`.
- [ ] `sensitive = true` em secrets.

### Recursos
- [ ] `this` ou nomes descritivos.
- [ ] Tags propagadas (ou input `tags`).
- [ ] `lifecycle` quando necessário.
- [ ] `path.module` em referências a arquivos.

### Estrutura
- [ ] `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- [ ] `README.md` gerado ou revisado.
- [ ] `examples/` com pelo menos 1 caso.
- [ ] `.terraform.lock.hcl` não commitado no módulo (só no root).

### Qualidade
- [ ] `terraform fmt` passa.
- [ ] `terraform validate` passa.
- [ ] `tflint` passa.
- [ ] Análise de segurança (`checkov`/`tfsec`) passa.
- [ ] CI roda `plan` em cada `examples/`.

### Versionamento
- [ ] SemVer.
- [ ] CHANGELOG.md.
- [ ] Tags `vX.Y.Z`.

## Ferramentas do ecossistema

| Ferramenta | Função |
|-----------|--------|
| `terraform fmt` | Formatação |
| `terraform validate` | Sintaxe e tipos |
| `tflint` | Lint extra (deprecated args, AMIs inválidas…) |
| `tfsec` / `checkov` | Security scanning |
| `terraform-docs` | Gera README.md |
| `infracost` | Estima custo da mudança |
| `terratest` | Testes em Go |
| `kitchen-terraform` | Testes em Ruby |
| `tftest` (Python) | Testes em Python |

## Pitfalls

### 1. Publicar antes de estabilizar API

Mudanças breaking em minor/patch quebram consumers. **Estabilize** a interface antes da `v1.0.0` (use `v0.x.y` enquanto evolui).

### 2. Não documentar breaking changes

CHANGELOG é obrigatório.

### 3. README desatualizado

Use `terraform-docs` em CI para regenerar sempre:

```bash
terraform-docs markdown table . > README.md
```

### 4. Permissões excessivas em registry privada

Revise tokens (`CI_JOB_TOKEN` tem escopo limitado; PATs podem ser amplos demais).

### 5. Confiar em módulos de terceiros sem auditar

Community modules podem ter bugs, vulnerabilidades ou práticas ruins. **Leia** antes de usar em prod.

## Resumo

- Registry pública = discovery; privada = reuso interno versionado.
- Publicação é orientada a **tags Git**.
- Pipelines garantem qualidade e automação.
- A Registry não substitui **revisão** — sempre audite.

Próximo e último tópico teórico do módulo: **exercícios**.
