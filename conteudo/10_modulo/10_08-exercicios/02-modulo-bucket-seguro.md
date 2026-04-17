# Exercício 02 - Módulo `bucket-seguro` com padrões de segurança

## Objetivo

Construir um módulo que aplica automaticamente padrões de segurança em buckets S3: versionamento, encryption e block public access.

## Tarefa

1. Criar módulo em `modules/bucket-seguro/` com:
   - Input `nome` (obrigatório) e `ambiente` (validação contains dev/hml/prod).
   - Input `versionamento` (bool, default `true`).
   - Input `tags_extras` (map(string), default `{}`).
2. No `main.tf` do módulo, criar:
   - `aws_s3_bucket`
   - `aws_s3_bucket_versioning` (condicional)
   - `aws_s3_bucket_server_side_encryption_configuration` (AES256)
   - `aws_s3_bucket_public_access_block` (tudo `true`)
3. Outputs: `id`, `arn`, `nome_completo`.
4. No root, consumir o módulo 3 vezes: `logs`, `backup`, `media`.

## Dicas

- Use `locals` no módulo para mergear tags default com `tags_extras`.
- Prefixe o nome do bucket com `var.ambiente`.

## Verificação

```bash
terraform apply

# Na AWS, verifique que cada bucket:
# - Tem versioning habilitado
# - Tem encryption default AES256
# - Tem block public access em TRUE
```

## Desafio extra

- Adicionar input opcional `lifecycle_rules` (list de objetos) para expirar objetos antigos.
- Exponha um output `lifecycle_arn` só quando a feature está ativa (use `try()`).
