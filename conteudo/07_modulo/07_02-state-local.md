# 07_02 - State Local

O backend **local** é o padrão se você não declarar nada. Ele grava o state em um arquivo JSON no diretório do projeto.

## Configuração

Não precisa de nada — por omissão é `local`:

```hcl
terraform {
  # sem backend → local, em ./terraform.tfstate
}
```

Explicitar ajuda documentação e intenção:

```hcl
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}
```

Argumentos:

| Argumento | Padrão | Uso |
|-----------|--------|-----|
| `path` | `terraform.tfstate` | Caminho do arquivo |
| `workspace_dir` | `terraform.tfstate.d` | Diretório base para workspaces não-default |

## Arquivos gerados

Na pasta do projeto, após um apply:

```
terraform.tfstate          # state atual
terraform.tfstate.backup   # cópia da versão anterior
.terraform/                # providers, módulos, metadata
.terraform.lock.hcl        # lock de providers
```

## Quando o state local faz sentido

- **Estudo e exercícios** deste curso.
- **Provas de conceito** descartáveis.
- **Módulos em desenvolvimento** que você vai testar rapidamente e jogar fora.
- **Zero colaboração**: você é o único a rodar o código.

## Quando **não** usar state local

- **Time**: outra pessoa pode rodar `apply` ao mesmo tempo e corromper tudo.
- **CI/CD**: o state vive na máquina local; o CI não tem acesso.
- **Produção**: sem lock, sem versionamento, sem audit.
- **Multi-máquina**: se você muda de laptop, perde o state.

## Localização do state com workspaces

Com workspace `default`: `terraform.tfstate`.
Com workspaces nomeados: `terraform.tfstate.d/<nome>/terraform.tfstate`.

Exemplo:

```bash
terraform workspace new prod
# cria terraform.tfstate.d/prod/terraform.tfstate
```

Mais sobre workspaces no **Módulo 8**.

## Visualizando o state

Mesmo no backend local, você usa comandos normais:

```bash
terraform show            # output humano
terraform show -json      # JSON para tooling
terraform state list      # lista recursos
terraform state show NAME # detalhes de um
```

Evite abrir o arquivo `terraform.tfstate` manualmente e editá-lo — use os comandos CLI.

## Backup manual

Antes de operações perigosas, faça uma cópia:

```bash
cp terraform.tfstate terraform.tfstate.bkp-$(date +%s)
```

Ou use `terraform state pull` / `push`:

```bash
terraform state pull > backup.json
# ...
terraform state push backup.json
```

Útil inclusive para migrar entre backends.

## Risco de commit acidental

O `.gitignore` deve sempre conter `*.tfstate*`. Se você esquecer, dados sensíveis vazam:

- Senhas geradas.
- ARNs e IDs internos.
- Estrutura de rede.

Em `pre-commit` hooks, considere um check que bloqueia commits de `*.tfstate`.

## Migrando para backend remoto

Quando decidir promover o projeto, o fluxo é:

1. Declare o novo backend (S3, GCS, HTTP, …).
2. Rode `terraform init -migrate-state`.
3. Terraform copia o state local para o remoto, pedindo confirmação.
4. Após migração, apague localmente (mantenha só `.terraform/` via `init`).

```bash
terraform init -migrate-state
```

Detalhes no próximo tópico.

## Resumo

- Backend local = arquivo JSON na pasta.
- OK para estudo/experimentos, ruim para colaboração.
- Cuide do `.gitignore`.
- Promova para backend remoto assim que o projeto cruza o teste do "mais de uma pessoa rodando".
