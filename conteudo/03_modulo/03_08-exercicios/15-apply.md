# Exercício 15 - Aplicando as mudanças

## Contexto

Agora que você revisou o plano no exercício anterior, chegou a hora de aplicar as mudanças e realmente criar o bucket S3.

## Objetivo

Aplicar um plano salvo, ler a saída, acessar outputs e observar o estado pós-apply.

## Pré-requisitos

- Ter rodado `terraform plan -out=plan.tfplan` com sucesso no Exercício 14.

## Tarefas

### 1. Aplicar o plano salvo

```bash
terraform apply plan.tfplan
```

Observe:

- Cada recurso aparece com `Creating...` e depois `Creation complete after Xs`.
- No fim: `Apply complete! Resources: N added, 0 changed, 0 destroyed.`.
- Outputs são impressos.

### 2. Verificar no console AWS

Abra o console S3 e confirme que o bucket existe, com as tags declaradas.

### 3. Obter outputs via CLI

```bash
terraform output
terraform output bucket_arn
terraform output -raw bucket_arn      # sem aspas, ideal para script
terraform output -json                # JSON estruturado
```

### 4. Observar o state

```bash
terraform state list
terraform state show aws_s3_bucket.logs
```

- Quantos recursos há no state?
- Que informações o `state show` trouxe que não estavam no seu código?

### 5. Idempotência

Rode `terraform apply` de novo:

```bash
terraform apply
```

- O que o plan mostra?
- Quantos recursos foram alterados?

### 6. Modifique uma tag e aplique

- Adicione uma tag nova ao bucket.
- `terraform plan`
- `terraform apply` (sem `-out` desta vez; apenas confirme com `yes`).

### 7. Limpeza

**Não esqueça de destruir!**

```bash
terraform destroy
```

## Critério de conclusão

- Bucket criado com sucesso no AWS.
- Output `bucket_arn` visível via CLI.
- Você viu "No changes" rodando apply duas vezes seguidas (idempotência).
- Bucket destruído ao final (não queremos cobrança).

## Referências

- [Tópico 03_07 - Apply](../03_07-apply.md)
- [terraform apply docs](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [terraform output docs](https://developer.hashicorp.com/terraform/cli/commands/output)
