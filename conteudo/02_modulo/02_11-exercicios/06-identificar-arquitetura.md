# Exercício 06 - Identificar a arquitetura do Terraform

## Objetivo

Exercitar o entendimento teórico da arquitetura do Terraform e relacioná-la com o que você **observa na prática** em um projeto real.

## Pré-requisitos

Ter executado `terraform init` em qualquer lab (pode ser o Lab AWS ou GCP do módulo).

## Tarefas

### 1. Inspeção dos artefatos gerados

Após um `terraform init` e `terraform apply`, execute:

```bash
ls -la
ls -la .terraform/
ls -la .terraform/providers/
```

- O que tem dentro de `.terraform/providers/`?
- O que é o arquivo `.terraform.lock.hcl`? Abra-o e veja.
- O que é o `terraform.tfstate`? (não abra pra editar, só olhe o início)

### 2. Mapeamento com a arquitetura

Relacione cada item encontrado com um componente do diagrama de [02_03 - Arquitetura](../02_03-arquitetura-terraform.md):

| Artefato | Componente da arquitetura |
|----------|---------------------------|
| O binário `terraform` | ? |
| Arquivos `.tf` | ? |
| `.terraform/providers/hashicorp/aws/...` | ? |
| `terraform.tfstate` | ? |
| `.terraform.lock.hcl` | ? |

### 3. Logs detalhados

Execute com logs verbose:

```bash
TF_LOG=DEBUG terraform plan 2> terraform.log
```

Procure no log:

- Linhas começando com `[INFO]  plugin`: que componente é esse?
- Chamadas a APIs da nuvem (`aws.amazonaws.com`, `googleapis.com`): em que momento acontecem?

### 4. Descreva com suas palavras

Em um documento `arquitetura.md`, responda:

1. Se o AWS provider é apenas um plugin baixado em runtime, por que o Terraform core não fica defasado quando a AWS lança serviços novos?
2. Por que o `plan` precisa ler tanto o state quanto a API da nuvem?
3. O que acontece se você apagar `.terraform/providers/` e não rodar `init` de novo?

## Critério de conclusão

- Preenchimento da tabela com os componentes corretos.
- Respostas às três perguntas finais com base no que aprendeu no tópico [02_03](../02_03-arquitetura-terraform.md).
