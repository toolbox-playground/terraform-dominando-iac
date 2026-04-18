# Exercício 12 - Formatação e validação

## Contexto

A equipe adotou boas práticas de formatação e validação. Seu código precisa passar em `terraform fmt -check` e `terraform validate` antes de ser aceito em PR.

## Objetivo

Praticar o uso de `terraform fmt` e `terraform validate` como parte do ciclo de desenvolvimento.

## Tarefas

### 1. Formatação

1. Abra um dos seus arquivos `.tf` (ex.: `main.tf`).
2. Introduza propositalmente **desformatação**:
   - Remova a indentação de algumas linhas.
   - Quebre a linha em lugares aleatórios.
   - Remova os espaços em volta dos `=`.

3. Rode:

   ```bash
   terraform fmt -check -diff
   ```

   O exit code deve ser 3 e o diff deve mostrar o que seria alterado.

4. Rode:

   ```bash
   terraform fmt
   ```

   Abra o arquivo novamente — está bonito, indentado, alinhado.

### 2. Validação

1. Introduza um **erro** de sintaxe:
   - Remova uma `}` fechadora.
   - Referencie uma variável que não existe (`var.nao_existe`).
   - Passe tipo errado (ex.: `instance_type = 123`).

2. Rode:

   ```bash
   terraform validate
   ```

3. Observe a mensagem de erro. Ela aponta arquivo, linha e descrição?

4. Corrija o erro e rode novamente. Deve aparecer `Success!`.

### 3. Integração

1. Instale o [pre-commit](https://pre-commit.com/) (se ainda não tem).
2. Adicione um `.pre-commit-config.yaml`:

   ```yaml
   repos:
     - repo: https://github.com/antonbabenko/pre-commit-terraform
       rev: v1.86.0
       hooks:
         - id: terraform_fmt
         - id: terraform_validate
   ```

3. Rode:

   ```bash
   pre-commit install
   pre-commit run --all-files
   ```

4. Faça um commit com código desformatado — o hook deve bloquear.

## Critério de conclusão

- Você consegue diferenciar o que `fmt` corrige vs. o que `validate` reporta.
- Pre-commit hook configurado e funcionando.

## Referências

- [Tópico 03_04 - FMT](../03_04-fmt.md)
- [Tópico 03_03 - Validate](../03_03-validate.md)
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
