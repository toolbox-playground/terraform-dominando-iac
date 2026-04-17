# Exercício 03 - Expressões e Funções

*(Integra o exercício original 23)*

## Objetivo

Combinar operações aritméticas, expressões `for` e funções built-in para gerar saídas formatadas.

## Tarefa

1. Criar duas input variables numéricas `a` e `b` (default 10 e 5).
2. Calcular `soma`, `produto` e `media` em `locals`.
3. Criar um output formatado com `format("...")`.
4. Criar uma lista de 5 números via `range(1, 6)` e computar o quadrado de cada em outro local.
5. Expor em outputs o total, a lista e um mapa `{ numero => quadrado }`.

## Dicas

```hcl
variable "a" { default = 10 }
variable "b" { default = 5 }

locals {
  soma     = var.a + var.b
  produto  = var.a * var.b
  media    = (var.a + var.b) / 2

  numeros   = range(1, 6)
  quadrados = [for n in local.numeros : n * n]
  mapa      = { for n in local.numeros : n => n * n }
}

output "resumo" {
  value = format("a=%d, b=%d, soma=%d, produto=%d, media=%d",
    var.a, var.b, local.soma, local.produto, local.media)
}

output "quadrados" { value = local.quadrados }
output "mapa"      { value = local.mapa }
```

## Verificação

```bash
terraform init
terraform apply
# resumo = a=10, b=5, soma=15, produto=50, media=7
# quadrados = [1, 4, 9, 16, 25]
# mapa = {1=1, 2=4, 3=9, 4=16, 5=25}
```

## Desafio extra

- Use `formatlist("item-%02d", local.numeros)` e gere `["item-01", "item-02", ...]`.
- Explore `terraform console` para testar funções isoladamente.
