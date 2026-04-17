# 02_09 - Estrutura de Comandos

## Anatomia de um comando Terraform

A forma geral de qualquer comando é:

```text
terraform [opções_globais] <subcomando> [opções_do_subcomando] [argumentos]
```

Exemplos:

```bash
terraform init
terraform -chdir=./infra plan
terraform apply -auto-approve -var="region=us-east-1"
terraform state list
```

## Help e descoberta

Sempre que estiver em dúvida:

```bash
terraform --help              # lista todos os subcomandos
terraform <subcomando> -help  # ajuda do subcomando específico

terraform plan -help          # exemplo
```

A saída do help é **confiável** e sempre está alinhada com a versão instalada.

## Subcomandos principais (visão rápida)

Organizados por uso:

### Ciclo principal (Workflow WPC)

| Comando | Função |
|---------|--------|
| `terraform init` | Inicializa o diretório: baixa providers e módulos, configura backend. Obrigatório antes de qualquer outro comando. |
| `terraform fmt` | Formata arquivos `.tf` conforme estilo oficial. |
| `terraform validate` | Valida sintaxe e referências internas do código. |
| `terraform plan` | Mostra o que será feito (create/update/destroy) sem aplicar. |
| `terraform apply` | Executa o plano. Pede confirmação a menos que use `-auto-approve`. |
| `terraform destroy` | Destroi todos os recursos gerenciados. |

### Inspeção e saída

| Comando | Função |
|---------|--------|
| `terraform show` | Mostra o state atual ou um plano salvo. |
| `terraform output` | Exibe os outputs declarados. |
| `terraform console` | Shell interativo para testar expressões HCL. |
| `terraform graph` | Gera grafo de dependências em formato DOT. |
| `terraform version` / `-v` | Mostra a versão do Terraform e dos providers. |

### State

| Comando | Função |
|---------|--------|
| `terraform state list` | Lista todos os recursos no state. |
| `terraform state show <addr>` | Mostra detalhes de um recurso específico. |
| `terraform state mv <src> <dst>` | Move/renomeia um recurso no state (sem recriar). |
| `terraform state rm <addr>` | Remove um recurso do state (não destrói na nuvem). |
| `terraform state pull` | Baixa o state remoto para stdout. |
| `terraform state push` | Envia um state local para o backend. |

### Workspaces

| Comando | Função |
|---------|--------|
| `terraform workspace list` | Lista workspaces. |
| `terraform workspace new <nome>` | Cria um workspace novo. |
| `terraform workspace select <nome>` | Muda para um workspace existente. |
| `terraform workspace show` | Mostra o workspace atual. |
| `terraform workspace delete <nome>` | Remove um workspace. |

### Importação e refresh

| Comando | Função |
|---------|--------|
| `terraform import <addr> <id>` | Traz recurso existente para dentro do state. |
| `terraform refresh` | Atualiza o state lendo a realidade (hoje equivalente a `apply -refresh-only`). |
| `terraform apply -replace=<addr>` | Força substituição de um recurso (substitui `taint`). |

### Outros

| Comando | Função |
|---------|--------|
| `terraform providers` | Lista providers usados no diretório atual. |
| `terraform providers lock` | Atualiza hashes no `.terraform.lock.hcl`. |
| `terraform login` / `logout` | Autentica com HCP Terraform / Enterprise. |
| `terraform force-unlock <LOCK_ID>` | Remove lock travado (cuidado!). |
| `terraform taint` / `untaint` | **Depreciado** — use `apply -replace`. |

## Flags globais

Aceitas **antes** do subcomando:

| Flag | Uso |
|------|-----|
| `-chdir=DIR` | Executa como se estivesse no diretório DIR. Útil em monorepos e CI. |
| `-help` / `-h` | Ajuda. |
| `-version` / `-v` | Versão. |

Exemplo:

```bash
terraform -chdir=./infra/prod plan
```

## Flags comuns de subcomandos

### init

- `-upgrade` — atualiza providers para a versão mais nova compatível com constraints.
- `-reconfigure` — reconfigura o backend ignorando config anterior.
- `-backend-config=FILE` ou `-backend-config="key=value"` — parâmetros do backend.
- `-no-color` — remove cores (útil em CI).

### plan

- `-out=FILE` — salva o plano em arquivo (pra depois aplicar com garantia).
- `-var="nome=valor"` — define variável.
- `-var-file=FILE` — carrega variáveis de arquivo.
- `-target=ADDR` — planeja só um recurso (use com moderação).
- `-destroy` — planeja destruição.
- `-refresh=false` — não consulta a nuvem; compara só código vs. state.
- `-detailed-exitcode` — códigos de saída úteis em CI (0=nada, 1=erro, 2=diff).

### apply

- `-auto-approve` — não pede confirmação.
- `-var` / `-var-file` — iguais ao plan.
- `-target` — aplica só um recurso.
- `-parallelism=N` — número de recursos em paralelo (default 10).
- Aceita um **arquivo de plano salvo**: `terraform apply plano.tfplan`.

### destroy

- `-auto-approve` — sem confirmação.
- `-target` — destrói só um recurso.

## Códigos de saída

Relevantes para CI/CD:

| Código | Significado |
|--------|-------------|
| 0 | Sucesso, nenhuma mudança (para `plan -detailed-exitcode`). |
| 1 | Erro. |
| 2 | Sucesso, mas há mudanças detectadas (somente com `-detailed-exitcode`). |

## Variáveis de ambiente úteis

- `TF_LOG` — nível de log (`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`). Debug por excelência.
- `TF_LOG_PATH` — direciona log para arquivo.
- `TF_VAR_<nome>` — define variável (ex.: `TF_VAR_region=us-east-1`).
- `TF_CLI_ARGS` / `TF_CLI_ARGS_<subcmd>` — flags padrão.
- `TF_IN_AUTOMATION=true` — muda mensagens para CI (esconde "dicas").
- `TF_INPUT=false` — não prompta por nada (use em CI com variáveis completas).

## Boas práticas

- **Sempre `init` primeiro** em um diretório novo ou após mudar providers/módulos.
- **Sempre `plan` antes de `apply`** em ambientes reais (mesmo em dev).
- **Salve plano com `-out`** em CI para garantir que o apply aplica exatamente o que foi revisado.
- **`fmt` e `validate`** viram parte do ciclo — em pre-commit hook ou pipeline.
- **`-auto-approve` só em automação** controlada com aprovação humana externa.
- **Leia o help do subcomando** antes de usar flags exóticas.

## Exemplo do ciclo completo

```bash
# setup inicial
terraform init

# antes de qualquer PR
terraform fmt -recursive
terraform validate

# revisão
terraform plan -out=plan.tfplan

# aplica exatamente o plano revisado
terraform apply plan.tfplan

# inspecionar saída
terraform output

# ver grafo em formato DOT
terraform graph | dot -Tsvg > graph.svg
```

## Referências

- [Terraform CLI Commands](https://developer.hashicorp.com/terraform/cli/commands)
- [Environment Variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables)
