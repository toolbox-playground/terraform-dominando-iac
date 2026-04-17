# 11_01 - Por que CI/CD para Terraform

Rodar `terraform apply` no laptop funciona — até não funcionar mais. Este tópico explica **por que** infraestrutura como código só entrega valor completo quando está em um pipeline.

## Os problemas do "apply local"

### 1. Nenhuma fonte da verdade

- Quem aplicou?
- Quando?
- Que versão do Terraform?
- Que versão do módulo?
- O state ainda bate com o Git?

Sem pipeline, essas respostas dependem de quem lembra.

### 2. Sem revisão

Mudanças em produção caem direto do `plan` do autor para o mundo. Sem segundo par de olhos, erros passam.

### 3. Sem audit trail

Auditoria e compliance exigem log imutável de quem mudou o quê. O terminal local não gera isso.

### 4. Dependência de credenciais humanas

Aplicar com credenciais do seu usuário IAM:

- Acopla infra a uma pessoa.
- Exige permissões amplas em laptops.
- Gira tokens manualmente.

### 5. Drift silencioso

Sem ciclo regular de `plan`, drift (mudança manual no console AWS) só aparece semanas depois.

### 6. Concorrência

Duas pessoas aplicam ao mesmo tempo. State lock ajuda **detectar**, mas não coordena quem merge o quê.

## O que CI/CD resolve

Um pipeline bem feito oferece:

1. **Formato único de execução**: mesma versão de Terraform, mesma máquina, mesmo ambiente.
2. **Gate de qualidade**: `fmt`, `validate`, `tflint`, `checkov` rodam antes de qualquer apply.
3. **Revisão obrigatória**: `plan` aparece no PR/MR; alguém precisa aprovar.
4. **Audit trail**: cada apply tem um job ID, autor, log, timestamp.
5. **OIDC / credenciais efêmeras**: pipeline assume role temporário, sem segredos permanentes.
6. **Ambientes escalonados**: mesma mudança percorre dev → hml → prod.
7. **Rollback**: pipelines versionados permitem replay de uma tag anterior.
8. **Automação de módulos**: release automático quando tag é criada.

## Fluxo clássico: PR/MR

```
┌────────────────────────────────────────────────────────┐
│  Developer abre Merge Request                          │
└────────────┬───────────────────────────────────────────┘
             ▼
┌────────────────────────────────────────────────────────┐
│  Pipeline validate                                     │
│  - terraform fmt -check                                │
│  - terraform validate                                  │
│  - tflint                                              │
│  - checkov / tfsec                                     │
└────────────┬───────────────────────────────────────────┘
             ▼
┌────────────────────────────────────────────────────────┐
│  Pipeline plan                                         │
│  - terraform init (backend remoto)                     │
│  - terraform plan -out=tfplan                          │
│  - publish plan como comentário no MR                  │
└────────────┬───────────────────────────────────────────┘
             ▼
┌────────────────────────────────────────────────────────┐
│  Revisão humana + Approval                             │
└────────────┬───────────────────────────────────────────┘
             ▼ (merge)
┌────────────────────────────────────────────────────────┐
│  Pipeline apply                                        │
│  - terraform apply tfplan                              │
│  - registra evento de deploy                           │
└────────────────────────────────────────────────────────┘
```

## Por que GitLab neste curso

- **Gratuito e self-hostável** (vs. Terraform Cloud pago).
- **HTTP backend nativo** para state (sem precisar de S3).
- **Terraform Module Registry** embutido.
- **Environments** com approvals/protected branches.
- **OIDC** para assumir roles na AWS/GCP/Azure sem armazenar chaves.
- **Mesmos conceitos** transferíveis para GitHub Actions, Jenkins, CircleCI, Azure DevOps.

## Modelos de execução

### Modelo 1 — Pipeline simples (dois estágios)

- `plan` roda em MR.
- `apply` roda no merge para `main` (automaticamente).

Bom para dev/sandbox.

### Modelo 2 — Pipeline com approval manual

- `plan` em MR.
- Após merge, `apply` fica **manual** — aguarda botão.

Bom para hml/prod.

### Modelo 3 — Pipeline com ambientes múltiplos

- Mesmo código, múltiplos jobs: `plan_dev`, `plan_hml`, `plan_prod`.
- Apply progressivo com approvals.

Bom para infra corporativa.

### Modelo 4 — Atlantis / Spacelift / Terraform Cloud

Plataformas dedicadas. Mais UI, menos YAML.

Este módulo foca no **Modelo 3** usando GitLab puro.

## Terminologia GitLab

| Termo | Significado |
|-------|-------------|
| **Pipeline** | Execução de CI/CD para um commit. |
| **Stage** | Grupo lógico de jobs (ex.: `validate`, `plan`, `apply`). |
| **Job** | Tarefa atômica (container + script). |
| **Runner** | Máquina que executa jobs (shared, group ou project-specific). |
| **Artifact** | Arquivo gerado por um job e passado adiante (ex.: `tfplan`). |
| **Variable** | Config/secret definido no projeto, grupo ou job. |
| **Environment** | Ambiente rastreado no GitLab (dev, hml, prod) com proteção. |
| **Protected branch** | Branch que só aceita push/merge com regras (ex.: `main`). |

## O que vamos construir

Ao final do módulo, você terá:

1. Um **repositório de infra** com pipeline:
   - `validate` → `plan` (em MR) → `apply` (manual em `main`).
   - State remoto via **HTTP backend** no GitLab.
   - Autenticação AWS via **OIDC** (sem chaves estáticas).
   - Ambientes `dev`, `hml`, `prod`.
2. Um **repositório de módulo** com pipeline:
   - Lint + validate + checkov.
   - `plan` em exemplos.
   - Release automático para GitLab Terraform Registry em tags.

## Pré-requisitos

- Conta GitLab (gitlab.com ou self-hosted).
- Conhecimento dos Módulos 1 a 10 deste curso.
- Para os laboratórios: AWS, GCP ou Azure (ou LocalStack).

## Resumo

Pipeline não é "extra" — é o que torna IaC auditável, reproduzível e colaborativo. Nos próximos tópicos vamos construir passo a passo.

Próximo: **conceitos de GitLab CI/CD**.
