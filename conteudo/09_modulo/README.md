# Módulo 9 - HCL Avançado

Recursos avançados da linguagem HCL para criar código expressivo, reutilizável e resiliente.

## Objetivos de aprendizagem

- Criar múltiplas instâncias de recursos com `count` e `for_each`.
- Transformar coleções com expressões `for` e filtrar resultados.
- Extrair atributos com o operador splat `[*]`.
- Gerar blocos aninhados dinamicamente com `dynamic`.
- Controlar ciclo de vida com `lifecycle` (create_before_destroy, prevent_destroy, ignore_changes).
- Renderizar arquivos a partir de templates com `templatefile`.
- Dominar as funções built-in mais usadas.

## Tópicos

1. [`count`](09_01-count.md)
2. [`for_each`](09_02-for-each.md)
3. [Expressões `for`](09_03-expressoes-for.md)
4. [Operador Splat `[*]`](09_04-splat.md)
5. [`dynamic` blocks](09_05-dynamic-blocks.md)
6. [`lifecycle`](09_06-lifecycle.md)
7. [Templates e `templatefile`](09_07-templates.md)
8. [Funções built-in essenciais](09_08-funcoes-essenciais.md)
9. [Exercícios](09_09-exercicios/)

## Decisões rápidas

| Cenário | Use |
|---------|-----|
| N recursos idênticos, quantidade variável | `count` |
| Recursos com identidades únicas (nome, chave) | `for_each` |
| Transformar lista/map | expressão `for` |
| Extrair 1 atributo de lista com `count` | splat `[*]` |
| Blocos aninhados repetidos | `dynamic` |
| Evitar downtime em recriação | `lifecycle { create_before_destroy = true }` |
| Proteger recurso de destroy acidental | `lifecycle { prevent_destroy = true }` |
| Ignorar mudanças externas (ex.: tags de autoscaling) | `lifecycle { ignore_changes = [...] }` |
| Gerar user-data, config, policy | `templatefile` ou `jsonencode` |

Este módulo encerra a parte "linguagem". A partir do Módulo 10 entramos em **Módulos** — empacotando código para reutilização — e no Módulo 11 em **CI/CD com GitLab**.
