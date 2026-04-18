# 08_01 - Input Variables

**Input variables** parametrizam módulos Terraform. Elas são a interface pública: quem usa o módulo escolhe valores; quem escreve o módulo declara a forma.

## Declarando uma variável

```hcl
variable "ambiente" {
  description = "Ambiente de deploy"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "hml", "prod"], var.ambiente)
    error_message = "Ambiente deve ser dev, hml ou prod."
  }

  sensitive = false
  nullable  = false
}
```

Argumentos:

| Argumento | Obrigatório | Uso |
|-----------|-------------|-----|
| `description` | não (recomendado) | Documenta |
| `type` | não (recomendado) | Restringe o tipo |
| `default` | não | Se omitido, variável é **obrigatória** |
| `validation` | não | Regra customizada |
| `sensitive` | não | Esconde em plan/apply |
| `nullable` | não (default `true`) | Se `false`, nunca aceita `null` |

## Uso

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "logs-${var.ambiente}"
}
```

Referência: sempre `var.NOME`.

## Tipos

Veja detalhes em [05_03 - Tipos Primitivos](../05_modulo/05_03-tipos-primitivos.md) e [05_04 - Tipos Complexos](../05_modulo/05_04-tipos-complexos.md).

Resumo comum:

```hcl
variable "porta"       { type = number }
variable "ssl"         { type = bool }
variable "zonas"       { type = list(string) }
variable "tags"        { type = map(string) }
variable "config" {
  type = object({
    nome = string
    cpu  = number
  })
}
```

## Validation

Desde Terraform 0.13, validation permite regras arbitrárias:

```hcl
variable "cidr" {
  type = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "CIDR inválido."
  }

  validation {
    condition     = split("/", var.cidr)[1] >= "16"
    error_message = "Use prefixo >= /16."
  }
}
```

**Múltiplas validations** num mesmo `variable` são permitidas. Todas são avaliadas.

## `sensitive = true`

Esconde valor em plan/apply e em outputs derivados:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

Como visto no **Módulo 7**, o valor continua no state — use com encryption + Secret Manager para secrets sérios.

## `nullable = false`

Por padrão, você pode explicitamente passar `null`. Em alguns cenários isso é ruim:

```hcl
variable "projeto" {
  type     = string
  nullable = false
}
```

Agora `null` é rejeitado.

## Quando definir `default`

- **Com default**: variável opcional.
- **Sem default**: variável obrigatória; o usuário precisa fornecer valor.

Convenção: defaults só para valores verdadeiramente padrão. Não invente defaults só para remover obrigatoriedade.

## Como passar valores (precedência)

O Terraform resolve na seguinte **ordem de prioridade** (maior → menor):

1. **`-var` CLI** (`terraform apply -var="ambiente=prod"`).
2. **`-var-file` CLI** (`terraform apply -var-file=prod.tfvars`).
3. **Environment variables**: `TF_VAR_ambiente=prod`.
4. **`*.auto.tfvars` / `*.auto.tfvars.json`** (carregados automaticamente em ordem lexicográfica).
5. **`terraform.tfvars` / `terraform.tfvars.json`** (carregado automaticamente).
6. **`default`** declarado no `variable`.

Ou seja: **CLI > Arquivos > Env > Default**.

Se a variável não tem default e nenhuma fonte supre o valor, Terraform **pede interativamente**.

## `*.tfvars` e `*.auto.tfvars`

### `terraform.tfvars`

Carregado automaticamente. Convenção para valores específicos do **ambiente local**.

```hcl
# terraform.tfvars
ambiente = "dev"
regiao   = "us-east-1"
```

Geralmente **não** vai pro Git (por conter dados específicos do dev).

### `*.auto.tfvars`

Qualquer arquivo que termine com `.auto.tfvars` é carregado. Útil para configs por ambiente:

```
envs/
├── dev.auto.tfvars
├── hml.auto.tfvars
└── prod.auto.tfvars
```

Atenção: **todos** são carregados. Se você tiver vários, eles se sobrepõem (último vence, ordem lexicográfica).

Alternativa mais limpa: pasta por ambiente (detalhado em [08_06 - Estratégias Multi-Environment](08_06-estrategias-multi-environment.md)).

### `-var-file=`

Passado explicitamente na CLI:

```bash
terraform plan -var-file=envs/prod.tfvars
```

Isso **não** é automático — você decide quando carregar.

## Variáveis de ambiente (`TF_VAR_`)

```bash
export TF_VAR_ambiente=prod
export TF_VAR_tags='{Env="prod",Time="plataforma"}'
```

Útil para:

- Secrets (não ficam em arquivos).
- CI/CD (pipeline define).
- Valores que variam por máquina.

## Exemplos práticos

### Obrigatória com validação

```hcl
variable "projeto" {
  description = "Nome do projeto (lowercase, 3-30 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,29}$", var.projeto))
    error_message = "Use lowercase, dígitos e hifens (3-30 chars)."
  }
}
```

### Opcional com tipo complexo

```hcl
variable "tags" {
  description = "Tags a aplicar"
  type        = map(string)
  default     = {}
}
```

### Secret com fallback por variável de ambiente

```hcl
variable "api_key" {
  description = "API key para provedor externo"
  type        = string
  sensitive   = true
}
```

Use `TF_VAR_api_key` no ambiente.

## Boas práticas

- **Sempre** inclua `description`.
- **Sempre** defina `type`.
- **Use `validation`** para invariantes importantes.
- **Organize** variáveis em `variables.tf` na raiz do módulo.
- **Evite `default`** para valores que mudam por ambiente — deixe explícito.
- **Documente no README** quais variáveis o módulo aceita.

## Debug

```bash
terraform console
> var.ambiente
"prod"

> var.tags
{
  "Env" = "prod"
}
```

Próximo tópico: **`locals`** — variáveis internas calculadas.
