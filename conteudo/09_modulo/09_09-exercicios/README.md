# Módulo 9 - Exercícios

Exercícios sobre HCL avançado: `count`, `for_each`, expressões `for`, splat, `dynamic`, `lifecycle`, templates e funções.

## Lista

1. [Count + Lifecycle (create_before_destroy)](01-count-lifecycle.md) *(integra exercício original 21)*
2. [`for_each` a partir de um map](02-for-each-map.md) *(integra exercício original 22)*
3. [Expressões e funções](03-expressoes-funcoes.md) *(integra exercício original 23)*
4. [Expressão `for` + splat `[*]`](04-for-splat.md) *(integra exercício original 24)*
5. [Renderização com `templatefile`](05-templatefile.md) *(integra exercício original 25)*
6. [`dynamic` blocks](06-dynamic-blocks.md)

## Dica geral

Algumas soluções de referência estão em [`respostas/`](respostas/).

Use `terraform console` para testar expressões isoladamente antes de aplicar:

```bash
terraform console
> [for n in range(3) : "web-${n}"]
> {for i, v in ["a","b","c"] : i => upper(v)}
> cidrsubnet("10.0.0.0/16", 8, 2)
```
