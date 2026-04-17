# Exercício 01 - Input Variables

*(Integra `exercicios/1_basicos/09.md` - Trabalhando com variáveis.)*

## Objetivo

Parametrizar um recurso S3 usando variáveis com `type`, `description` e `validation`.

## Tarefas

1. Crie `variables.tf`:

   ```hcl
   variable "nome_bucket" {
     description = "Nome do bucket S3 (lowercase, 3-63 chars)"
     type        = string

     validation {
       condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.nome_bucket))
       error_message = "Bucket deve começar com letra minúscula e ter 3-63 chars."
     }
   }

   variable "regiao" {
     description = "Região AWS"
     type        = string
     default     = "us-east-1"
   }

   variable "tags_extras" {
     description = "Tags adicionais"
     type        = map(string)
     default     = {}
   }
   ```

2. Em `main.tf`, use-as:

   ```hcl
   resource "aws_s3_bucket" "this" {
     bucket = var.nome_bucket
     tags = merge({ ManagedBy = "terraform" }, var.tags_extras)
   }
   ```

3. Teste diferentes formas de passar valores:

   ```bash
   # 1. Prompt interativo (sem default)
   terraform apply

   # 2. CLI
   terraform apply -var="nome_bucket=meu-bucket-123"

   # 3. Env var
   TF_VAR_nome_bucket=meu-bucket-123 terraform apply

   # 4. Arquivo
   echo 'nome_bucket = "meu-bucket-123"' > terraform.tfvars
   terraform apply
   ```

4. Teste a validação passando `nome_bucket = "Invalid_Name"` e observe a mensagem.

## Perguntas

1. O que acontece se você passar o mesmo valor por dois meios (ex.: `-var` e env)?
2. Qual a ordem de precedência?
3. Por que preferir `-var-file` a `-var` em CI?
