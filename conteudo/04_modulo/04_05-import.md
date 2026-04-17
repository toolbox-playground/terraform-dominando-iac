# 04_05 - Import

## Problema

Você tem um recurso **criado manualmente** (ou via outra ferramenta) na nuvem, e quer passar a gerenciá-lo via Terraform. Sem import, a única opção seria destruir e recriar — inaceitável para recursos stateful.

O `terraform import` traz o recurso existente para dentro do **state** do Terraform, **sem destruir nada**.

## Sintaxe clássica (`terraform import`)

```bash
terraform import <endereco_do_recurso> <id_na_nuvem>
```

Exemplo:

```bash
terraform import aws_s3_bucket.logs logs-prod-2026
```

Isso cria uma entrada no state para `aws_s3_bucket.logs` apontando para o bucket real `logs-prod-2026`. Mas **você ainda precisa escrever o `resource` no código**, senão o próximo plan vai querer destruir.

## Fluxo recomendado

### 1. Escreva o `resource` no código

Pegue um recurso similar como base, adapte:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "logs-prod-2026"
}
```

### 2. Importe

```bash
terraform import aws_s3_bucket.logs logs-prod-2026
```

Saída:
```text
aws_s3_bucket.logs: Importing from ID "logs-prod-2026"...
aws_s3_bucket.logs: Import prepared!
  Prepared aws_s3_bucket for import
aws_s3_bucket.logs: Refreshing state...

Import successful!
```

### 3. Rode `terraform plan`

Agora o Terraform te mostra **o que falta no seu código para ele bater com a realidade**. É comum ver:

- Atributos que você não declarou.
- Atributos com valores diferentes.

Você ajusta o código iterativamente até o plan ficar **No changes**.

### 4. Confirme com apply (vazio)

```bash
terraform apply
# No changes. Your infrastructure matches the configuration.
```

A partir daí, o recurso é 100% gerenciado pelo Terraform.

## Sintaxe moderna: bloco `import` (Terraform 1.5+)

Em vez do comando CLI, você pode declarar o import no próprio código:

```hcl
import {
  to = aws_s3_bucket.logs
  id = "logs-prod-2026"
}

resource "aws_s3_bucket" "logs" {
  bucket = "logs-prod-2026"
}
```

Rode `terraform plan`: o plan mostra o import proposto. Rode `apply`: o state é atualizado.

**Vantagem**: fica no Git, revisado como código.

### Gerando configuração a partir do import (experimental)

Terraform pode até **gerar** o HCL a partir do recurso real:

```bash
terraform plan -generate-config-out=generated.tf
```

Gera um `generated.tf` com o recurso descrito. Depois você adapta (remove defaults redundantes, parametriza, organiza).

## Exemplos reais

### Importar uma EC2 existente

Código:
```hcl
resource "aws_instance" "legacy" {
  ami           = "ami-0123"
  instance_type = "t3.micro"
}
```

Comando:
```bash
terraform import aws_instance.legacy i-0abcdef1234567890
```

### Importar um RDS

```bash
terraform import aws_db_instance.main minha-db-production
```

### Importar com `for_each`

Se seu recurso usa `for_each`, o endereço tem a chave:

```bash
terraform import 'aws_instance.web["us-east-1a"]' i-0abcdef1234567890
```

### Importar com `count`

```bash
terraform import 'aws_instance.web[0]' i-0abcdef1234567890
```

## Casos complicados

### Bucket S3 com versionamento

```bash
# o bucket
terraform import aws_s3_bucket.logs logs-prod-2026

# o versionamento (recurso separado no provider AWS 4.x+)
terraform import aws_s3_bucket_versioning.logs logs-prod-2026
```

Cada recurso auxiliar precisa ser importado separadamente.

### IAM Role + Policy Attachment

```bash
terraform import aws_iam_role.app app-role
terraform import aws_iam_role_policy_attachment.app 'app-role/arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'
```

Cada provider documenta o formato do ID em "Import" no final da página do resource no Registry.

## Cuidados

### Import não valida configuração completamente

Import traz o recurso para o state, mas **não garante** que seu código bate com a realidade. Sempre rode `plan` depois e ajuste.

### Atributos sensíveis

Importar um RDS, por exemplo, traz o recurso — mas a senha não pode ser recuperada. Você terá que declarar `password = var.db_password` e esperar que o valor não mude o que já está lá (use `lifecycle { ignore_changes = [password] }` em alguns casos).

### Importar em massa

Para dezenas de recursos, considerar:

- Script que gera vários blocos `import {}` e roda um `plan`.
- Ferramentas como [Terraformer](https://github.com/GoogleCloudPlatform/terraformer) que extraem código + state de uma conta inteira.

### Import é one-shot

Cada import roda uma vez e altera o state. Se errou, precisa desfazer com `terraform state rm` e refazer.

## Dicas

- **Sempre commit o código antes** de importar.
- **Leia a seção "Import" do recurso no Registry** — cada um tem seu formato de ID.
- **Comece pelos recursos simples** (bucket, role) antes de importar monstros (RDS, EKS).
- **Use branches e PRs** — import em prod precisa revisão.
- **Importar em dev primeiro** é um ótimo teste.

## Referências

- [terraform import](https://developer.hashicorp.com/terraform/cli/import)
- [import block (1.5+)](https://developer.hashicorp.com/terraform/language/import)
- [Generating Configuration](https://developer.hashicorp.com/terraform/language/import/generating-configuration)
- [Terraformer](https://github.com/GoogleCloudPlatform/terraformer)
