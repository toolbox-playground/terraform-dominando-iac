# 08_04 - Workspaces

**Workspace** é um **state isolado** dentro do mesmo diretório de código. Útil para gerenciar ambientes similares sem duplicar configs, mas com limitações importantes.

## Conceito

Um projeto Terraform sempre tem **pelo menos um workspace**: `default`. Você pode criar outros:

```bash
terraform workspace new dev
terraform workspace new hml
terraform workspace new prod
```

Cada workspace tem seu próprio state. O código é **o mesmo**; o que muda é o state escolhido.

## Comandos

```bash
terraform workspace list       # lista workspaces
terraform workspace show       # qual estou agora
terraform workspace select X   # troca para X
terraform workspace new Y      # cria e seleciona Y
terraform workspace delete Z   # remove (não pode ser o atual)
```

## Como diferenciar comportamento por workspace

Use `terraform.workspace` no código:

```hcl
locals {
  ambiente = terraform.workspace

  tipo_instancia = {
    default = "t3.micro"
    dev     = "t3.micro"
    hml     = "t3.small"
    prod    = "t3.medium"
  }[terraform.workspace]
}

resource "aws_s3_bucket" "app" {
  bucket = "app-${terraform.workspace}-logs"
}
```

O `terraform.workspace` é uma string — você usa como qualquer outra.

## Onde o state vive

Com backend `local`: `terraform.tfstate.d/<workspace>/terraform.tfstate`.

Com backend `s3`:
- workspace `default`: `bucket/prefixo/key`.
- workspaces nomeados: `bucket/env:/<workspace>/prefixo/key`.

Exemplo:

```hcl
backend "s3" {
  bucket = "tfstate"
  key    = "app/terraform.tfstate"
  region = "us-east-1"
}
```

- `default` → `s3://tfstate/app/terraform.tfstate`
- `prod` → `s3://tfstate/env:/prod/app/terraform.tfstate`

## Workspace selection no init

Terraform Cloud (`cloud { }`) tem gerenciamento próprio de workspaces; a sintaxe muda um pouco. Para este curso focamos nos backends OSS.

## Quando usar workspaces

### Bom para

- **Experimentos rápidos**: um dev cria workspace próprio para testar sem afetar `dev`.
- **Ambientes quase idênticos**: dev/hml/prod com pouquíssima diferença.
- **PR preview environments** efêmeros.

### Ruim para

- **Ambientes muito diferentes**: dev single-AZ vs. prod multi-AZ com DR cross-region → workspaces não acomodam bem.
- **Credenciais distintas por ambiente**: workspaces compartilham provider config, embora você possa alternar via env vars.
- **Projetos grandes**: um erro em dev pode acidentalmente tocar prod pelo `select` errado.
- **Controle de acesso granular**: difícil restringir "só pode aplicar em dev".

Por isso, muitos times **preferem** uma pasta/repositório por ambiente com **backend key explícito** (ver [08_06 - Estratégias Multi-Environment](08_06-estrategias-multi-environment.md)).

## Exemplo completo com workspaces

```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate"
    key            = "plataforma/rede/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tflocks"
    encrypt        = true
  }
}

locals {
  ambiente = terraform.workspace

  config = {
    default = { cidr = "10.0.0.0/16", azs = 2 }
    dev     = { cidr = "10.10.0.0/16", azs = 2 }
    hml     = { cidr = "10.20.0.0/16", azs = 3 }
    prod    = { cidr = "10.30.0.0/16", azs = 3 }
  }

  atual = local.config[local.ambiente]
}

resource "aws_vpc" "this" {
  cidr_block = local.atual.cidr

  tags = {
    Name     = "${local.ambiente}-vpc"
    Ambiente = local.ambiente
  }
}
```

Workflow:

```bash
terraform workspace new dev
terraform apply       # cria VPC dev

terraform workspace new prod
terraform apply       # cria VPC prod
```

Dois estados distintos, mesmo código.

## Armadilhas comuns

### Esquecer `workspace select`

Você pode estar em `dev` achando que está em `prod` — aplicar, achar que aconteceu em prod. **Sempre** rode `terraform workspace show` antes de `apply`.

Mitigação: coloque no prompt shell:

```bash
# ~/.zshrc
prompt_tf_ws() {
  [ -d .terraform ] && echo "[tf:$(terraform workspace show 2>/dev/null)] "
}
PROMPT='$(prompt_tf_ws)%~ '
```

### Provider config única

O `provider "aws" { region = "us-east-1" }` vale para **todos os workspaces**. Se `dev` e `prod` estão em contas AWS diferentes, você precisa:

- Variáveis: `region = var.regiao_por_workspace[terraform.workspace]`.
- Aliases (mas limitados por workspace).
- Ou **separar em diretórios** (abordagem preferida).

### Impossível referenciar workspace em `backend`

O bloco `backend` não aceita variáveis. Você **não** pode fazer `key = "${terraform.workspace}/terraform.tfstate"` — Terraform Cloud/OSS cuidam do prefixo automaticamente.

## `terraform.workspace` não é contrato

O valor `default` é padrão quando você cria um diretório sem explicitar workspace. Evite lógica que dependa disso — prefira variáveis explícitas ou validar que `terraform.workspace != "default"`.

```hcl
check "workspace_valido" {
  assert {
    condition     = contains(["dev", "hml", "prod"], terraform.workspace)
    error_message = "Workspace inválido. Use: dev, hml, prod."
  }
}
```

## Workspaces vs. diretórios separados

Resumo do que vemos na prática:

| | Workspaces | Diretórios |
|---|-----------|-----------|
| Overhead | Baixo | Médio |
| Isolamento real | Fraco | Forte |
| Credenciais distintas | Difícil | Natural |
| CI por ambiente | Compartilhado | Dedicado |
| Atomicidade entre ambientes | Sim (mesmo repo) | Precisa orquestrar |
| Recomendado para prod corporativa | Não | Sim |

**Conclusão**: workspaces ótimos para **experimentação**, menos ideais para **produção enterprise**. No próximo tópico vemos a estratégia de diretórios.

## Próximo tópico

**`.tfvars` e arquivos de variáveis** — como parametrizar por ambiente sem depender de workspace.
