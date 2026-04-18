# 10_05 - Layout e organização de código

Não existe "layout oficial", mas há padrões consagrados. Esta seção apresenta três estratégias comuns e quando usar cada.

## Layout 1 — Projeto único com módulos locais

```
infra/
├── versions.tf
├── providers.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── eks/
    └── rds/
```

**Uso no `main.tf`**:

```hcl
module "vpc" { source = "./modules/vpc" ... }
module "eks" { source = "./modules/eks" ... }
```

**Bom para**:
- Projeto pequeno.
- Infra de uma única app.
- Um único ambiente (ou gerenciado via workspace/tfvars).

**Ruim para**:
- Múltiplos ambientes com muita divergência.
- Equipes separadas que evoluem módulos independentemente.

## Layout 2 — Monorepo com múltiplos roots

```
infra/
├── modules/           # módulos reutilizáveis (locais ou publicados)
│   ├── vpc/
│   ├── eks/
│   └── rds/
└── live/              # roots por ambiente/stack
    ├── dev/
    │   ├── rede/
    │   │   ├── versions.tf
    │   │   ├── main.tf
    │   │   └── terraform.tfvars
    │   ├── eks/
    │   └── apps/
    ├── hml/
    └── prod/
```

- Cada diretório em `live/*/` é um **root module** (`terraform init/apply` próprio).
- Cada root tem seu state próprio.
- Módulos em `modules/` são compartilhados via `source = "../../../modules/vpc"`.

**Bom para**:
- Múltiplos ambientes com configurações distintas.
- Blast radius reduzido (aplicar só rede não mexe em apps).
- CI/CD com jobs independentes por stack.

**Ruim para**:
- Drift entre envs (precisa disciplina).
- Muita duplicação de código "wiring".

### Variante: "stacks" lógicas

```
live/
├── prod/
│   ├── 010-rede/
│   ├── 020-seguranca/
│   ├── 030-eks/
│   ├── 040-rds/
│   └── 050-apps/
```

Numeração sugere ordem de dependência; cada stack tem seu state. Composição via `terraform_remote_state`.

## Layout 3 — Multi-repo

```
org/
├── terraform-aws-vpc/          # repo de módulo
├── terraform-aws-eks/           # repo de módulo
├── infra-dev/                   # repo de ambiente
│   ├── rede/
│   ├── eks/
│   └── apps/
├── infra-hml/
└── infra-prod/
```

- Módulos viram **artefatos** versionados (tags).
- Ambientes ficam em repos próprios, consumindo módulos via Git/Registry.

**Bom para**:
- Organizações grandes.
- Times de plataforma vs. squads de aplicação.
- Versionamento rigoroso (mudar módulo não afeta infra imediatamente).

**Ruim para**:
- Coordenação entre repos (mudança cross-cutting vira N PRs).
- Onboarding mais lento.

## Convenção de nomes

### Nomes de repos de módulos

```
terraform-<provider>-<nome>
```

Exemplos:
- `terraform-aws-vpc`
- `terraform-gcp-gke`
- `terraform-azurerm-postgres`

Essa é a convenção do **Terraform Registry**. Sigam mesmo em repos privados para uniformidade.

### Nomes de recursos dentro do módulo

- **Um recurso principal**: `this` ou `main`.
  ```hcl
  resource "aws_s3_bucket" "this" { ... }
  ```
- **Múltiplos recursos**: nomes descritivos.
  ```hcl
  resource "aws_subnet" "public" { ... }
  resource "aws_subnet" "private" { ... }
  ```

### Nomes de módulos no caller

Use nomes do **domínio**, não da tecnologia:

```hcl
# Preferível
module "rede" { source = "./modules/vpc" ... }
module "cluster_kubernetes" { source = "./modules/eks" ... }

# Pior
module "aws_vpc" { ... }
module "eks_cluster_wrapper" { ... }
```

## Arquivos recomendados

Por root module:

| Arquivo | Propósito |
|---------|-----------|
| `versions.tf` | Bloco `terraform` + `required_providers` |
| `providers.tf` | Configuração de `provider "xxx" { }` |
| `main.tf` | Recursos/módulos principais |
| `variables.tf` | Declaração de `variable` |
| `outputs.tf` | Declaração de `output` |
| `locals.tf` | `locals { }` complexos (opcional) |
| `data.tf` | `data` blocks (opcional) |
| `terraform.tfvars` | Valores default do root |
| `README.md` | Documentação |

Terraform não requer esses nomes — é convenção para facilitar leitura.

## Separação por stack vs. workspace

Revisão rápida (vide Módulo 8):

| Dimensão | Workspace | Diretórios separados |
|----------|-----------|----------------------|
| Isolamento de state | ✓ | ✓ |
| Pode divergir código? | ✗ (mesmo código) | ✓ |
| Blast radius | alto (mesmo root) | baixo (roots diferentes) |
| Bom para | labs, efêmero | prod |

**Produção séria**: diretórios separados.

## Arquitetura em camadas

Separe por **ciclo de mudança** e **blast radius**:

```
Camada 1 - Foundation (rede, IAM baseline)
    ↓
Camada 2 - Plataforma (EKS, RDS, Redis)
    ↓
Camada 3 - Aplicações (Deployments, Services)
```

Cada camada:
- Muda em cadência diferente.
- Tem owner diferente.
- Tem blast radius diferente.
- Expõe outputs consumidos pela próxima via `terraform_remote_state`.

## Drift entre ambientes

Problema comum: `dev` e `prod` divergem porque alguém editou só um.

**Mitigações**:

1. **Mesmos módulos versionados**: `source = "...?ref=v1.2.0"` nos dois.
2. **`.tfvars` distintos**, código igual.
3. **Promoção controlada**: mudança vai dev → hml → prod via merge requests.
4. **Ferramentas**: Atlantis, Spacelift, Terraform Cloud.

## Exemplo realista: projeto SaaS

```
saas-infra/
├── modules/
│   ├── network/              # VPC, subnets, NAT
│   ├── eks-cluster/          # EKS + node groups
│   ├── database/             # RDS + backup
│   ├── cache/                # ElastiCache
│   ├── observability/        # CloudWatch, Grafana
│   └── iam-baseline/         # Roles, policies padrão
└── live/
    ├── dev/
    │   ├── foundation/
    │   │   ├── network.tf
    │   │   ├── iam.tf
    │   │   └── backend.tf
    │   ├── platform/
    │   │   ├── eks.tf
    │   │   ├── db.tf
    │   │   └── cache.tf
    │   └── apps/
    │       ├── api.tf
    │       ├── workers.tf
    │       └── frontend.tf
    ├── hml/   # mesma estrutura
    └── prod/
```

## Pitfalls

1. **Root único para tudo**: aplicar "mudar tag da API" recalcula plano para rede/DB/EKS inteiro. Lento e arriscado.
2. **Módulos que expõem "tudo"**: 40 outputs pra não "impedir" caller → vira API pública congelada.
3. **Sem `versions.tf`**: nenhum pin de provider → upgrades surpresa.
4. **tfvars em Git** com senhas: use Secrets Manager / Vault / CI variables.
5. **Scripts bash chamando `terraform apply`**: prefira CI/CD explícito (Módulo 11).

## Resumo

- **Projeto único** para começar.
- **Monorepo com múltiplos roots** para crescimento controlado.
- **Multi-repo** para organizações grandes com times separados.
- Separe por **blast radius** e **ciclo de mudança**.
- Convenções de nomes e arquivos ajudam onboarding.

Próximo tópico: **padrões avançados** — dependency injection, composition, feature flags.
