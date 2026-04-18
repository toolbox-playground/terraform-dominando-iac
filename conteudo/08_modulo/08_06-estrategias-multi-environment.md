# 08_06 - Estratégias Multi-Environment

Como organizar dev / hml / prod em Terraform? Há várias abordagens — cada uma com trade-offs. Este tópico discute as principais.

## Opção 1 - Workspaces (mesmo diretório, múltiplos states)

```bash
terraform workspace new dev
terraform workspace new prod
```

Código:

```hcl
locals {
  ambiente = terraform.workspace

  config = {
    dev  = { tipo = "t3.micro", min = 1 }
    prod = { tipo = "t3.large", min = 3 }
  }

  atual = local.config[local.ambiente]
}
```

**Pró**:
- Zero duplicação de código.
- Troca rápida entre ambientes (`terraform workspace select`).

**Contra**:
- **Ambientes compartilham** provider config, variáveis, credenciais por padrão.
- Risco alto de **aplicar no ambiente errado** por engano.
- Dificuldade em separar IAM por ambiente.
- Não acomoda bem **infra muito diferente** entre ambientes.

**Quando usar**: experimentação rápida, PR previews, ambientes quase idênticos e de baixo risco.

## Opção 2 - Diretórios por ambiente

```
infra/
├── modules/                      # código reutilizável
│   ├── vpc/
│   ├── eks/
│   └── rds/
├── environments/
│   ├── dev/
│   │   ├── versions.tf           # backend específico
│   │   ├── main.tf               # chama módulos
│   │   └── terraform.tfvars
│   ├── hml/
│   └── prod/
```

Cada diretório tem seu `terraform.tfstate` separado (via `backend.key`).

`environments/prod/main.tf`:

```hcl
module "rede" {
  source = "../../modules/vpc"

  nome = "prod"
  cidr = "10.30.0.0/16"
}

module "cluster" {
  source = "../../modules/eks"

  nome         = "prod-cluster"
  vpc_id       = module.rede.vpc_id
  subnet_ids   = module.rede.private_subnet_ids
  node_groups  = var.node_groups
}
```

**Pró**:
- Separação **física** clara.
- Credenciais/backend distintos por ambiente.
- CI por ambiente independente (job diferente para dev vs prod).
- Mais difícil aplicar no errado por acidente.

**Contra**:
- **Duplicação** do "wiring" (main.tf por ambiente).
- Mudanças de padrão precisam propagar para todos os ambientes.

**Quando usar**: projetos médios e grandes, produção corporativa. **Estratégia mais adotada**.

## Opção 3 - Repositórios separados

```
infra-dev/       # repositório Git
infra-hml/
infra-prod/
```

Cada um com seu próprio código, backend, CI, permissões.

**Pró**:
- Isolamento máximo (permissões, audit, CI).
- Pode usar **versões diferentes** de módulos em cada ambiente.
- Mudança em prod não bloqueia dev.

**Contra**:
- Custos de manutenção (N repos, N pipelines).
- Desafio: manter módulos consistentes.
- Overhead para projetos pequenos.

**Quando usar**: organizações grandes, compliance rigoroso, times separados por ambiente.

## Opção 4 - Híbrida (monorepo + diretórios)

Muito adotada: um repo com `modules/` + `environments/dev/hml/prod`, mas com pipelines CI separadas (uma por ambiente).

Combina o melhor das Opções 2 e 3:

- Código compartilhado num só repo.
- Deploys isolados por ambiente.
- Credenciais/roles por pipeline.

Este curso vai por essa abordagem no **Módulo 11**.

## Comparação rápida

| Critério | Workspaces | Diretórios | Repos | Híbrida |
|----------|-----------|------------|-------|---------|
| Código DRY | ✅ | ⚠️ | ❌ | ✅ |
| Isolamento | ⚠️ | ✅ | ✅✅ | ✅ |
| Credenciais distintas | ⚠️ | ✅ | ✅ | ✅ |
| CI por ambiente | ⚠️ | ✅ | ✅ | ✅ |
| Curva de adoção | Baixa | Média | Alta | Média |
| Recomendado para produção | ⚠️ | ✅ | ✅ | ✅ |

## Convenções de nomenclatura

Em qualquer abordagem, padronize:

- **Prefixo**: `proj-ambiente-recurso` (ex.: `billing-prod-db`).
- **Tags**:
  - `Projeto`
  - `Ambiente`
  - `Owner` ou `CostCenter`
  - `ManagedBy = "terraform"`
  - `Repo` (útil para rastreamento)
- **CIDR**: faixa distinta por ambiente para evitar overlap em peering/VPN.
  - dev: `10.10.0.0/16`
  - hml: `10.20.0.0/16`
  - prod: `10.30.0.0/16`

## Promoção de mudanças (dev → hml → prod)

Fluxo recomendado:

1. Desenvolvedor edita módulo em branch.
2. PR com `terraform plan` (contra `dev`).
3. Merge → CI aplica em `dev`.
4. Após validação, promove (merge em branch `hml` → CI aplica).
5. Aprovação manual → aplica em `prod`.

Ferramentas úteis:

- Atlantis, Spacelift, Env0: orquestração.
- GitLab/GitHub native pipelines: menos mágica, mais controle.
- Terraform Cloud/Enterprise: runs com aprovação.

## Dicas práticas

- Escreva módulos **genéricos** e use **parâmetros** por ambiente. Evite `if ambiente == "prod"` espalhado.
- Mantenha um `README.md` por ambiente explicando:
  - Qual backend usa.
  - Quem pode aplicar.
  - Como rodar localmente.
- **Runbook** para promoções e rollback.

## Anti-patterns

- Copiar e colar código entre ambientes (divergência garantida).
- Acoplar `prod` a `dev` via `terraform_remote_state` (se dev quebra, prod não deveria sofrer).
- Usar um único state gigantesco para tudo (apply demora, risco sobe).
- Deixar workspaces abertos que ninguém usa.

## Exemplo: estrutura híbrida recomendada

```
infra/
├── modules/
│   ├── networking/
│   ├── compute/
│   └── data/
├── environments/
│   ├── dev/
│   │   ├── backend.tf        # key = "dev/..."
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── hml/
│   └── prod/
├── .gitlab-ci.yml            # pipeline por ambiente
└── README.md
```

Cada ambiente tem seu CI job + backend. Módulos são reutilizados.

## Resumo

- Não existe "a resposta certa". Escolha pela fase do projeto.
- Em dúvida: **diretórios separados** cobrem 90% dos casos.
- Documente **por que** a escolha; deixe a saída aberta para migrar depois.
- Trate promoções dev → prod como **processo**, não improvisação.

Próximo tópico: exemplo completo de projeto com multi-environment.
