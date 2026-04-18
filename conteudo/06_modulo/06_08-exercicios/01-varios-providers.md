# Exercício 01 - Configurando múltiplos providers

## Objetivo

Provisionar recursos de três providers diferentes no mesmo projeto: AWS (recurso real), `random` (utilitário) e `null` (utilitário).

## Tarefas

1. Crie um novo diretório e dentro dele um `versions.tf` com `required_providers` para:
   - `hashicorp/aws ~> 5.0`
   - `hashicorp/random ~> 3.6`
   - `hashicorp/null ~> 3.2`
2. Configure o `provider "aws"` com `region = "us-east-1"` e `default_tags` com pelo menos 3 tags.
3. Declare:
   - Um `random_id` com 4 bytes para usar como sufixo de nomes.
   - Um `aws_s3_bucket` usando o sufixo `random_id.suffix.hex` no nome.
   - Um `null_resource` com um `triggers` que mude quando o bucket for recriado.
4. Rode `terraform init` e observe quais providers foram baixados.
5. Rode `terraform plan` e identifique a **ordem de criação** no grafo.
6. Aplique com `terraform apply` e depois destrua.

## Dicas

- `random_id.suffix.hex` fornece um string de 8 caracteres hexa.
- `null_resource` sem `triggers` só roda uma vez; com `triggers = { bucket_id = aws_s3_bucket.x.id }` reexecuta quando o bucket muda.

## Perguntas

1. Quantos binários apareceram em `.terraform/providers/`?
2. Qual provider é mais "leve" (tamanho e tempo de download)?
3. Se você remover `hashicorp/null` do código e rodar `init -upgrade`, o que acontece com o lock file?
