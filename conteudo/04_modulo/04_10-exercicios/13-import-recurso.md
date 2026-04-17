# Exercício 13 - Importando um recurso existente

## Contexto

Sua equipe tem um recurso criado manualmente no console AWS e quer passar a gerenciá-lo via Terraform, sem destruir/recriar.

## Objetivo

Praticar os dois fluxos de import: via CLI clássico (`terraform import`) e via bloco `import {}` (Terraform 1.5+).

## Pré-requisitos

- Conta AWS com permissões.
- Terraform 1.5+ (para o bloco `import`).
- Um projeto Terraform inicializado.

## Tarefas

### Parte 1: criar recurso manualmente (só para o exercício)

1. No console AWS, crie manualmente um bucket S3:
   - Nome: `import-test-<seu-nome>-2026`
   - Região: `us-east-1`
   - Outros: default

2. Anote o nome para usar abaixo.

### Parte 2: import via CLI (clássico)

1. No seu `main.tf`, declare:

   ```hcl
   resource "aws_s3_bucket" "imported" {
     bucket = "import-test-<seu-nome>-2026"
   }
   ```

2. Execute:

   ```bash
   terraform import aws_s3_bucket.imported import-test-<seu-nome>-2026
   ```

3. Rode:

   ```bash
   terraform plan
   ```

   - O que aparece no plan?
   - Se houver diff, ajuste o código até `No changes`.

4. Inspecione o state:

   ```bash
   terraform state show aws_s3_bucket.imported
   ```

### Parte 3: import via bloco `import {}` (moderno)

1. Remova o recurso do state (para testar):

   ```bash
   terraform state rm aws_s3_bucket.imported
   ```

2. No código, adicione:

   ```hcl
   import {
     to = aws_s3_bucket.imported
     id = "import-test-<seu-nome>-2026"
   }

   resource "aws_s3_bucket" "imported" {
     bucket = "import-test-<seu-nome>-2026"
   }
   ```

3. Rode:

   ```bash
   terraform plan
   terraform apply
   ```

   - O plan mostra o import proposto?
   - Apply executa sem recriar?

### Parte 4: geração automática de config (experimental)

Apague a declaração de `resource` (mantenha só o `import {}`):

```bash
terraform plan -generate-config-out=generated.tf
```

Inspecione `generated.tf`:

- Quais atributos foram descobertos?
- Faltou algo?

### Limpeza

```bash
terraform destroy
```

## Critério de conclusão

- Você conseguiu importar o bucket de duas formas diferentes.
- Conseguiu ajustar o código até `terraform plan` dizer `No changes`.
- Entendeu o uso do `-generate-config-out`.

## Referências

- [Tópico 04_05 - Import](../04_05-import.md)
- [import block docs](https://developer.hashicorp.com/terraform/language/import)
- [aws_s3_bucket Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
