# 06_06 - Terraform Registry

O **Terraform Registry** (registry.terraform.io) é o catálogo público da HashiCorp onde você descobre providers e módulos.

## Estrutura

- **Providers** (plugins) — `registry.terraform.io/providers/...`
- **Modules** (coleções de código reutilizável) — `registry.terraform.io/modules/...`

Além do registry público, existem:

- **Terraform Cloud / HCP Terraform**: registry privado hospedado.
- **Terraform Enterprise**: versão self-hosted do registry privado.
- **Artifactory, GitLab, GitHub Packages**: suporte a "generic" registries (para módulos via Git).

## Tiers e badges

Ao navegar por providers, você verá badges:

| Badge | Significado |
|-------|-------------|
| **Official** | Mantido pela HashiCorp. SLAs e releases frequentes. |
| **Partner** | Mantido por empresa parceira com contrato. Qualidade validada. |
| **Community** | Mantido por indivíduos ou grupos, sem garantias. |
| **Archived** | Não é mais mantido. |

Preferência:

1. Procure **Official** primeiro.
2. **Partner** é aceitável, especialmente de empresas grandes.
3. **Community** só se não houver alternativa — avalie o `README`, commits recentes, issues abertas.
4. **Archived** jamais em novos projetos.

## Anatomia de uma página de provider

Ao abrir, por exemplo, `hashicorp/aws`, você encontra:

- **Versões disponíveis** (sidebar direita).
- **Documentação por recurso e data source**.
- **Guias** (ex.: "Using AWS Provider with ...").
- **Exemplos** inline.
- **Changelog** / release notes.

Cada recurso mostra:

- Atributos requeridos (`Required`) e opcionais (`Optional`).
- Atributos **computed** (só de leitura, preenchidos pelo provider).
- Importação (`terraform import` ou bloco `import`).
- Exemplos de uso.

**Dica**: mantenha a documentação do provider aberta enquanto escreve Terraform — o retorno é enorme.

## Módulos no Registry

Módulos públicos seguem o formato `namespace/nome/provider`:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"
  # ...
}
```

Pontos importantes:

- **`source`** sem hostname → assume registry público.
- **`version`** com constraint.
- **Documentação** mostra inputs e outputs.
- **Exemplos** completos geralmente estão em `examples/` no repositório.

Módulos populares da comunidade (alta qualidade):

- `terraform-aws-modules/*` — organização com módulos AWS muito usados.
- `terraform-google-modules/*` — equivalentes GCP.
- `Azure/*` — módulos oficiais Azure.

## Fontes alternativas de módulos

Além do Registry, `source` aceita:

| Tipo | Exemplo |
|------|---------|
| Registry público | `terraform-aws-modules/vpc/aws` |
| Registry privado HCP | `app.terraform.io/empresa/vpc/aws` |
| Git HTTPS | `git::https://github.com/empresa/modules.git//vpc?ref=v1.2.0` |
| Git SSH | `git::ssh://git@github.com/empresa/modules.git//vpc?ref=v1.2.0` |
| Path local | `../modules/vpc` |
| S3 | `s3::https://s3.amazonaws.com/bucket/modules/vpc.zip` |
| GCS | `gcs::https://www.googleapis.com/storage/v1/bucket/modules/vpc.zip` |

Em projetos corporativos é comum misturar: módulos públicos para primitivas e registry privado para padrões da empresa.

## Lock file (`.terraform.lock.hcl`)

Ao rodar `init`, o Terraform grava as **versões exatas** escolhidas:

```hcl
# .terraform.lock.hcl (excerto)
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.40.0"
  constraints = "~> 5.0"

  hashes = [
    "h1:abc...",
    "zh:...",
  ]
}
```

Comandos para manipular:

```bash
# Atualiza tudo respeitando constraints
terraform init -upgrade

# Adiciona hashes multi-plataforma (útil se dev macOS + CI Linux)
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64
```

Commite esse arquivo. Ele torna builds reproduzíveis.

## Atualizações: como manter providers em dia

1. **Renovate** / **Dependabot** abrem PRs com atualizações.
2. CI roda `terraform plan` no PR.
3. Diferenças de comportamento aparecem no plan antes do merge.
4. Merge → aplica.

Frequência recomendada: patches semanais, minors mensais/trimestrais, majors conforme changelog exige.

## Verificando versões

```bash
# Versão da CLI
terraform version

# Providers instalados + versões
terraform providers

# Ver resolução: versão requisitada vs escolhida
terraform providers lock
```

## Erros típicos com Registry

- **`Failed to query available provider packages`** → rede bloqueando registry.terraform.io. Configure mirror ou proxy.
- **`provider requires newer version`** → constraint do provider exige CLI nova. Atualize Terraform.
- **Checksum mismatch** → lock file corrompido ou pacote adulterado. Apague o lock e rode `init` em ambiente confiável.

## Registry privado

Em empresas, módulos internos em registry privado:

```hcl
module "database" {
  source  = "terraform.empresa.com/plataforma/rds/aws"
  version = "~> 2.0"
  # ...
}
```

Benefícios:

- Versionamento centralizado.
- Auditoria de uso.
- Não vaza implementação interna.
- Controle de acesso via IAM/SSO.

Opções:

- **HCP Terraform** (pago, fácil).
- **Terraform Enterprise** (auto-hospedado).
- **Git tags** como versões, com `source` git (barato, requer disciplina).

## Boas práticas

- Sempre **fixe versões** (`version`) de providers e módulos.
- Prefira **Official/Partner**.
- **Leia o changelog** ao fazer upgrade de major.
- Teste upgrades em **dev** antes de **prod**.
- Mantenha `.terraform.lock.hcl` **commitado**.
- Em empresas, use **registry privado** para padrões internos.

No próximo tópico: **data sources** — consumindo dados de recursos existentes.
