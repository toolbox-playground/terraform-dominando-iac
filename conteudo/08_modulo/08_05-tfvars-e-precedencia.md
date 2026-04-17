# 08_05 - Arquivos `.tfvars` e Precedência

Arquivos `.tfvars` carregam valores de variáveis sem precisar da CLI. São o mecanismo mais comum para parametrizar por ambiente.

## Formato

### `.tfvars` (HCL)

```hcl
# prod.tfvars
ambiente       = "prod"
regiao         = "us-east-1"
instance_type  = "t3.large"

tags = {
  CostCenter = "business"
  Owner      = "plataforma"
}
```

### `.tfvars.json` (JSON)

```json
{
  "ambiente": "prod",
  "regiao": "us-east-1",
  "instance_type": "t3.large",
  "tags": {
    "CostCenter": "business",
    "Owner": "plataforma"
  }
}
```

Use HCL por default; JSON quando um script gera o arquivo.

## Nomes com carregamento automático

Alguns nomes são lidos **automaticamente** pelo Terraform:

| Arquivo | Comportamento |
|---------|---------------|
| `terraform.tfvars` | Carregado sempre |
| `terraform.tfvars.json` | Carregado sempre |
| `*.auto.tfvars` | Carregados sempre (em ordem lexicográfica) |
| `*.auto.tfvars.json` | Idem |

Qualquer outro nome (`prod.tfvars`, `envs/prod.tfvars`) exige `-var-file=`.

## Precedência completa (ordem de resolução)

```mermaid
flowchart TD
  D[defaults em variable{}]
  E[env: TF_VAR_name]
  T[terraform.tfvars / .json]
  A[*.auto.tfvars / .json]
  F[-var-file= CLI]
  V[-var CLI]

  D --> E --> T --> A --> F --> V --> FINAL[Valor final]
```

Maior prioridade = sobrepõe. Ou seja:

1. **`default`** (dentro de `variable`).
2. **Environment var** (`TF_VAR_name`).
3. **`terraform.tfvars`** / `.json`.
4. **`*.auto.tfvars`** em ordem lexicográfica.
5. **`-var-file=`** na CLI (ordem dos flags).
6. **`-var=`** na CLI.

Os últimos **sobrescrevem** os primeiros.

## Exemplos

### Apenas arquivos automáticos

Estrutura:

```
projeto/
├── main.tf
├── variables.tf
├── terraform.tfvars
└── regional.auto.tfvars
```

Rode `terraform apply` — ambos `.tfvars` são lidos.

### Um arquivo por ambiente com `-var-file`

Estrutura:

```
projeto/
├── main.tf
├── variables.tf
└── envs/
    ├── dev.tfvars
    ├── hml.tfvars
    └── prod.tfvars
```

```bash
terraform plan -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

### Combinação

```bash
# Base + override pontual
terraform apply -var-file=envs/prod.tfvars -var="instance_type=t3.xlarge"
```

O `-var=` sobrescreve o `.tfvars`.

## Variáveis de ambiente

```bash
export TF_VAR_ambiente="prod"
export TF_VAR_instance_type="t3.large"
export TF_VAR_tags='{CostCenter="business",Owner="plataforma"}'
```

Útil para CI (sem precisar de `.tfvars`).

Valores complexos em env var precisam ser **literais HCL**:

```bash
export TF_VAR_lista='["a","b","c"]'
export TF_VAR_mapa='{chave="valor"}'
```

## Arquivo por ambiente vs. workspace

Opção A — workspaces:

```bash
terraform workspace select prod
terraform apply   # usa terraform.workspace para decidir
```

Opção B — `.tfvars` por ambiente:

```bash
terraform apply -var-file=envs/prod.tfvars
```

Opção C — diretórios separados (mais comum em produção):

```
infra/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── hml/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

Veja detalhes no próximo tópico.

## Segredos em `.tfvars`

**Evite**. Se precisar:

1. Adicione ao `.gitignore`:
   ```
   *.tfvars
   !example.tfvars.json
   ```
2. Commit apenas um `example.tfvars` sem valores reais.
3. Documente no README como preencher localmente.

Melhor ainda: **secrets via env var** (`TF_VAR_db_password`) ou Vault/Secrets Manager.

## Dicas para times

- Commit apenas `*.tfvars` **sem valores sensíveis** (ex.: `dev.tfvars` público, `dev.local.tfvars` no .gitignore para overrides).
- Use `*.auto.tfvars` para valores **comuns do repo**, `*.tfvars` para **ambiente específico**.
- Em CI, gere `.tfvars` do jeito certo **antes** de rodar Terraform.
- Documente quais variáveis existem e como descobri-las (`terraform console` + `var.X`).

## Validação

Antes de aplicar, confirme qual arquivo foi carregado:

```bash
terraform console -var-file=envs/prod.tfvars
> var.ambiente
"prod"
```

Ou rode `terraform plan` e revise.

## Ordem dos flags `-var-file`

Se você passa múltiplos:

```bash
terraform apply -var-file=base.tfvars -var-file=prod.tfvars
```

O `prod.tfvars` **sobrescreve** o `base.tfvars`. Estratégia "base + override" é comum.

## Exemplo: precedência em ação

```hcl
# variables.tf
variable "nome" {
  default = "padrao"
}
```

```hcl
# terraform.tfvars
nome = "de_arquivo"
```

Comando:

```bash
TF_VAR_nome=de_env terraform apply -var-file=extra.tfvars -var="nome=de_cli"
```

Resultado: `nome = "de_cli"` (prioridade mais alta).

## Boas práticas finais

- **Use `-var-file`** para ambientes em produção; evite confiança cega em `*.auto.tfvars`.
- **Jamais** comite `*.tfvars` com senhas.
- **Documente** cada variável e um exemplo de valor.
- **Teste** localmente com os mesmos arquivos que o CI usará.

Próximo tópico: **estratégias multi-environment** (workspaces, diretórios, repositórios).
