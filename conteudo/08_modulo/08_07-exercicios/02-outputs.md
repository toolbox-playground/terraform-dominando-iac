# Exercício 02 - Outputs

*(Integra `exercicios/1_basicos/10.md` - Exibindo informações da infraestrutura.)*

## Objetivo

Expor informações do bucket criado no exercício 01 via `output`, inclusive marcando alguns como sensíveis.

## Tarefas

1. Em `outputs.tf`:

   ```hcl
   output "bucket_name" {
     description = "Nome do bucket"
     value       = aws_s3_bucket.this.id
   }

   output "bucket_arn" {
     description = "ARN do bucket"
     value       = aws_s3_bucket.this.arn
   }

   output "bucket_regional_domain" {
     description = "Domínio regional"
     value       = aws_s3_bucket.this.bucket_regional_domain_name
   }
   ```

2. Rode `terraform apply` e confirme que os outputs aparecem no final.

3. Consulte outputs em diferentes formatos:

   ```bash
   terraform output
   terraform output bucket_arn
   terraform output -raw bucket_name
   terraform output -json
   ```

4. Adicione um output sensível:

   ```hcl
   output "politica_hypothetical" {
     value     = "arn:aws:iam::123:policy/secret-policy"
     sensitive = true
   }
   ```

   Verifique que `terraform apply` mostra `<sensitive>` no final.

5. Adicione um output **agrupado**:

   ```hcl
   output "bucket" {
     description = "Resumo do bucket criado"
     value = {
       name   = aws_s3_bucket.this.id
       arn    = aws_s3_bucket.this.arn
       region = aws_s3_bucket.this.region
     }
   }
   ```

## Perguntas

1. Qual a diferença entre `terraform output` e `terraform output -raw`?
2. Outputs sensíveis ainda aparecem no state? Por quê?
3. Como outro projeto Terraform consumiria esses outputs?
