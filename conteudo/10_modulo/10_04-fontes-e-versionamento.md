# 10_04 - Fontes e versionamento de módulos

O argumento `source` no bloco `module { }` aceita **vários formatos**. A escolha afeta versionamento, auditoria e segurança.

## Fontes locais

```hcl
module "vpc" {
  source = "./modules/vpc"        # relativo
}

module "vpc" {
  source = "../common/modules/vpc"  # subir diretórios também funciona
}
```

**Quando usar**: módulos internos do mesmo repositório.

**Sem versionamento**: o módulo "é" o que está no disco na hora do `init`.

## Git

### HTTPS

```hcl
module "vpc" {
  source = "git::https://github.com/org/terraform-aws-vpc.git?ref=v1.2.0"
}
```

### SSH

```hcl
module "vpc" {
  source = "git::git@github.com:org/terraform-aws-vpc.git?ref=v1.2.0"
}
```

### Subdiretório

```hcl
module "vpc" {
  source = "git::https://github.com/org/terraform-modules.git//vpc?ref=v1.2.0"
}
```

O `//` separa o repo do subpath.

### Referências (`ref`)

- `ref=v1.2.0` — tag (**recomendado**)
- `ref=main` — branch (**evite** em prod, instável)
- `ref=abc123` — commit (imutável, mas menos legível)

### GitLab

```hcl
module "vpc" {
  source = "git::https://gitlab.com/org/terraform-aws-vpc.git?ref=v1.2.0"
}

# Com CI_JOB_TOKEN em pipelines
module "vpc" {
  source = "git::https://gitlab-ci-token:${env.CI_JOB_TOKEN}@gitlab.com/org/modulo.git?ref=v1.2.0"
}
```

## Terraform Registry (público)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}
```

Formato: `NAMESPACE/NOME/PROVIDER`.

**Vantagens**:
- Constraint de versão (`~>`, `>=`, etc.).
- Docs e README na Registry.
- Verificação de download.

## Registry privada

### Terraform Cloud / Enterprise

```hcl
module "vpc" {
  source  = "app.terraform.io/minha-org/vpc/aws"
  version = "~> 1.0"
}
```

### GitLab Terraform Module Registry

```hcl
module "vpc" {
  source  = "gitlab.com/grupo/modulos/vpc/aws"
  version = "1.2.0"
}
```

Publicação via pipeline GitLab (veremos no Módulo 11).

## HTTP / S3 / GCS

```hcl
module "vpc" {
  source = "https://example.com/modulo.zip"
}

module "vpc" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/modulo.zip"
}

module "vpc" {
  source = "gcs::https://www.googleapis.com/storage/v1/bucket/modulo.zip"
}
```

Raramente usado, mas válido para distribuir módulos internamente sem registry dedicada.

## Versionamento

### `version` só funciona com Registry

```hcl
# OK — Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# NÃO — Git (use ?ref= na URL)
module "vpc" {
  source = "git::https://github.com/org/vpc.git"
  # version = "v1.2.0"   # ← ignorado em Git!
}
```

### Operadores de versão

| Operador | Exemplo | Significa |
|----------|---------|-----------|
| `=` | `= 1.2.3` | Exatamente |
| `>=` | `>= 1.2.0` | A partir de |
| `<=` | `<= 2.0.0` | Até |
| `>` / `<` | `> 1.0.0` | Estritamente |
| `!=` | `!= 1.5.0` | Exclui versão |
| `~>` | `~> 1.2` | >= 1.2, < 2.0 (pessimistic) |
| `~>` | `~> 1.2.3` | >= 1.2.3, < 1.3.0 |

**Produção**: use `~> X.Y` (permite patches e minors).
**Crítico**: fixe `= X.Y.Z`.
**Lab**: `>= X.Y` está ok.

## Semantic Versioning (SemVer)

Módulos publicados DEVEM seguir `MAJOR.MINOR.PATCH`:

- **PATCH** (1.2.3 → 1.2.4): bugfix compatível.
- **MINOR** (1.2 → 1.3): nova feature sem breaking change.
- **MAJOR** (1.x → 2.0): breaking change (remover output, renomear variable obrigatória).

Consumers escolhem o quanto querem receber com `~>`.

## Upgrades de módulo

```bash
terraform init -upgrade
```

- Pega a versão **mais recente compatível** com seus constraints.
- Atualiza `.terraform/modules/`.
- Sempre rode **`terraform plan`** depois para ver o que muda.

## Exemplos por cenário

### Monorepo (módulos locais)

```hcl
module "vpc"   { source = "./modules/vpc" }
module "rds"   { source = "./modules/rds" }
module "eks"   { source = "./modules/eks" }
```

### Multi-repo com Git tags

```hcl
module "vpc" {
  source = "git::https://gitlab.com/infra/terraform-modules.git//vpc?ref=vpc/v2.3.0"
}
```

(Convenção: `SUBMODULO/vX.Y.Z`.)

### Módulos públicos + privados

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

module "security_baseline" {
  source  = "gitlab.com/infra/modulos/security-baseline/aws"
  version = "~> 1.0"
}
```

## Pinning com lock file

Terraform **não** grava versões de módulos no `.terraform.lock.hcl` — esse arquivo é só para **providers**.

Para módulos, você garante determinismo via:

1. `version = "X.Y.Z"` exato (Registry).
2. `?ref=v1.2.0` tag (Git).
3. Commit SHA (`?ref=abc123`).

## Segurança e auditoria

- **Prefira tags imutáveis**: alguém pode mover uma tag, mas um commit SHA não muda.
- **Revise o módulo** antes de usar de terceiros (especialmente Community tier).
- **Fork para auditoria** de módulos críticos em produção.
- **Mirrors internos**: em ambientes ultra-regulados, cache os módulos num registry interno.

## Cache e `init`

Terraform baixa módulos em `.terraform/modules/`:

```
.terraform/
├── modules/
│   ├── modules.json
│   └── vpc/         # conteúdo do módulo
└── providers/
```

- `terraform init` baixa se faltar.
- `terraform init -upgrade` força re-download (respeitando constraints).
- `.terraform/` **nunca** deve ir para Git.

## Pitfalls

### 1. `source` com branch

```hcl
# PERIGOSO
source = "git::https://gitlab.com/org/modulo.git?ref=main"
```

O módulo **muda em silêncio** a cada `init`. Use **tags**.

### 2. Versão minor "inofensiva"

Nem todo maintainer respeita SemVer direito. **Sempre rode `plan`** depois de um upgrade.

### 3. Caminhos relativos em módulos

Use `path.module` dentro do módulo, não `./`:

```hcl
templatefile("${path.module}/templates/x.tpl", vars)  # ✓
templatefile("./templates/x.tpl", vars)               # depende do cwd
```

### 4. Dependências transitivas

Se `modulo_a` consome `modulo_b` (`source = "..."` dentro dele), você **não** controla a versão de `modulo_b` diretamente — só através do constraint que `modulo_a` tem.

Mantenha árvores **rasas**.

## Resumo

- `source` define **de onde** o módulo vem; `version` só funciona em Registry.
- **Produção**: use tags Git ou `~>` em Registry.
- **Sempre** rode `init` após mudar source/version, e `plan` antes de `apply`.
- Mantenha módulos **versionados** e **documentados** com SemVer.

Próximo tópico: **layout de diretórios** para monorepos e multi-repos.
