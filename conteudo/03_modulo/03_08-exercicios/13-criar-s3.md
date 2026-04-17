# Exercício 13 - Provisionando um recurso S3

## Contexto

A equipe precisa de um novo bucket S3 para armazenar logs de aplicações. Sua tarefa é criar a configuração Terraform para provisionar esse bucket.

## Objetivo

Escrever um recurso Terraform `aws_s3_bucket` simples e preparar o diretório para o ciclo de plan/apply.

## Pré-requisitos

- Credenciais AWS configuradas.
- Terraform inicializado (Exercício 11).

## Tarefas

1. No seu diretório, crie um arquivo `main.tf`:

   ```hcl
   resource "aws_s3_bucket" "logs" {
     bucket = "logs-<seu-nome>-2026"  # nome globalmente único

     tags = {
       Ambiente = "estudo"
       Criado_por = "terraform"
     }
   }

   output "bucket_arn" {
     description = "ARN do bucket de logs"
     value       = aws_s3_bucket.logs.arn
   }
   ```

2. Substitua `<seu-nome>` por algo único (seu primeiro nome + número, por exemplo). Nomes S3 são globais — se "meu-bucket" já existe na AWS, o seu falha.

3. Rode `terraform fmt` e `terraform validate`.

4. Rode `terraform plan`. Você **ainda não vai aplicar** neste exercício — isso é o próximo.

5. Observe no plan:
   - Quantos recursos serão criados?
   - Qual o símbolo (`+`, `~`, `-`)?
   - Há valores `known after apply`? Por quê?

## Critério de conclusão

- `main.tf` válido com bucket declarado.
- `terraform plan` imprime "Plan: 1 to add, 0 to change, 0 to destroy."
- Você **não aplicou** ainda — isso fica para o próximo exercício.

## Referências

- [aws_s3_bucket no Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Tópico 03_06 - Plan](../03_06-plan.md)
