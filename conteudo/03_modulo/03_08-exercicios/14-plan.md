# Exercício 14 - Visualizando mudanças com plan

## Contexto

Antes de aplicar qualquer alteração, é essencial revisar o que vai mudar. O comando `terraform plan` é seu melhor amigo.

## Objetivo

Dominar a leitura da saída do `plan` e salvar um plano para aplicar depois.

## Pré-requisitos

- Ter o `main.tf` do Exercício 13 pronto.

## Tarefas

### 1. Plan em modo interativo

```bash
terraform plan
```

Observe:

- O número de recursos em `Plan: X to add, Y to change, Z to destroy`.
- Os símbolos (`+`, `~`, `-`, `-/+`).
- Os valores `known after apply`.

### 2. Salvando o plano

```bash
terraform plan -out=plan.tfplan
```

- Liste os arquivos: o `plan.tfplan` apareceu?
- Tente abrir com um editor — é binário.

### 3. Inspecione o plano salvo

```bash
terraform show plan.tfplan
```

E em JSON:

```bash
terraform show -json plan.tfplan | jq '.resource_changes[] | {address, actions}'
```

(Requer [jq](https://jqlang.github.io/jq/) instalado.)

### 4. Experimente `-detailed-exitcode`

```bash
terraform plan -detailed-exitcode
echo "Exit code: $?"
```

O exit code é:
- **0** se não há mudanças
- **2** se há mudanças (normal para a primeira vez)
- **1** em caso de erro

### 5. Faça uma mudança no código e rode plan de novo

- Adicione uma tag nova ao bucket.
- Rode `plan`. O símbolo é `+` (novo recurso) ou `~` (modificação)?
- Sem ter aplicado ainda, como o Terraform sabe que precisa mudar?

## Critério de conclusão

- Você entende os símbolos do plan.
- Sabe salvar um plano com `-out` e inspecionar com `show`.
- Entende como usar `-detailed-exitcode` em scripts.

## Referências

- [Tópico 03_06 - Plan](../03_06-plan.md)
- [terraform plan docs](https://developer.hashicorp.com/terraform/cli/commands/plan)
