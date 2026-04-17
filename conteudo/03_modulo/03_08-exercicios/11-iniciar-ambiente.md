# Exercício 11 - Inicializando o ambiente Terraform

## Contexto

Antes de criar qualquer recurso, você precisa inicializar o diretório Terraform para que ele baixe os providers necessários, configure o backend e prepare o lock file.

## Objetivo

Executar com sucesso o `terraform init` em um projeto novo.

## Pré-requisitos

- Terraform instalado.
- Credenciais da nuvem configuradas (AWS ou GCP).
- Ter concluído o [Exercício 02 do Módulo 2](../../02_modulo/02_11-exercicios/02-configurar-provider-aws.md) ou ter um `versions.tf` com `required_providers` configurado.

## Tarefas

1. Em um diretório com `versions.tf`/`main.tf`, execute:

   ```bash
   terraform init
   ```

2. Observe a saída. Anote:
   - Quais providers foram baixados?
   - Qual a versão de cada um?
   - Foi criado o arquivo `.terraform.lock.hcl`?

3. Liste os artefatos gerados:

   ```bash
   ls -la
   ls -la .terraform/providers/
   ```

4. Abra o `.terraform.lock.hcl` e veja o conteúdo. Qual é a utilidade desse arquivo?

5. Tente rodar `terraform plan` **sem** ter feito o init. O que acontece?

## Critério de conclusão

- Pasta `.terraform/` criada.
- Arquivo `.terraform.lock.hcl` gerado e commitável.
- Provider baixado na versão compatível com a constraint.

## Referências

- Tópico [03_05 - Init](../03_05-init.md)
- [Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
