# 04_08 - Operações de State CLI

## Por que manipular state diretamente

Em vida real, você vai precisar:

- **Renomear recursos** sem recriar (mudou de `aws_instance.web` para `aws_instance.api`).
- **Mover recursos entre módulos** durante refatoração.
- **Remover recursos do gerenciamento** (sem destruir na nuvem).
- **Inspecionar** o state para debug.

Essas operações **não mudam nada na nuvem** — apenas editam o state. É por isso que são perigosas: mal usadas, podem causar perda de rastreamento ou duplicação de recursos.

```bash
terraform state <subcomando> [opções]
```

## Subcomandos principais

| Comando | Função |
|---------|--------|
| `terraform state list` | Lista todos os recursos no state. |
| `terraform state show <addr>` | Mostra atributos de um recurso. |
| `terraform state mv <src> <dst>` | Move/renomeia recurso. |
| `terraform state rm <addr>` | Remove recurso do state (não destrói). |
| `terraform state pull` | Baixa state para stdout. |
| `terraform state push` | Envia state local para backend. |
| `terraform state replace-provider` | Troca provider source (avançado). |

## `state list`

```bash
terraform state list
```

Saída:
```text
aws_s3_bucket.logs
aws_s3_bucket_versioning.logs
aws_instance.web
module.vpc.aws_vpc.main
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
```

Útil para:
- Ver quantos recursos estão sob gerenciamento.
- Descobrir endereços de recursos dentro de módulos.
- Confirmar que um recurso está ou não no state.

### Filtros

```bash
terraform state list aws_s3_bucket.logs           # só esse
terraform state list 'module.vpc.*'                # tudo em module.vpc
terraform state list 'aws_subnet.*'                # todos subnets
```

## `state show`

```bash
terraform state show aws_s3_bucket.logs
```

Mostra todos os atributos do recurso (como está no state):

```text
# aws_s3_bucket.logs:
resource "aws_s3_bucket" "logs" {
    arn                         = "arn:aws:s3:::logs-prod-2026"
    bucket                      = "logs-prod-2026"
    force_destroy               = false
    id                          = "logs-prod-2026"
    # ...
}
```

Para obter só um valor:

```bash
terraform state show aws_s3_bucket.logs | grep arn
```

Ou melhor, usar `output` ou `terraform console`.

## `state mv`

Move/renomeia no state. **Não destrói, não cria** — apenas altera o rótulo que o Terraform usa.

### Caso 1: Renomear

Código antigo:
```hcl
resource "aws_instance" "web" { ... }
```

Código novo:
```hcl
resource "aws_instance" "api" { ... }
```

Sem `state mv`, o próximo plan diria "destruir web, criar api" — re-provisionamento desnecessário.

Com `state mv`:

```bash
terraform state mv aws_instance.web aws_instance.api
```

Agora o Terraform entende que `web` virou `api` — nenhum recurso é destruído/criado.

### Caso 2: Mover para módulo

```bash
terraform state mv aws_instance.web module.app.aws_instance.web
```

Útil quando você refatora o código agrupando recursos em módulos.

### Caso 3: Mover entre states (cross-backend)

```bash
terraform state mv -state=old.tfstate -state-out=new.tfstate \
  aws_instance.web aws_instance.web
```

Mais complexo — evite se possível.

## `state rm`

Remove recurso do state **sem destruir na nuvem**. O recurso fica "órfão" — existe na AWS, mas o Terraform esquece dele.

```bash
terraform state rm aws_instance.web
```

### Quando usar

- **Desfazer** um `import` errado.
- **Entregar** um recurso para outro time/código (que vai reimportar).
- **Parar de gerenciar** um recurso via TF sem destruí-lo.

### Cuidados

- O recurso **continua cobrando na nuvem** — não esqueça dele.
- Se você rodar `apply` depois, o Terraform **vai tentar recriar** (porque o código ainda declara). Remova do código junto.

## `state pull` / `state push`

```bash
terraform state pull > state.json
```

Baixa o state para stdout (ou arquivo). Útil para:
- Inspecionar em editor.
- Fazer backup.
- Debugar com `jq`.

```bash
terraform state push state.json
```

Envia state local para o backend. **Perigoso** — substitui o state remoto. Use só para recuperação de backup.

## Workflow seguro

### 1. Sempre faça backup antes

Quando estiver prestes a editar state:

```bash
terraform state pull > backup-$(date +%F-%H%M).json
```

### 2. Use CI com revisão

Em time, operações de state devem passar por PR + aprovação. Algumas empresas proíbem `state rm/mv` manualmente em prod — só via pipeline.

### 3. Confirme com `state list` antes e depois

```bash
terraform state list | sort > antes.txt
terraform state mv ...
terraform state list | sort > depois.txt
diff antes.txt depois.txt
```

## `moved` block (Terraform 1.1+)

Para refatorações **versionadas em código**, use `moved` em vez de `state mv` CLI:

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.api
}
```

No próximo `plan`, o Terraform entende a movimentação sem precisar rodar comando manual. Depois da migração, pode remover o bloco.

### Vantagens

- Versionado no Git.
- Visível em code review.
- Não depende de quem roda o comando.
- Rastreável.

### Limitações

- Dentro do mesmo state (não move entre backends).
- Suportado em 1.1+ (antes só CLI).

## `import` block vs. `state` commands

- **`state`** — edita o state, não a config.
- **`import` block** — traz recurso externo, edita state + (opcionalmente) gera config.
- **`moved` block** — declara refatoração em código.

Tendência moderna: fazer tudo em código (`moved`, `import`) e evitar CLI para operações de state. Mais auditável.

## Troubleshooting

### "Resource not found in state"

- Você errou o endereço. Use `terraform state list`.
- Recurso nunca foi importado. Use `terraform import`.

### "Lock is required"

- State remoto com lock. Aguarde ou `terraform force-unlock` se seguro.

### Commands wiping state

- **NUNCA** rode `state rm` sem entender.
- **NUNCA** force push state por cima de state corrompido sem backup.

## Referências

- [terraform state](https://developer.hashicorp.com/terraform/cli/commands/state)
- [moved block](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [import block](https://developer.hashicorp.com/terraform/language/import)
